import Color from '../../math/Color.hx';
import Matrix4 from '../../math/Matrix4.hx';
import Vector2 from '../../math/Vector2.hx';
import Vector3 from '../../math/Vector3.hx';
import UniformsLib from '../shaders/UniformsLib.hx';

class UniformsCache {

    private static _instances:Map<String,Dynamic> = new Map();

    public static get(light:Dynamic):Dynamic {
        let id = light.id;
        if (UniformsCache._instances.containsKey(id)) {
            return UniformsCache._instances.get(id);
        }
        let uniforms:Dynamic;
        switch (light.type) {
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
        UniformsCache._instances.set(id, uniforms);
        return uniforms;
    }

}

class ShadowUniformsCache {

    private static _instances:Map<String,Dynamic> = new Map();

    public static get(light:Dynamic):Dynamic {
        let id = light.id;
        if (ShadowUniformsCache._instances.containsKey(id)) {
            return ShadowUniformsCache._instances.get(id);
        }
        let uniforms:Dynamic;
        switch (light.type) {
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
            case 'RectAreaLight':
                // TODO (abelnation): set RectAreaLight shadow uniforms
                break;
        }
        ShadowUniformsCache._instances.set(id, uniforms);
        return uniforms;
    }

}

let nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Dynamic, lightB:Dynamic):Int {
    return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {

    public extensions:Dynamic;
    public state:Dynamic;
    public cache:Dynamic;
    public shadowCache:Dynamic;

    public constructor(extensions:Dynamic) {
        this.extensions = extensions;
        this.state = {
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
            probe: new Array<Vector3>(),
            directional: new Array<Dynamic>(),
            directionalShadow: new Array<Dynamic>(),
            directionalShadowMap: new Array<Dynamic>(),
            directionalShadowMatrix: new Array<Dynamic>(),
            spot: new Array<Dynamic>(),
            spotLightMap: new Array<Dynamic>(),
            spotShadow: new Array<Dynamic>(),
            spotShadowMap: new Array<Dynamic>(),
            spotLightMatrix: new Array<Dynamic>(),
            rectArea: new Array<Dynamic>(),
            rectAreaLTC1: null,
            rectAreaLTC2: null,
            point: new Array<Dynamic>(),
            pointShadow: new Array<Dynamic>(),
            pointShadowMap: new Array<Dynamic>(),
            pointShadowMatrix: new Array<Dynamic>(),
            hemi: new Array<Dynamic>(),
            numSpotLightShadowsWithMaps: 0,
            numLightProbes: 0
        };
        for (let i = 0; i < 9; i++) this.state.probe.push(new Vector3());
        this.cache = new UniformsCache();
        this.shadowCache = new ShadowUniformsCache();
    }

    public setup(lights:Array<Dynamic>, useLegacyLights:Bool):Void {
        let r = 0, g = 0, b = 0;
        for (let i = 0; i < 9; i++) this.state.probe[i].set(0, 0, 0);
        let directionalLength = 0;
        let pointLength = 0;
        let spotLength = 0;
        let rectAreaLength = 0;
        let hemiLength = 0;
        let numDirectionalShadows = 0;
        let numPointShadows = 0;
        let numSpotShadows = 0;
        let numSpotMaps = 0;
        let numSpotShadowsWithMaps = 0;
        let numLightProbes = 0;
        lights.sort(shadowCastingAndTexturingLightsFirst);
        const scaleFactor = (useLegacyLights == true) ? Math.PI : 1;
        for (let i = 0, l = lights.length; i < l; i++) {
            const light = lights[i];
            const color = light.color;
            const intensity = light.intensity;
            const distance = light.distance;
            const shadowMap = (light.shadow && light.shadow.map) ? light.shadow.map.texture : null;
            if (light.isAmbientLight) {
                r += color.r * intensity * scaleFactor;
                g += color.g * intensity * scaleFactor;
                b += color.b * intensity * scaleFactor;
            } else if (light.isLightProbe) {
                for (let j = 0; j < 9; j++) {
                    this.state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
                }
                numLightProbes++;
            } else if (light.isDirectionalLight) {
                const uniforms = this.cache.get(light);
                uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
                if (light.castShadow) {
                    const shadow = light.shadow;
                    const shadowUniforms = this.shadowCache.get(light);
                    shadowUniforms.shadowBias = shadow.bias;
                    shadowUniforms.shadowNormalBias = shadow.normalBias;
                    shadowUniforms.shadowRadius = shadow.radius;
                    shadowUniforms.shadowMapSize = shadow.mapSize;
                    this.state.directionalShadow[directionalLength] = shadowUniforms;
                    this.state.directionalShadowMap[directionalLength] = shadowMap;
                    this.state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;
                    numDirectionalShadows++;
                }
                this.state.directional[directionalLength] = uniforms;
                directionalLength++;
            } else if (light.isSpotLight) {
                const uniforms = this.cache.get(light);
                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
                uniforms.distance = distance;
                uniforms.coneCos = Math.cos(light.angle);
                uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
                uniforms.decay = light.decay;
                this.state.spot[spotLength] = uniforms;
                const shadow = light.shadow;
                if (light.map) {
                    this.state.spotLightMap[numSpotMaps] = light.map;
                    numSpotMaps++;
                    // make sure the lightMatrix is up to date
                    // TODO : do it if required only
                    shadow.updateMatrices(light);
                    if (light.castShadow) numSpotShadowsWithMaps++;
                }
                this.state.spotLightMatrix[spotLength] = shadow.matrix;
                if (light.castShadow) {
                    const shadowUniforms = this.shadowCache.get(light);
                    shadowUniforms.shadowBias = shadow.bias;
                    shadowUniforms.shadowNormalBias = shadow.normalBias;
                    shadowUniforms.shadowRadius = shadow.radius;
                    shadowUniforms.shadowMapSize = shadow.mapSize;
                    this.state.spotShadow[spotLength] = shadowUniforms;
                    this.state.spotShadowMap[spotLength] = shadowMap;
                    numSpotShadows++;
                }
                spotLength++;
            } else if (light.isRectAreaLight) {
                const uniforms = this.cache.get(light);
                uniforms.color.copy(color).multiplyScalar(intensity);
                uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
                uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);
                this.state.rectArea[rectAreaLength] = uniforms;
                rectAreaLength++;
            } else if (light.isPointLight) {
                const uniforms = this.cache.get(light);
                uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
                uniforms.distance = light.distance;
                uniforms.decay = light.decay;
                if (light.castShadow) {
                    const shadow = light.shadow;
                    const shadowUniforms = this.shadowCache.get(light);
                    shadowUniforms.shadowBias = shadow.bias;
                    shadowUniforms.shadowNormalBias = shadow.normalBias;
                    shadowUniforms.shadowRadius = shadow.radius;
                    shadowUniforms.shadowMapSize = shadow.mapSize;
                    shadowUniforms.shadowCameraNear = shadow.camera.near;
                    shadowUniforms.shadowCameraFar = shadow.camera.far;
                    this.state.pointShadow[pointLength] = shadowUniforms;
                    this.state.pointShadowMap[pointLength] = shadowMap;
                    this.state.pointShadowMatrix[pointLength] = light.shadow.matrix;
                    numPointShadows++;
                }
                this.state.point[pointLength] = uniforms;
                pointLength++;
            } else if (light.isHemisphereLight) {
                const uniforms = this.cache.get(light);
                uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
                uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);
                this.state.hemi[hemiLength] = uniforms;
                hemiLength++;
            }
        }
        if (rectAreaLength > 0) {
            if (this.extensions.has('OES_texture_float_linear') == true) {
                this.state.rectAreaLTC1 = UniformsLib.LTC_FLOAT_1;
                this.state.rectAreaLTC2 = UniformsLib.LTC_FLOAT_2;
            } else {
                this.state.rectAreaLTC1 = UniformsLib.LTC_HALF_1;
                this.state.rectAreaLTC2 = UniformsLib.LTC_HALF_2;
            }
        }
        this.state.ambient[0] = r;
        this.state.ambient[1] = g;
        this.state.ambient[2] = b;
        const hash = this.state.hash;
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
            this.state.directional.length = directionalLength;
            this.state.spot.length = spotLength;
            this.state.rectArea.length = rectAreaLength;
            this.state.point.length = pointLength;
            this.state.hemi.length = hemiLength;
            this.state.directionalShadow.length = numDirectionalShadows;
            this.state.directionalShadowMap.length = numDirectionalShadows;
            this.state.pointShadow.length = numPointShadows;
            this.state.pointShadowMap.length = numPointShadows;
            this.state.spotShadow.length = numSpotShadows;
            this.state.spotShadowMap.length = numSpotShadows;
            this.state.directionalShadowMatrix.length = numDirectionalShadows;
            this.state.pointShadowMatrix.length = numPointShadows;
            this.state.spotLightMatrix.length = numSpotShadows + numSpotMaps - numSpotShadowsWithMaps;
            this.state.spotLightMap.length = numSpotMaps;
            this.state.numSpotLightShadowsWithMaps = numSpotShadowsWithMaps;
            this.state.numLightProbes = numLightProbes;
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
            this.state.version = nextVersion++;
        }
    }

    public setupView(lights:Array<Dynamic>, camera:Dynamic):Void {
        let directionalLength = 0;
        let pointLength = 0;
        let spotLength = 0;
        let rectAreaLength = 0;
        let hemiLength = 0;
        let viewMatrix = camera.matrixWorldInverse;
        for (let i = 0, l = lights.length; i < l; i++) {
            const light = lights[i];
            if (light.isDirectionalLight) {
                const uniforms = this.state.directional[directionalLength];
                uniforms.direction.setFromMatrixPosition(light.matrixWorld);
                Vector3.sub(uniforms.direction, uniforms.direction, light.target.matrixWorld.getPosition(Vector3.temp()));
                uniforms.direction.transformDirection(viewMatrix);
                directionalLength++;
            } else if (light.isSpotLight) {
                const uniforms = this.state.spot[spotLength];
                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.position.applyMatrix4(viewMatrix);
                uniforms.direction.setFromMatrixPosition(light.matrixWorld);
                Vector3.sub(uniforms.direction, uniforms.direction, light.target.matrixWorld.getPosition(Vector3.temp()));
                uniforms.direction.transformDirection(viewMatrix);
                spotLength++;
            } else if (light.isRectAreaLight) {
                const uniforms = this.state.rectArea[rectAreaLength];
                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.position.applyMatrix4(viewMatrix);
                // extract local rotation of light to derive width/height half vectors
                Matrix4.extractRotation(light.matrixWorld, matrix42);
                uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
                uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);
                uniforms.halfWidth.applyMatrix4(matrix42);
                uniforms.halfHeight.applyMatrix4(matrix42);
                rectAreaLength++;
            } else if (light.isPointLight) {
                const uniforms = this.state.point[pointLength];
                uniforms.position.setFromMatrixPosition(light.matrixWorld);
                uniforms.position.applyMatrix4(viewMatrix);
                pointLength++;
            } else if (light.isHemisphereLight) {
                const uniforms = this.state.hemi[hemiLength];
                uniforms.direction.setFromMatrixPosition(light.matrixWorld);
                uniforms.direction.transformDirection(viewMatrix);
                hemiLength++;
            }
        }
    }

}