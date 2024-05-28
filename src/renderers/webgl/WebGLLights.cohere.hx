import haxe.ds.IntMap;
import js.html.CanvasElement;
import js.html.ImageData;
import js.html.OptionElement;
import js.html.Window;
import js.html._CanvasRenderingContext2D;
import js.html._CanvasRenderingContext2D.LineCap;
import js.html._CanvasRenderingContext2D.LineJoin;
import js.html._CanvasRenderingContext2D.TextAlign;
import js.html._CanvasRenderingContext2D.TextBaseline;
import js.html._ImageData;
import js.html._OptionElement;
import js.html._Window;
import js.sys.ArrayBuffer;
import js.sys.ArrayBufferView;
import js.sys.DataView;
import js.sys.Float32Array;
import js.sys.Float64Array;
import js.sys.Int16Array;
import js.sys.Int32Array;
import js.sys.Int8Array;
import js.sys.Uint16Array;
import js.sys.Uint32Array;
import js.sys.Uint8Array;
import js.sys.Uint8ClampedArray;

class UniformsCache {
   var lights = new IntMap();

   public function get(light:Dynamic) {
      var id = light.id;
      if (lights.exists(id)) {
         return lights.get(id);
      }

      var uniforms:Dynamic;
      switch (light.type) {
         case "DirectionalLight":
            uniforms = {
               "direction": new openfl.geom.Vector3D(),
               "color": new openfl.display.AGALMiniAssembler()
            };
            break;
         case "SpotLight":
            uniforms = {
               "position": new openfl.geom.Vector3D(),
               "direction": new openfl.geom.Vector3D(),
               "color": new openfl.display.AGALMiniAssembler(),
               "distance": 0,
               "coneCos": 0,
               "penumbraCos": 0,
               "decay": 0
            };
            break;
         case "PointLight":
            uniforms = {
               "position": new openfl.geom.Vector3D(),
               "color": new openfl.display.AGALMiniAssembler(),
               "distance": 0,
               "decay": 0
            };
            break;
         case "HemisphereLight":
            uniforms = {
               "direction": new openfl.geom.Vector3D(),
               "skyColor": new openfl.display.AGALMiniAssembler(),
               "groundColor": new openfl.display.AGALMiniAssembler()
            };
            break;
         case "RectAreaLight":
            uniforms = {
               "color": new openfl.display.AGALMiniAssembler(),
               "position": new openfl.geom.Vector3D(),
               "halfWidth": new openfl.geom.Vector3D(),
               "halfHeight": new openfl.geom.Vector3D()
            };
            break;
      }

      lights.set(id, uniforms);
      return uniforms;
   }
}

class ShadowUniformsCache {
   var lights = new IntMap();

