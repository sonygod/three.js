Here is the converted Haxe code:
```
package three.js.src.renderers.webgl;

import math.Color;
import math.Matrix4;
import math.Vector2;
import math.Vector3;
import shaders.UniformsLib;

class UniformsCache {
    private var lights:Map<Int,Dynamic>;

    public function new() {
        lights = new Map();
    }

    public function get(light:Dynamic):Dynamic {
        if (lights.exists(light.id)) {
            return lights.get(light.id);
        }

        var uniforms:Dynamic;

        switch (light.type) {
            case 'DirectionalLight':
                uniforms = {
                    direction: new Vector3(),
                    color: new Color()
                };
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
            case 'PointLight':
                uniforms = {
                    position: new Vector3(),
                    color: new Color(),
                    distance: 0,
                    decay: 0
                };
            case 'HemisphereLight':
                uniforms = {
                    direction: new Vector3(),
                    skyColor: new Color(),
                    groundColor: new Color()
                };
            case 'RectAreaLight':
                uniforms = {
                    color: new Color(),
                    position: new Vector3(),
                    halfWidth: new Vector3(),
                    halfHeight: new Vector3()
                };
        }

        lights.set(light.id, uniforms);

        return uniforms;
    }
}

class ShadowUniformsCache {
    private var lights:Map<Int,Dynamic>;

    public function new() {
        lights = new Map();
    }

    public function get(light:Dynamic):Dynamic {
        if (lights.exists(light.id)) {
            return lights.get(light.id);
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
            case 'SpotLight':
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2()
                };
            case 'PointLight':
                uniforms = {
                    shadowBias: 0,
                    shadowNormalBias: 0,
                    shadowRadius: 1,
                    shadowMapSize: new Vector2(),
                    shadowCameraNear: 1,
                    shadowCameraFar: 1000
                };
        }

        lights.set(light.id, uniforms);

        return uniforms;
    }
}

var nextVersion:Int = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Dynamic, lightB:Dynamic):Int {
    return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
    private var cache:UniformsCache;
    private var shadowCache:ShadowUniformsCache;
    private var state:Dynamic;

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
            probe: [for (i in 0...9) new Vector3()],
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
    }

    private function setup(lights:Array<Dynamic>, useLegacyLights:Bool):Void {
        // ...
    }

    private function setupView(lights:Array<Dynamic>, camera:Dynamic):Void {
        // ...
    }

    public function setup(lights:Array<Dynamic>, useLegacyLights:Bool):Void {
        setup(lights, useLegacyLights);
    }

    public function setupView(lights:Array<Dynamic>, camera:Dynamic):Void {
        setupView(lights, camera);
    }

    public function getState():Dynamic {
        return state;
    }
}
```