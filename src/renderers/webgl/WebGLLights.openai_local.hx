import three.math.Color;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.renderers.webgl.shaders.UniformsLib;

class UniformsCache {
    private var lights:Map<Int, Dynamic> = new Map();

    public function new() {}

    public function get(light:Dynamic):Dynamic {
        if (lights.exists(light.id)) {
            return lights.get(light.id);
        }

        var uniforms:Dynamic;

        switch (light.type) {
            case "DirectionalLight":
                uniforms = {
                    direction: new Vector3(),
                    color: new Color()
                };
                break;
            case "SpotLight":
                uniforms = {
                    position: new Vector3(),
                    direction: new Vector3(),
                    color: new Color(),
                    distance: 0,
                    coneCos: 0,
                    penumbraCos: 0,
                    decay: 0
                };
                break;
            case "PointLight":
                uniforms = {
                    position: new Vector3(),
                    color: new Color(),
                    distance: 0,
                    decay: 0
                };
                break;
            case "HemisphereLight":
                uniforms = {
                    direction: new Vector3(),
                    skyColor: new Color(),
                    groundColor: new Color()
                };
                break;
            case "RectAreaLight":
                uniforms = {
                    color: new Color(),
                    position: new Vector3(),
                    halfWidth: new Vector3(),
                    halfHeight: new Vector3()
                };
                break;
        }

        lights.set(light.id, uniforms);
        return uniforms;
    }
}

class ShadowUniformsCache {
    private var lights:Map<Int, Dynamic> = new Map();

    public function new() {}

    public function get(light:Dynamic):Dynamic {
        if (lights.exists(light.id)) {
            return lights.get(light.id);
        }

        var uniforms:Dynamic;

        switch (light.type) {
            case "DirectionalLight":
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2()
                };
                break;
            case "SpotLight":
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2()
                };
                break;
            case "PointLight":
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2(),
                    shadowCameraNear: 1,
                    shadowCameraFar: 1000
                };
                break;
            // TODO: set RectAreaLight shadow uniforms
        }

        lights.set(light.id, uniforms);
        return uniforms;
    }
}

class WebGLLights {
    private var cache:UniformsCache = new UniformsCache();
    private var shadowCache:ShadowUniformsCache = new ShadowUniformsCache();

    public var state:Dynamic = {
        version: 0,
        hash: {
            directionalLength: -1,
            pointLength: -1,
            spotLength: -1,
            rectAreaLength: -1,
            hemiLength: -1,
            numDirectionalShadows: -1,
            numPointShadows: -1,
            numSpotShadows: -1,
            numSpotMaps: -1,
            numLightProbes: -1
        },
        ambient: [0, 0, 0],
        probe: [],
        directional: [],
        directionalShadow: [],
        directionalShadowMap: [],
        directionalShadowMatrix: [],
        spot: [],
        spotLightMap: [],
        spotShadow: [],
        spotShadowMap: [],
        spotLightMatrix: [],
        rectArea: [],
        rectAreaLTC1: null,
        rectAreaLTC2: null,
        point: [],
        pointShadow: [],
        pointShadowMap: [],
        pointShadowMatrix: [],
        hemi: [],
        numSpotLightShadowsWithMaps: 0,
        numLightProbes: 0
    };

    public function new() {
        for (i in 0...9) state.probe.push(new Vector3());
    }