   public function get(light:Dynamic) {
      var id = light.id;
      if (lights.exists(id)) {
         return lights.get(id);
      }

      var uniforms:Dynamic;
      switch (light.type) {
         case "DirectionalLight":
            uniforms = {
               "shadowBias": 0,
               "shadowNormalBias": 0,
               "shadowRadius": 1,
               "shadowMapSize": new openfl.geom.Vector2D()
            };
            break;
         case "SpotLight":
            uniforms = {
               "shadowBias": 0,
               "shadowNormalBias": 0,
               "shadowRadius": 1,
               "shadowMapSize": new openfl.geom.Vector2D()
            };
            break;
         case "PointLight":
            uniforms = {
               "shadowBias": 0,
               "shadowNormalBias": 0,
               "shadowRadius": 1,
               "shadowMapSize": new openfl.geom.Vector2D(),
               "shadowCameraNear": 1,
               "shadowCameraFar": 1000
            };
            break;
      }

      lights.set(id, uniforms);
      return uniforms;
   }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Dynamic, lightB:Dynamic) {
   return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
   var cache = new UniformsCache();
   var shadowCache = new ShadowUniformsCache();
   var state = {
      "version": 0,
      "hash": {
         "directionalLength": -1,
         "pointLength": -1,
         "spotLength": -1,
         "rectAreaLength": -1,
         "hemiLength": -1,
         "numDirectionalShadows": -1,
         "numPointShadows": -1,
         "numSpotShadows": -1,
         "numSpotMaps": -1,
         "numLightProbes": -1
      },
      "ambient": [0, 0, 0],
      "probe": [],
      "directional": [],
      "directionalShadow": [],
      "directionalShadowMap": [],
      "directionalShadowMatrix": [],
      "spot": [],
      "spotLightMap": [],
      "spotShadow": [],
      "spotShadowMap": [],
      "spotLightMatrix": [],
      "rectArea": [],
      "rectAreaLTC1": null,
      "rectAreaLTC2": null,
      "point": [],
      "pointShadow": [],
      "pointShadowMap": [],
      "pointShadowMatrix": [],
      "hemi": [],
      "numSpotLightShadowsWithMaps": 0,
      "numLightProbes": 0
   };

   public function new(extensions:Dynamic) {
      for (i in 0...9) {
         state.probe.push(new openfl.geom.Vector3D());
      }

      var vector3 = new openfl.geom.Vector3D();
      var matrix4 = new openfl.geom.Matrix3D();
      var matrix42 = new openfl.geom.Matrix3D();

      function setup(lights:Array<Dynamic>, useLegacyLights:Bool) {
         var r = 0;
         var g = 0;
         var b = 0;

         for (i in 0...9) {
            state.probe[i].setTo(0, 0, 0);
         }

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

         // ordering : [shadow casting + map texturing, map texturing, shadow casting, none ]
         lights.sort(shadowCastingAndTexturingLightsFirst);

         // artist-friendly light intensity scaling factor
         var scaleFactor = (useLegacyLights) ? Math.PI : 1;

         for (i in 0...lights.length) {
            var light = lights[i];

            var color = light.color;
            var intensity = light.intensity;
            var distance = light.distance;

            var shadowMap = (light.shadow && light.shadow.map) ? light.shadow.map.texture : null;

            if (light.isAmbientLight) {
               r += color.r * intensity * scaleFactor;
               g += color.g * intensity * scaleFactor;
               b += color.b * intensity * scaleFactor;
            } else if (light.isLightProbe) {
               for (j in 0...9) {
                  state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
               }

               numLightProbes++;
            } else if (light.isDirectionalLight) {
               var uniforms = cache.get(light);

               uniforms.color.copyFrom(light.color).multiplyScalar(light.intensity * scaleFactor);

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

               uniforms.position.copyFrom(light.matrixWorld.translation);

               uniforms.color.copyFrom(color).multiplyScalar(intensity * scaleFactor);
               uniforms.distance = distance;

               uniforms.coneCos = Math.cos(light.angle);
               uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
               uniforms.decay = light.decay;

               state.spot[spotLength] = uniforms;

               var shadow = light.shadow;

               if (light.map) {
                  state.spotLightMap[numSpotMaps] = light.map;
                  numSpotMaps++;

                  // make sure the lightMatrix is up to date
                  // TODO : do it if required only
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

               uniforms.color.copyFrom(color).multiplyScalar(intensity);

               uniforms.halfWidth.setTo(light.width * 0.5, 0.0, 0.0);
               uniforms.halfHeight.setTo(0.0, light.height * 0.5, 0.0);

               state.rectArea[rectAreaLength] = uniforms;

               rectAreaLength++;
            } else if (light.isPointLight) {
               var uniforms = cache.get(light);

               uniforms.color.copyFrom(light.color).multiplyScalar(light.intensity * scaleFactor);
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

               uniforms.skyColor.copyFrom(light.color).multiplyScalar(intensity * scaleFactor);
               uniforms.groundColor.copyFrom(light.groundColor).multiplyScalar(intensity * scaleFactor);

               state.hemi[hemiLength] = uniforms;

               hemiLength++;
            }
         }

         if (rectAreaLength > 0) {
            if (extensions.has("OES_texture_float_linear")) {
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

         if (hash.directionalLength != directionalLength || hash.pointLength != pointLength || hash.spotLength != spotLength || hash.rectAreaLength != rectAreaLength || hash.hemiLength != hemiLength || hash.numDirectionalShadows != numDirectionalShadows || hash.numPointShadows != numPointShadows || hash.numSpotShadows != numSpotShadows || hash.numSpotMaps != numSpotMaps || hash.numLightProbes != numLightProbes) {
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

      function setupView(lights:Array<Dynamic>, camera:Dynamic) {
         var directionalLength = 0;
         var pointLength = 0;
         var spotLength = 0;
         var rectAreaLength = 0;
         var hemiLength = 0;

         var viewMatrix = camera.matrixWorldInverse;

         for (i in 0...lights.length) {
            var light = lights[i];

            if (light.isDirectionalLight) {
               var uniforms = state.directional[directionalLength];

               uniforms.direction.copyFrom(light.matrixWorld.translation);
               vector3.setFromMatrixPosition(light.target.matrixWorld);
               uniforms.direction.subtract(vector3);
               uniforms.direction.transformDirection(viewMatrix);

               directionalLength++;
            } else if (light.isSpotLight) {
               var uniforms = state.spot[spotLength];

               uniforms.position.copyFrom(light.matrixWorld.translation);
               uniforms.position.applyMatrix4(viewMatrix);

               uniforms.direction.copyFrom(light.matrixWorld.translation);
               vector3.setFromMatrixPosition(light.target.matrixWorld);
               uniforms.direction.subtract(vector3);
               uniforms.direction.transformDirection(viewMatrix);

               spotLength++;
            } else if (light.isRectAreaLight) {
               var uniforms = state.rectArea[rectAreaLength];

               uniforms.position.copyFrom(light.matrixWorld.translation);
               uniforms.position.applyMatrix4(viewMatrix);

               // extract local rotation of light to derive width/height half vectors
               matrix42.identity();
               matrix4.copyFrom(light.matrixWorld);
               matrix4.premultiply(viewMatrix);
               matrix42.extractRotation(matrix4);

               uniforms.halfWidth.setTo(light.width * 0.5, 0.0, 0.0);
               uniforms.halfHeight.setTo(0.0, light.height * 0.5, 0.0);

               uniforms.halfWidth.applyMatrix4(matrix42);
               uniforms.halfHeight.applyMatrix4(matrix42);

               rectAreaLength++;
            } else if (light.isPointLight) {
               var uniforms = state.point[pointLength];

               uniforms.position.copyFrom(light.matrixWorld.translation);
               uniforms.position.applyMatrix4(viewMatrix);

               pointLength++;
            } else if (light.isHemisphereLight) {
               var uniforms = state.hemi[hemiLength];

               uniforms.direction.copyFrom(light.matrixWorld.translation);
               uniforms.direction.transformDirection(viewMatrix);

               hemiLength++;
            }
         }
      }

      return {
         "setup": setup,
         "setupView": setupView,
         "state": state
      };
   }
}