import Color.Color;
import Matrix4.Matrix4;
import Vector2.Vector2;
import Vector3.Vector3;
import UniformsLib.UniformsLib;

class UniformsCache {
    private var lights:Map<Int, Dynamic>;

    public function new() {
        this.lights = new Map();
    }

    public function get(light:Dynamic):Dynamic {
        if (this.lights.exists(light.id)) {
            return this.lights.get(light.id);
        }

        var uniforms:Dynamic;

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

        this.lights.set(light.id, uniforms);

        return uniforms;
    }
}

class ShadowUniformsCache {
    private var lights:Map<Int, Dynamic>;

    public function new() {
        this.lights = new Map();
    }

    public function get(light:Dynamic):Dynamic {
        if (this.lights.exists(light.id)) {
            return this.lights.get(light.id);
        }

        var uniforms:Dynamic;

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
        }

        this.lights.set(light.id, uniforms);

        return uniforms;
    }
}

class WebGLLights {
    private var cache:UniformsCache;
    private var shadowCache:ShadowUniformsCache;
    private var state:Dynamic;

    public function new(extensions:Dynamic) {
        this.cache = new UniformsCache();
        this.shadowCache = new ShadowUniformsCache();

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

        for (i in 0...9) this.state.probe.push(new Vector3());

        var vector3:Vector3 = new Vector3();
        var matrix4:Matrix4 = new Matrix4();
        var matrix42:Matrix4 = new Matrix4();

        var setup = function(lights:Array<Dynamic>, useLegacyLights:Bool):Void {
            // ...
        };

        var setupView = function(lights:Array<Dynamic>, camera:Dynamic):Void {
            // ...
        };

        this.setup = setup;
        this.setupView = setupView;
    }
}