import three.math.Color;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.renderers.shaders.UniformsLib;

class UniformsCache {
    private var lights:Map<Int,Dynamic>;

    public function new() {
        lights = new Map<Int,Dynamic>();
    }

    public function get(light:Dynamic):Dynamic {
        if (lights.exists(light.id)) {
            return lights.get(light.id);
        }

        var uniforms:Dynamic;

        switch(Std.string(Reflect.field(light, "type"))) {
            case 'DirectionalLight':
                uniforms = {
                    direction: new Vector3(),
                    color: new Color()
                };
                break;

            case 'SpotLight':
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

            case 'PointLight':
                uniforms = {
                    position: new Vector3(),
                    color: new Color(),
                    distance: 0,
                    decay: 0
                };
                break;

            case 'HemisphereLight':
                uniforms = {
                    direction: new Vector3(),
                    skyColor: new Color(),
                    groundColor: new Color()
                };
                break;

            case 'RectAreaLight':
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
    private var lights:Map<Int,Dynamic>;

    public function new() {
        lights = new Map<Int,Dynamic>();
    }

    public function get(light:Dynamic):Dynamic {
        if (lights.exists(light.id)) {
            return lights.get(light.id);
        }

        var uniforms:Dynamic;

        switch(Std.string(Reflect.field(light, "type"))) {
            case 'DirectionalLight':
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2()
                };
                break;

            case 'SpotLight':
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2()
                };
                break;

            case 'PointLight':
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2(),
                    shadowCameraNear: 1,
                    shadowCameraFar: 1000
                };
                break;

            // TODO (abelnation): set RectAreaLight shadow uniforms
        }

        lights.set(light.id, uniforms);

        return uniforms;
    }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Dynamic, lightB:Dynamic):Int {
    return ((lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0)) + ((lightB.map ? 1 : 0) - (lightA.map ? 1 : 0));
}

class WebGLLights {
    private var cache:UniformsCache;
    private var shadowCache:ShadowUniformsCache;
    private var state:Dynamic;
    private var vector3:Vector3;
    private var matrix4:Matrix4;
    private var matrix42:Matrix4;

