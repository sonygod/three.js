package three.js.src.renderers.webgl;

import math.Color;
import math.Matrix4;
import math.Vector2;
import math.Vector3;
import shaders.UniformsLib;

class WebGLLights {
    static var nextVersion:Int = 0;

    static function UniformsCache():Dynamic {
        var lights:Array.<Dynamic> = [];

        return {
            get: function(light:Dynamic) {
                if (lights[light.id] != null) {
                    return lights[light.id];
                }

                var uniforms:Dynamic = null;

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

                lights[light.id] = uniforms;

                return uniforms;
            }
        };
    }

    static function ShadowUniformsCache():Dynamic {
        var lights:Array.<Dynamic> = [];

        return {
            get: function(light:Dynamic) {
                if (lights[light.id] != null) {
                    return lights[light.id];
                }

                var uniforms:Dynamic = null;

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

                lights[light.id] = uniforms;

                return uniforms;
            }
        };
    }

    static function shadowCastingAndTexturingLightsFirst(lightA:Dynamic, lightB:Dynamic):Int {
        return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
    }

    static function WebGLLights(extensions:Dynamic):Dynamic {
        var cache = UniformsCache();
        var shadowCache = ShadowUniformsCache();
        var state:Dynamic = {
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

        function setup(lights:Array<Dynamic>, useLegacyLights:Bool):Void {
            // ...
        }

        function setupView(lights:Array<Dynamic>, camera:Dynamic):Void {
            // ...
        }

        return {
            setup: setup,
            setupView: setupView,
            state: state
        };
    }
}