    public function setup(lights:Array<Dynamic>, useLegacyLights:Bool) {
        var r = 0, g = 0, b = 0;

        for (i in 0...9) state.probe[i].set(0, 0, 0);

        var directionalLength = 0;
        var pointLength = 0;
        var spotLength = 0;
        var rectAreaLength = 0;
        var hemiLength = 0;

        var numDirectionalShadows = 0;
        var numPointShadows = 0;
        var numSpotShadows = 0;
        var numSpotMaps = 0;
        var numSpotShadowsWithMaps = 0;

        var numLightProbes = 0;

        lights.sort(shadowCastingAndTexturingLightsFirst);

        var scaleFactor = useLegacyLights ? Math.PI : 1;

        for (light in lights) {
            var color = light.color;
            var intensity = light.intensity;
            var distance = light.distance;

            var shadowMap = (light.shadow != null && light.shadow.map != null) ? light.shadow.map.texture : null;

            if (light.isAmbientLight) {
                r += color.r * intensity * scaleFactor;
                g += color.g * intensity * scaleFactor;
                b += color.b * intensity * scaleFactor;
            } else if (light.isLightProbe) {
                for (j in 0...9) state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
                numLightProbes++;
            } else if (light.isDirectionalLight) {
                var uniforms = cache.get(light);

                uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);

                if (light.castShadow) {
                    var shadow = light.shadow;
                    var shadowUniforms = shadowCache.get(light);

                    shadowUniforms.shadowBias = shadow.bias;
                    shadowUniforms.shadowNormalBias = shadow.normalBias;
                    shadowUniforms.shadowRadius = shadow.radius;
                    shadowUniforms.shadowMapSize = shadow.mapSize;

                    state.directionalShadow[directionalLength] = shadowUniforms;
                    state.directionalShadowMap[directionalLength] = shadowMap;
                    state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;

                    numDirectionalShadows++;
                }

                state.directional[directionalLength] = uniforms;
                directionalLength++;
            } else if (light.isSpotLight) {
                var uniforms = cache.get(light);

                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
                uniforms.distance = distance;
                uniforms.coneCos = Math.cos(light.angle);
                uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
                uniforms.decay = light.decay;

                state.spot[spotLength] = uniforms;

                var shadow = light.shadow;

                if (light.map != null) {
                    state.spotLightMap[numSpotMaps] = light.map;
                    numSpotMaps++;

                    shadow.updateMatrices(light);

                    if (light.castShadow) numSpotShadowsWithMaps++;
                }

                state.spotLightMatrix[spotLength] = shadow.matrix;

                if (light.castShadow) {
                    var shadowUniforms = shadowCache.get(light);

                    shadowUniforms.shadowBias = shadow.bias;
                    shadowUniforms.shadowNormalBias = shadow.normalBias;
                    shadowUniforms.shadowRadius = shadow.radius;
                    shadowUniforms.shadowMapSize = shadow.mapSize;

                    state.spotShadow[spotLength] = shadowUniforms;
                    state.spotShadowMap[spotLength] = shadowMap;

                    numSpotShadows++;
                }

                spotLength++;
            } else if (light.isRectAreaLight) {
                var uniforms = cache.get(light);

                uniforms.color.copy(color).multiplyScalar(intensity);
                uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
                uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

                state.rectArea[rectAreaLength] = uniforms;
                rectAreaLength++;
            } else if (light.isPointLight) {
                var uniforms = cache.get(light);

                uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
                uniforms.distance = light.distance;
                uniforms.decay = light.decay;

                if (light.castShadow) {
                    var shadow = light.shadow;
                    var shadowUniforms = shadowCache.get(light);

                    shadowUniforms.shadowBias = shadow.bias;
                    shadowUniforms.shadowNormalBias = shadow.normalBias;
                    shadowUniforms.shadowRadius = shadow.radius;
                    shadowUniforms.shadowMapSize = shadow.mapSize;
                    shadowUniforms.shadowCameraNear = shadow.camera.near;
                    shadowUniforms.shadowCameraFar = shadow.camera.far;

                    state.pointShadow[pointLength] = shadowUniforms;
                    state.pointShadowMap[pointLength] = shadowMap;
                    state.pointShadowMatrix[pointLength] = light.shadow.matrix;

                    numPointShadows++;
                }

                state.point[pointLength] = uniforms;
                pointLength++;
            } else if (light.isHemisphereLight) {
                var uniforms = cache.get(light);

                uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
                uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

                state.hemi[hemiLength] = uniforms;
                hemiLength++;
            }
        }

        state.ambient[0] = r;
        state.ambient[1] = g;
        state.ambient[2] = b;

        state.directional.length = directionalLength;
        state.spot.length = spotLength;
        state.rectArea.length = rectAreaLength;
        state.point.length = pointLength;
        state.hemi.length = hemiLength;
        state.numSpotLightShadowsWithMaps = numSpotShadowsWithMaps;
        state.numLightProbes = numLightProbes;

        state.hash.directionalLength = directionalLength;
        state.hash.pointLength = pointLength;
        state.hash.spotLength = spotLength;
        state.hash.rectAreaLength = rectAreaLength;
        state.hash.hemiLength = hemiLength;
        state.hash.numDirectionalShadows = numDirectionalShadows;
        state.hash.numPointShadows = numPointShadows;
        state.hash.numSpotShadows = numSpotShadows;
        state.hash.numSpotMaps = numSpotMaps;
        state.hash.numLightProbes = numLightProbes;

        state.version++;
    }

    private function shadowCastingAndTexturingLightsFirst(a:Dynamic, b:Dynamic):Int {
        if (a.castShadow && b.castShadow == false) {
            return -1;
        } else if (a.castShadow == false && b.castShadow) {
            return 1;
        } else if (a.map != null && b.map == null) {
            return -1;
        } else if (a.map == null && b.map != null) {
            return 1;
        } else {
            return 0;
        }
    }
}