    public function new(extensions:Dynamic) {
        cache = new UniformsCache();
        shadowCache = new ShadowUniformsCache();

        state = {
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

        for (var i = 0; i < 9; i++) state.probe.push(new Vector3());

        vector3 = new Vector3();
        matrix4 = new Matrix4();
        matrix42 = new Matrix4();
    }

    public function setup(lights:Array<Dynamic>, useLegacyLights:Bool) {
        var r = 0, g = 0, b = 0;

        for (var i = 0; i < 9; i++) state.probe[i].set(0, 0, 0);

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

        var scaleFactor = (useLegacyLights == true) ? Math.PI : 1;

        for (var i = 0, l = lights.length; i < l; i++) {
            var light = lights[i];

            var color = light.color;
            var intensity = light.intensity;
            var distance = light.distance;

            var shadowMap = (light.shadow && light.shadow.map) ? light.shadow.map.texture : null;

            if (Reflect.hasField(light, "isAmbientLight")) {
                r += color.r * intensity * scaleFactor;
                g += color.g * intensity * scaleFactor;
                b += color.b * intensity * scaleFactor;
            } else if (Reflect.hasField(light, "isLightProbe")) {
                for (var j = 0; j < 9; j++) {
                    state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
                }

                numLightProbes++;
            } else if (Reflect.hasField(light, "isDirectionalLight")) {
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
            } else if (Reflect.hasField(light, "isSpotLight")) {
                var uniforms = cache.get(light);

                uniforms.position.setFromMatrixPosition(light.matrixWorld);

                uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
                uniforms.distance = distance;

                uniforms.coneCos = Math.cos(light.angle);
                uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
                uniforms.decay = light.decay;

                state.spot[spotLength] = uniforms;

                var shadow = light.shadow;

                if (light.map) {
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
            } else if (Reflect.hasField(light, "isRectAreaLight")) {
                var uniforms = cache.get(light);

                uniforms.color.copy(color).multiplyScalar(intensity);

                uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
                uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

                state.rectArea[rectAreaLength] = uniforms;

                rectAreaLength++;
            } else if (Reflect.hasField(light, "isPointLight")) {
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
            } else if (Reflect.hasField(light, "isHemisphereLight")) {
                var uniforms = cache.get(light);

                uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
                uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

                state.hemi[hemiLength] = uniforms;

                hemiLength++;
            }
        }

        if (rectAreaLength > 0) {
            if (extensions.has('OES_texture_float_linear') == true) {
                state.rectAreaLTC1 = UniformsLib.LTC_FLOAT_1;
                state.rectAreaLTC2 = UniformsLib.LTC_FLOAT_2;
            } else {
                state.rectAreaLTC1 = UniformsLib.LTC_HALF_1;
                state.rectAreaLTC2 = UniformsLib.LTC_HALF_2;
            }
        }

        state.ambient[0] = r;
        state.ambient[1] = g;
        state.ambient[2] = b;

        var hash = state.hash;

        if (hash.directionalLength != directionalLength ||
            hash.pointLength != pointLength ||
            hash.spotLength != spotLength ||
            hash.rectAreaLength != rectAreaLength ||
            hash.hemiLength != hemiLength ||
            hash.numDirectionalShadows != numDirectionalShadows ||
            hash.numPointShadows != numPointShadows ||
            hash.numSpotShadows != numSpotShadows ||
            hash.numSpotMaps != numSpotMaps ||
            hash.numLightProbes != numLightProbes) {

            state.directional.length = directionalLength;
            state.spot.length = spotLength;
            state.rectArea.length = rectAreaLength;
            state.point.length = pointLength;
            state.hemi.length = hemiLength;

            state.directionalShadow.length = numDirectionalShadows;
            state.directionalShadowMap.length = numDirectionalShadows;
            state.pointShadow.length = numPointShadows;
            state.pointShadowMap.length = numPointShadows;
            state.spotShadow.length = numSpotShadows;
            state.spotShadowMap.length = numSpotShadows;
            state.directionalShadowMatrix.length = numDirectionalShadows;
            state.pointShadowMatrix.length = numPointShadows;
            state.spotLightMatrix.length = numSpotShadows + numSpotMaps - numSpotShadowsWithMaps;
            state.spotLightMap.length = numSpotMaps;
            state.numSpotLightShadowsWithMaps = numSpotShadowsWithMaps;
            state.numLightProbes = numLightProbes;

            hash.directionalLength = directionalLength;
            hash.pointLength = pointLength;
            hash.spotLength = spotLength;
            hash.rectAreaLength = rectAreaLength;
            hash.hemiLength = hemiLength;

            hash.numDirectionalShadows = numDirectionalShadows;
            hash.numPointShadows = numPointShadows;
            hash.numSpotShadows = numSpotShadows;
            hash.numSpotMaps = numSpotMaps;

            hash.numLightProbes = numLightProbes;

            state.version = nextVersion++;
        }
    }

    public function setupView(lights:Array<Dynamic>, camera:Dynamic) {
        var directionalLength = 0;
        var pointLength = 0;
        var spotLength = 0;
        var rectAreaLength = 0;
        var hemiLength = 0;

        var viewMatrix = camera.matrixWorldInverse;

        for (var i = 0, l = lights.length; i < l; i++) {
            var light = lights[i];

            if (Reflect.hasField(light, "isDirectionalLight")) {
                var uniforms = state.directional[directionalLength];

                uniforms.direction.setFromMatrixPosition(light.matrixWorld);
                vector3.setFromMatrixPosition(light.target.matrixWorld);
                uniforms.direction.sub(vector3);
                uniforms.direction.transformDirection(viewMatrix);

                directionalLength++;
            } else if (Reflect.hasField(light, "isSpotLight")) {
                var uniforms = state.spot[spotLength];

                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.position.applyMatrix4(viewMatrix);

                uniforms.direction.setFromMatrixPosition(light.matrixWorld);
                vector3.setFromMatrixPosition(light.target.matrixWorld);
                uniforms.direction.sub(vector3);
                uniforms.direction.transformDirection(viewMatrix);

                spotLength++;
            } else if (Reflect.hasField(light, "isRectAreaLight")) {
                var uniforms = state.rectArea[rectAreaLength];

                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.position.applyMatrix4(viewMatrix);

                matrix42.identity();
                matrix4.copy(light.matrixWorld);
                matrix4.premultiply(viewMatrix);
                matrix42.extractRotation(matrix4);

                uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
                uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

                uniforms.halfWidth.applyMatrix4(matrix42);
                uniforms.halfHeight.applyMatrix4(matrix42);

                rectAreaLength++;
            } else if (Reflect.hasField(light, "isPointLight")) {
                var uniforms = state.point[pointLength];

                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.position.applyMatrix4(viewMatrix);

                pointLength++;
            } else if (Reflect.hasField(light, "isHemisphereLight")) {
                var uniforms = state.hemi[hemiLength];

                uniforms.direction.setFromMatrixPosition(light.matrixWorld);
                uniforms.direction.transformDirection(viewMatrix);

                hemiLength++;
            }
        }
    }

    public function get_state():Dynamic {
        return state;
    }
}