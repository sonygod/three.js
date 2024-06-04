import haxe.io.Bytes;
import haxe.io.Output;
import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3;
import openfl.utils.ByteArray;

class UniformsCache {
  public var lights:Map<Int, {
    direction:Vector3,
    color:Color
  }>;

  public function new() {
    this.lights = new Map<Int, {direction:Vector3, color:Color}>();
  }

  public function get(light:Light):{direction:Vector3, color:Color} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
    }

    var uniforms:Dynamic = null;

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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

class ShadowUniformsCache {
  public var lights:Map<Int, {
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;

  public function new() {
    this.lights = new Map<Int, {shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
  }

  public function get(light:Light):{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Light, lightB:Light):Int {
  return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
  public var cache:UniformsCache;
  public var shadowCache:ShadowUniformsCache;
  public var state:State;

  public function new(extensions:Dynamic) {
    this.cache = new UniformsCache();
    this.shadowCache = new ShadowUniformsCache();
    this.state = new State(extensions);
  }

  public function setup(lights:Array<Light>, useLegacyLights:Bool) {
    var r = 0;
    var g = 0;
    var b = 0;

    for (i in 0...9) {
      this.state.probe[i].set(0, 0, 0);
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

      var shadowMap = (light.shadow != null && light.shadow.map != null) ? light.shadow.map.texture : null;

      if (light.isAmbientLight) {
        r += color.r * intensity * scaleFactor;
        g += color.g * intensity * scaleFactor;
        b += color.b * intensity * scaleFactor;
      } else if (light.isLightProbe) {
        for (j in 0...9) {
          this.state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
        }

        numLightProbes++;
      } else if (light.isDirectionalLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.directionalShadow[directionalLength] = shadowUniforms;
          this.state.directionalShadowMap[directionalLength] = shadowMap;
          this.state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;

          numDirectionalShadows++;
        }

        this.state.directional[directionalLength] = uniforms;

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.cache.get(light);

        uniforms.position.setFromMatrixPosition(light.matrixWorld);

        uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
        uniforms.distance = distance;

        uniforms.coneCos = Math.cos(light.angle);
        uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
        uniforms.decay = light.decay;

        this.state.spot[spotLength] = uniforms;

        var shadow = light.shadow;

        if (light.map != null) {
          this.state.spotLightMap[numSpotMaps] = light.map;
          numSpotMaps++;

          // make sure the lightMatrix is up to date
          // TODO : do it if required only
          shadow.updateMatrices(light);

          if (light.castShadow) numSpotShadowsWithMaps++;
        }

        this.state.spotLightMatrix[spotLength] = shadow.matrix;

        if (light.castShadow) {
          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.spotShadow[spotLength] = shadowUniforms;
          this.state.spotShadowMap[spotLength] = shadowMap;

          numSpotShadows++;
        }

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(color).multiplyScalar(intensity);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        this.state.rectArea[rectAreaLength] = uniforms;

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
        uniforms.distance = light.distance;
        uniforms.decay = light.decay;

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);
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
        var uniforms = this.cache.get(light);

        uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
        uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

        this.state.hemi[hemiLength] = uniforms;

        hemiLength++;
      }
    }

    if (rectAreaLength > 0) {
      if (extensions.has('OES_texture_float_linear')) {
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

    var hash = this.state.hash;

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

  public function setupView(lights:Array<Light>, camera:Camera) {
    var directionalLength = 0;
    var pointLength = 0;
    var spotLength = 0;
    var rectAreaLength = 0;
    var hemiLength = 0;

    var viewMatrix = camera.matrixWorldInverse;

    for (i in 0...lights.length) {
      var light = lights[i];

      if (light.isDirectionalLight) {
        var uniforms = this.state.directional[directionalLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.state.spot[spotLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.state.rectArea[rectAreaLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        // extract local rotation of light to derive width/height half vectors
        var matrix42 = new Matrix3D();
        matrix42.identity();
        var matrix4 = new Matrix3D();
        matrix4.copy(light.matrixWorld);
        matrix4.premultiply(viewMatrix);
        matrix42.extractRotation(matrix4);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        uniforms.halfWidth.applyMatrix4(matrix42);
        uniforms.halfHeight.applyMatrix4(matrix42);

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.state.point[pointLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        pointLength++;
      } else if (light.isHemisphereLight) {
        var uniforms = this.state.hemi[hemiLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        uniforms.direction.transformDirection(viewMatrix);

        hemiLength++;
      }
    }
  }
}

class State {
  public var version:Int;
  public var hash:Hash;
  public var ambient:Array<Float>;
  public var probe:Array<Vector3>;
  public var directional:Array<{direction:Vector3, color:Color}>;
  public var directionalShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var directionalShadowMap:Array<Texture>;
  public var directionalShadowMatrix:Array<Matrix3D>;
  public var spot:Array<{
    position:Vector3,
    direction:Vector3,
    color:Color,
    distance:Float,
    coneCos:Float,
    penumbraCos:Float,
    decay:Float
  }>;
  public var spotLightMap:Array<Texture>;
  public var spotShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var spotShadowMap:Array<Texture>;
  public var spotLightMatrix:Array<Matrix3D>;
  public var rectArea:Array<{
    color:Color,
    position:Vector3,
    halfWidth:Vector3,
    halfHeight:Vector3
  }>;
  public var rectAreaLTC1:Dynamic;
  public var rectAreaLTC2:Dynamic;
  public var point:Array<{
    position:Vector3,
    color:Color,
    distance:Float,
    decay:Float
  }>;
  public var pointShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;
  public var pointShadowMap:Array<Texture>;
  public var pointShadowMatrix:Array<Matrix3D>;
  public var hemi:Array<{
    direction:Vector3,
    skyColor:Color,
    groundColor:Color
  }>;
  public var numSpotLightShadowsWithMaps:Int;
  public var numLightProbes:Int;

  public function new(extensions:Dynamic) {
    this.version = 0;
    this.hash = new Hash();
    this.ambient = [0, 0, 0];
    this.probe = new Array<Vector3>();
    this.directional = new Array<{direction:Vector3, color:Color}>();
    this.directionalShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.directionalShadowMap = new Array<Texture>();
    this.directionalShadowMatrix = new Array<Matrix3D>();
    this.spot = new Array<{position:Vector3, direction:Vector3, color:Color, distance:Float, coneCos:Float, penumbraCos:Float, decay:Float}>();
    this.spotLightMap = new Array<Texture>();
    this.spotShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.spotShadowMap = new Array<Texture>();
    this.spotLightMatrix = new Array<Matrix3D>();
    this.rectArea = new Array<{color:Color, position:Vector3, halfWidth:Vector3, halfHeight:Vector3}>();
    this.rectAreaLTC1 = null;
    this.rectAreaLTC2 = null;
    this.point = new Array<{position:Vector3, color:Color, distance:Float, decay:Float}>();
    this.pointShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
    this.pointShadowMap = new Array<Texture>();
    this.pointShadowMatrix = new Array<Matrix3D>();
    this.hemi = new Array<{direction:Vector3, skyColor:Color, groundColor:Color}>();
    this.numSpotLightShadowsWithMaps = 0;
    this.numLightProbes = 0;

    for (i in 0...9) {
      this.probe.push(new Vector3());
    }
  }
}

class Color {
  public var r:Float;
  public var g:Float;
  public var b:Float;

  public function new(r:Float = 0, g:Float = 0, b:Float = 0) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  public function copy(color:Color):Color {
    this.r = color.r;
    this.g = color.g;
    this.b = color.b;

    return this;
  }

  public function multiplyScalar(s:Float):Color {
    this.r *= s;
    this.g *= s;
    this.b *= s;

    return this;
  }
}

class Vector2 {
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  public function set(x:Float, y:Float):Vector2 {
    this.x = x;
    this.y = y;

    return this;
  }
}

class Vector3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function set(x:Float, y:Float, z:Float):Vector3 {
    this.x = x;
    this.y = y;
    this.z = z;

    return this;
  }

  public function addScaledVector(v:Vector3, s:Float):Vector3 {
    this.x += v.x * s;
    this.y += v.y * s;
    this.z += v.z * s;

    return this;
  }

  public function copy(v:Vector3):Vector3 {
    this.x = v.x;
    this.y = v.y;
    this.z = v.z;

    return this;
  }

  public function sub(v:Vector3):Vector3 {
    this.x -= v.x;
    this.y -= v.y;
    this.z -= v.z;

    return this;
  }

  public function transformDirection(m:Matrix3D):Vector3 {
    var x = this.x;
    var y = this.y;
    var z = this.z;

    this.x = m.n11 * x + m.n12 * y + m.n13 * z;
    this.y = m.n21 * x + m.n22 * y + m.n23 * z;
    this.z = m.n31 * x + m.n32 * y + m.n33 * z;

    return this;
  }
}

class Matrix3D {
  public var n11:Float;
  public var n12:Float;
  public var n13:Float;
  public var n14:Float;
  public var n21:Float;
  public var n22:Float;
  public var n23:Float;
  public var n24:Float;
  public var n31:Float;
  public var n32:Float;
  public var n33:Float;
  public var n34:Float;
  public var n41:Float;
  public var n42:Float;
  public var n43:Float;
  public var n44:Float;

  public function new(n11:Float = 1, n12:Float = 0, n13:Float = 0, n14:Float = 0,
                    n21:Float = 0, n22:Float = 1, n23:Float = 0, n24:Float = 0,
                    n31:Float = 0, n32:Float = 0, n33:Float = 1, n34:Float = 0,
                    n41:Float = 0, n42:Float = 0, n43:Float = 0, n44:Float = 1) {
    this.n11 = n11;
    this.n12 = n12;
    this.n13 = n13;
    this.n14 = n14;
    this.n21 = n21;
    this.n22 = n22;
    this.n23 = n23;
    this.n24 = n24;
    this.n31 = n31;
    this.n32 = n32;
    this.n33 = n33;
    this.n34 = n34;
    this.n41 = n41;
    this.n42 = n42;
    this.n43 = n43;
    this.n44 = n44;
  }

  public function identity():Matrix3D {
    this.n11 = 1;
    this.n12 = 0;
    this.n13 = 0;
    this.n14 = 0;
    this.n21 = 0;
    this.n22 = 1;
    this.n23 = 0;
    this.n24 = 0;
    this.n31 = 0;
    this.n32 = 0;
    this.n33 = 1;
    this.n34 = 0;
    this.n41 = 0;
    this.n42 = 0;
    this.n43 = 0;
    this.n44 = 1;

    return this;
  }

  public function copy(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n14 = m.n14;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n24 = m.n24;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;
    this.n34 = m.n34;
    this.n41 = m.n41;
    this.n42 = m.n42;
    this.n43 = m.n43;
    this.n44 = m.n44;

    return this;
  }

  public function premultiply(m:Matrix3D):Matrix3D {
    var n11 = this.n11;
    var n12 = this.n12;
    var n13 = this.n13;
    var n14 = this.n14;
    var n21 = this.n21;
    var n22 = this.n22;
    var n23 = this.n23;
    var n24 = this.n24;
    var n31 = this.n31;
    var n32 = this.n32;
    var n33 = this.n33;
    var n34 = this.n34;
    var n41 = this.n41;
    var n42 = this.n42;
    var n43 = this.n43;
    var n44 = this.n44;

    this.n11 = m.n11 * n11 + m.n12 * n21 + m.n13 * n31 + m.n14 * n41;
    this.n12 = m.n11 * n12 + m.n12 * n22 + m.n13 * n32 + m.n14 * n42;
    this.n13 = m.n11 * n13 + m.n12 * n23 + m.n13 * n33 + m.n14 * n43;
    this.n14 = m.n11 * n14 + m.n12 * n24 + m.n13 * n34 + m.n14 * n44;

    this.n21 = m.n21 * n11 + m.n22 * n21 + m.n23 * n31 + m.n24 * n41;
    this.n22 = m.n21 * n12 + m.n22 * n22 + m.n23 * n32 + m.n24 * n42;
    this.n23 = m.n21 * n13 + m.n22 * n23 + m.n23 * n33 + m.n24 * n43;
    this.n24 = m.n21 * n14 + m.n22 * n24 + m.n23 * n34 + m.n24 * n44;

    this.n31 = m.n31 * n11 + m.n32 * n21 + m.n33 * n31 + m.n34 * n41;
    this.n32 = m.n31 * n12 + m.n32 * n22 + m.n33 * n32 + m.n34 * n42;
    this.n33 = m.n31 * n13 + m.n32 * n23 + m.n33 * n33 + m.n34 * n43;
    this.n34 = m.n31 * n14 + m.n32 * n24 + m.n33 * n34 + m.n34 * n44;

    this.n41 = m.n41 * n11 + m.n42 * n21 + m.n43 * n31 + m.n44 * n41;
    this.n42 = m.n41 * n12 + m.n42 * n22 + m.n43 * n32 + m.n44 * n42;
    this.n43 = m.n41 * n13 + m.n42 * n23 + m.n43 * n33 + m.n44 * n43;
    this.n44 = m.n41 * n14 + m.n42 * n24 + m.n43 * n34 + m.n44 * n44;

    return this;
  }

  public function extractRotation(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;

    return this;
  }
}

class Light {
  public var id:Int;
  public var type:String;
  public var color:Color;
  public var intensity:Float;
  public var distance:Float;
  public var castShadow:Bool;
  public var map:Texture;
  public var shadow:Dynamic;
  public var isAmbientLight:Bool;
  public var isLightProbe:Bool;
  public var isDirectionalLight:Bool;
  public var isSpotLight:Bool;
  public var isRectAreaLight:Bool;
  public var isPointLight:Bool;
  public var isHemisphereLight:Bool;
  public var matrixWorld:Matrix3D;
  public var target:Dynamic;
  public var angle:Float;
  public var penumbra:Float;
  public var decay:Float;
  public var sh:Dynamic;
  public var width:Float;
  public var height:Float;

  public function new() {
    this.id = 0;
    this.type = "";
    this.color = new Color();
    this.intensity = 1;
    this.distance = 0;
    this.castShadow = false;
    this.map = null;
    this.shadow = null;
    this.isAmbientLight = false;
    this.isLightProbe = false;
    this.isDirectionalLight = false;
    this.isSpotLight = false;

import haxe.io.Bytes;
import haxe.io.Output;
import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3;
import openfl.utils.ByteArray;

class UniformsCache {
  public var lights:Map<Int, {
    direction:Vector3,
    color:Color
  }>;

  public function new() {
    this.lights = new Map<Int, {direction:Vector3, color:Color}>();
  }

  public function get(light:Light):{direction:Vector3, color:Color} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
    }

    var uniforms:Dynamic = null;

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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

class ShadowUniformsCache {
  public var lights:Map<Int, {
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;

  public function new() {
    this.lights = new Map<Int, {shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
  }

  public function get(light:Light):{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Light, lightB:Light):Int {
  return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
  public var cache:UniformsCache;
  public var shadowCache:ShadowUniformsCache;
  public var state:State;

  public function new(extensions:Dynamic) {
    this.cache = new UniformsCache();
    this.shadowCache = new ShadowUniformsCache();
    this.state = new State(extensions);
  }

  public function setup(lights:Array<Light>, useLegacyLights:Bool) {
    var r = 0;
    var g = 0;
    var b = 0;

    for (i in 0...9) {
      this.state.probe[i].set(0, 0, 0);
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

      var shadowMap = (light.shadow != null && light.shadow.map != null) ? light.shadow.map.texture : null;

      if (light.isAmbientLight) {
        r += color.r * intensity * scaleFactor;
        g += color.g * intensity * scaleFactor;
        b += color.b * intensity * scaleFactor;
      } else if (light.isLightProbe) {
        for (j in 0...9) {
          this.state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
        }

        numLightProbes++;
      } else if (light.isDirectionalLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.directionalShadow[directionalLength] = shadowUniforms;
          this.state.directionalShadowMap[directionalLength] = shadowMap;
          this.state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;

          numDirectionalShadows++;
        }

        this.state.directional[directionalLength] = uniforms;

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.cache.get(light);

        uniforms.position.setFromMatrixPosition(light.matrixWorld);

        uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
        uniforms.distance = distance;

        uniforms.coneCos = Math.cos(light.angle);
        uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
        uniforms.decay = light.decay;

        this.state.spot[spotLength] = uniforms;

        var shadow = light.shadow;

        if (light.map != null) {
          this.state.spotLightMap[numSpotMaps] = light.map;
          numSpotMaps++;

          // make sure the lightMatrix is up to date
          // TODO : do it if required only
          shadow.updateMatrices(light);

          if (light.castShadow) numSpotShadowsWithMaps++;
        }

        this.state.spotLightMatrix[spotLength] = shadow.matrix;

        if (light.castShadow) {
          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.spotShadow[spotLength] = shadowUniforms;
          this.state.spotShadowMap[spotLength] = shadowMap;

          numSpotShadows++;
        }

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(color).multiplyScalar(intensity);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        this.state.rectArea[rectAreaLength] = uniforms;

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
        uniforms.distance = light.distance;
        uniforms.decay = light.decay;

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);
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
        var uniforms = this.cache.get(light);

        uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
        uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

        this.state.hemi[hemiLength] = uniforms;

        hemiLength++;
      }
    }

    if (rectAreaLength > 0) {
      if (extensions.has('OES_texture_float_linear')) {
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

    var hash = this.state.hash;

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

  public function setupView(lights:Array<Light>, camera:Camera) {
    var directionalLength = 0;
    var pointLength = 0;
    var spotLength = 0;
    var rectAreaLength = 0;
    var hemiLength = 0;

    var viewMatrix = camera.matrixWorldInverse;

    for (i in 0...lights.length) {
      var light = lights[i];

      if (light.isDirectionalLight) {
        var uniforms = this.state.directional[directionalLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.state.spot[spotLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.state.rectArea[rectAreaLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        // extract local rotation of light to derive width/height half vectors
        var matrix42 = new Matrix3D();
        matrix42.identity();
        var matrix4 = new Matrix3D();
        matrix4.copy(light.matrixWorld);
        matrix4.premultiply(viewMatrix);
        matrix42.extractRotation(matrix4);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        uniforms.halfWidth.applyMatrix4(matrix42);
        uniforms.halfHeight.applyMatrix4(matrix42);

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.state.point[pointLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        pointLength++;
      } else if (light.isHemisphereLight) {
        var uniforms = this.state.hemi[hemiLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        uniforms.direction.transformDirection(viewMatrix);

        hemiLength++;
      }
    }
  }
}

class State {
  public var version:Int;
  public var hash:Hash;
  public var ambient:Array<Float>;
  public var probe:Array<Vector3>;
  public var directional:Array<{direction:Vector3, color:Color}>;
  public var directionalShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var directionalShadowMap:Array<Texture>;
  public var directionalShadowMatrix:Array<Matrix3D>;
  public var spot:Array<{
    position:Vector3,
    direction:Vector3,
    color:Color,
    distance:Float,
    coneCos:Float,
    penumbraCos:Float,
    decay:Float
  }>;
  public var spotLightMap:Array<Texture>;
  public var spotShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var spotShadowMap:Array<Texture>;
  public var spotLightMatrix:Array<Matrix3D>;
  public var rectArea:Array<{
    color:Color,
    position:Vector3,
    halfWidth:Vector3,
    halfHeight:Vector3
  }>;
  public var rectAreaLTC1:Dynamic;
  public var rectAreaLTC2:Dynamic;
  public var point:Array<{
    position:Vector3,
    color:Color,
    distance:Float,
    decay:Float
  }>;
  public var pointShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;
  public var pointShadowMap:Array<Texture>;
  public var pointShadowMatrix:Array<Matrix3D>;
  public var hemi:Array<{
    direction:Vector3,
    skyColor:Color,
    groundColor:Color
  }>;
  public var numSpotLightShadowsWithMaps:Int;
  public var numLightProbes:Int;

  public function new(extensions:Dynamic) {
    this.version = 0;
    this.hash = new Hash();
    this.ambient = [0, 0, 0];
    this.probe = new Array<Vector3>();
    this.directional = new Array<{direction:Vector3, color:Color}>();
    this.directionalShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.directionalShadowMap = new Array<Texture>();
    this.directionalShadowMatrix = new Array<Matrix3D>();
    this.spot = new Array<{position:Vector3, direction:Vector3, color:Color, distance:Float, coneCos:Float, penumbraCos:Float, decay:Float}>();
    this.spotLightMap = new Array<Texture>();
    this.spotShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.spotShadowMap = new Array<Texture>();
    this.spotLightMatrix = new Array<Matrix3D>();
    this.rectArea = new Array<{color:Color, position:Vector3, halfWidth:Vector3, halfHeight:Vector3}>();
    this.rectAreaLTC1 = null;
    this.rectAreaLTC2 = null;
    this.point = new Array<{position:Vector3, color:Color, distance:Float, decay:Float}>();
    this.pointShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
    this.pointShadowMap = new Array<Texture>();
    this.pointShadowMatrix = new Array<Matrix3D>();
    this.hemi = new Array<{direction:Vector3, skyColor:Color, groundColor:Color}>();
    this.numSpotLightShadowsWithMaps = 0;
    this.numLightProbes = 0;

    for (i in 0...9) {
      this.probe.push(new Vector3());
    }
  }
}

class Color {
  public var r:Float;
  public var g:Float;
  public var b:Float;

  public function new(r:Float = 0, g:Float = 0, b:Float = 0) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  public function copy(color:Color):Color {
    this.r = color.r;
    this.g = color.g;
    this.b = color.b;

    return this;
  }

  public function multiplyScalar(s:Float):Color {
    this.r *= s;
    this.g *= s;
    this.b *= s;

    return this;
  }
}

class Vector2 {
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  public function set(x:Float, y:Float):Vector2 {
    this.x = x;
    this.y = y;

    return this;
  }
}

class Vector3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function set(x:Float, y:Float, z:Float):Vector3 {
    this.x = x;
    this.y = y;
    this.z = z;

    return this;
  }

  public function addScaledVector(v:Vector3, s:Float):Vector3 {
    this.x += v.x * s;
    this.y += v.y * s;
    this.z += v.z * s;

    return this;
  }

  public function copy(v:Vector3):Vector3 {
    this.x = v.x;
    this.y = v.y;
    this.z = v.z;

    return this;
  }

  public function sub(v:Vector3):Vector3 {
    this.x -= v.x;
    this.y -= v.y;
    this.z -= v.z;

    return this;
  }

  public function transformDirection(m:Matrix3D):Vector3 {
    var x = this.x;
    var y = this.y;
    var z = this.z;

    this.x = m.n11 * x + m.n12 * y + m.n13 * z;
    this.y = m.n21 * x + m.n22 * y + m.n23 * z;
    this.z = m.n31 * x + m.n32 * y + m.n33 * z;

    return this;
  }
}

class Matrix3D {
  public var n11:Float;
  public var n12:Float;
  public var n13:Float;
  public var n14:Float;
  public var n21:Float;
  public var n22:Float;
  public var n23:Float;
  public var n24:Float;
  public var n31:Float;
  public var n32:Float;
  public var n33:Float;
  public var n34:Float;
  public var n41:Float;
  public var n42:Float;
  public var n43:Float;
  public var n44:Float;

  public function new(n11:Float = 1, n12:Float = 0, n13:Float = 0, n14:Float = 0,
                    n21:Float = 0, n22:Float = 1, n23:Float = 0, n24:Float = 0,
                    n31:Float = 0, n32:Float = 0, n33:Float = 1, n34:Float = 0,
                    n41:Float = 0, n42:Float = 0, n43:Float = 0, n44:Float = 1) {
    this.n11 = n11;
    this.n12 = n12;
    this.n13 = n13;
    this.n14 = n14;
    this.n21 = n21;
    this.n22 = n22;
    this.n23 = n23;
    this.n24 = n24;
    this.n31 = n31;
    this.n32 = n32;
    this.n33 = n33;
    this.n34 = n34;
    this.n41 = n41;
    this.n42 = n42;
    this.n43 = n43;
    this.n44 = n44;
  }

  public function identity():Matrix3D {
    this.n11 = 1;
    this.n12 = 0;
    this.n13 = 0;
    this.n14 = 0;
    this.n21 = 0;
    this.n22 = 1;
    this.n23 = 0;
    this.n24 = 0;
    this.n31 = 0;
    this.n32 = 0;
    this.n33 = 1;
    this.n34 = 0;
    this.n41 = 0;
    this.n42 = 0;
    this.n43 = 0;
    this.n44 = 1;

    return this;
  }

  public function copy(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n14 = m.n14;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n24 = m.n24;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;
    this.n34 = m.n34;
    this.n41 = m.n41;
    this.n42 = m.n42;
    this.n43 = m.n43;
    this.n44 = m.n44;

    return this;
  }

  public function premultiply(m:Matrix3D):Matrix3D {
    var n11 = this.n11;
    var n12 = this.n12;
    var n13 = this.n13;
    var n14 = this.n14;
    var n21 = this.n21;
    var n22 = this.n22;
    var n23 = this.n23;
    var n24 = this.n24;
    var n31 = this.n31;
    var n32 = this.n32;
    var n33 = this.n33;
    var n34 = this.n34;
    var n41 = this.n41;
    var n42 = this.n42;
    var n43 = this.n43;
    var n44 = this.n44;

    this.n11 = m.n11 * n11 + m.n12 * n21 + m.n13 * n31 + m.n14 * n41;
    this.n12 = m.n11 * n12 + m.n12 * n22 + m.n13 * n32 + m.n14 * n42;
    this.n13 = m.n11 * n13 + m.n12 * n23 + m.n13 * n33 + m.n14 * n43;
    this.n14 = m.n11 * n14 + m.n12 * n24 + m.n13 * n34 + m.n14 * n44;

    this.n21 = m.n21 * n11 + m.n22 * n21 + m.n23 * n31 + m.n24 * n41;
    this.n22 = m.n21 * n12 + m.n22 * n22 + m.n23 * n32 + m.n24 * n42;
    this.n23 = m.n21 * n13 + m.n22 * n23 + m.n23 * n33 + m.n24 * n43;
    this.n24 = m.n21 * n14 + m.n22 * n24 + m.n23 * n34 + m.n24 * n44;

    this.n31 = m.n31 * n11 + m.n32 * n21 + m.n33 * n31 + m.n34 * n41;
    this.n32 = m.n31 * n12 + m.n32 * n22 + m.n33 * n32 + m.n34 * n42;
    this.n33 = m.n31 * n13 + m.n32 * n23 + m.n33 * n33 + m.n34 * n43;
    this.n34 = m.n31 * n14 + m.n32 * n24 + m.n33 * n34 + m.n34 * n44;

    this.n41 = m.n41 * n11 + m.n42 * n21 + m.n43 * n31 + m.n44 * n41;
    this.n42 = m.n41 * n12 + m.n42 * n22 + m.n43 * n32 + m.n44 * n42;
    this.n43 = m.n41 * n13 + m.n42 * n23 + m.n43 * n33 + m.n44 * n43;
    this.n44 = m.n41 * n14 + m.n42 * n24 + m.n43 * n34 + m.n44 * n44;

    return this;
  }

  public function extractRotation(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;

    return this;
  }
}

class Light {
  public var id:Int;
  public var type:String;
  public var color:Color;
  public var intensity:Float;
  public var distance:Float;
  public var castShadow:Bool;
  public var map:Texture;
  public var shadow:Dynamic;
  public var isAmbientLight:Bool;
  public var isLightProbe:Bool;
  public var isDirectionalLight:Bool;
  public var isSpotLight:Bool;
  public var isRectAreaLight:Bool;
  public var isPointLight:Bool;
  public var isHemisphereLight:Bool;
  public var matrixWorld:Matrix3D;
  public var target:Dynamic;
  public var angle:Float;
  public var penumbra:Float;
  public var decay:Float;
  public var sh:Dynamic;
  public var width:Float;
  public var height:Float;

  public function new() {
    this.id = 0;
    this.type = "";
    this.color = new Color();
    this.intensity = 1;
    this.distance = 0;
    this.castShadow = false;
    this.map = null;
    this.shadow = null;
    this.isAmbientLight = false;
    this.isLightProbe = false;
    this.isDirectionalLight = false;
    this.isSpotLight = false;

import haxe.io.Bytes;
import haxe.io.Output;
import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3;
import openfl.utils.ByteArray;

class UniformsCache {
  public var lights:Map<Int, {
    direction:Vector3,
    color:Color
  }>;

  public function new() {
    this.lights = new Map<Int, {direction:Vector3, color:Color}>();
  }

  public function get(light:Light):{direction:Vector3, color:Color} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
    }

    var uniforms:Dynamic = null;

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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

class ShadowUniformsCache {
  public var lights:Map<Int, {
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;

  public function new() {
    this.lights = new Map<Int, {shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
  }

  public function get(light:Light):{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Light, lightB:Light):Int {
  return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
  public var cache:UniformsCache;
  public var shadowCache:ShadowUniformsCache;
  public var state:State;

  public function new(extensions:Dynamic) {
    this.cache = new UniformsCache();
    this.shadowCache = new ShadowUniformsCache();
    this.state = new State(extensions);
  }

  public function setup(lights:Array<Light>, useLegacyLights:Bool) {
    var r = 0;
    var g = 0;
    var b = 0;

    for (i in 0...9) {
      this.state.probe[i].set(0, 0, 0);
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

      var shadowMap = (light.shadow != null && light.shadow.map != null) ? light.shadow.map.texture : null;

      if (light.isAmbientLight) {
        r += color.r * intensity * scaleFactor;
        g += color.g * intensity * scaleFactor;
        b += color.b * intensity * scaleFactor;
      } else if (light.isLightProbe) {
        for (j in 0...9) {
          this.state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
        }

        numLightProbes++;
      } else if (light.isDirectionalLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.directionalShadow[directionalLength] = shadowUniforms;
          this.state.directionalShadowMap[directionalLength] = shadowMap;
          this.state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;

          numDirectionalShadows++;
        }

        this.state.directional[directionalLength] = uniforms;

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.cache.get(light);

        uniforms.position.setFromMatrixPosition(light.matrixWorld);

        uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
        uniforms.distance = distance;

        uniforms.coneCos = Math.cos(light.angle);
        uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
        uniforms.decay = light.decay;

        this.state.spot[spotLength] = uniforms;

        var shadow = light.shadow;

        if (light.map != null) {
          this.state.spotLightMap[numSpotMaps] = light.map;
          numSpotMaps++;

          // make sure the lightMatrix is up to date
          // TODO : do it if required only
          shadow.updateMatrices(light);

          if (light.castShadow) numSpotShadowsWithMaps++;
        }

        this.state.spotLightMatrix[spotLength] = shadow.matrix;

        if (light.castShadow) {
          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.spotShadow[spotLength] = shadowUniforms;
          this.state.spotShadowMap[spotLength] = shadowMap;

          numSpotShadows++;
        }

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(color).multiplyScalar(intensity);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        this.state.rectArea[rectAreaLength] = uniforms;

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
        uniforms.distance = light.distance;
        uniforms.decay = light.decay;

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);
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
        var uniforms = this.cache.get(light);

        uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
        uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

        this.state.hemi[hemiLength] = uniforms;

        hemiLength++;
      }
    }

    if (rectAreaLength > 0) {
      if (extensions.has('OES_texture_float_linear')) {
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

    var hash = this.state.hash;

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

  public function setupView(lights:Array<Light>, camera:Camera) {
    var directionalLength = 0;
    var pointLength = 0;
    var spotLength = 0;
    var rectAreaLength = 0;
    var hemiLength = 0;

    var viewMatrix = camera.matrixWorldInverse;

    for (i in 0...lights.length) {
      var light = lights[i];

      if (light.isDirectionalLight) {
        var uniforms = this.state.directional[directionalLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.state.spot[spotLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.state.rectArea[rectAreaLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        // extract local rotation of light to derive width/height half vectors
        var matrix42 = new Matrix3D();
        matrix42.identity();
        var matrix4 = new Matrix3D();
        matrix4.copy(light.matrixWorld);
        matrix4.premultiply(viewMatrix);
        matrix42.extractRotation(matrix4);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        uniforms.halfWidth.applyMatrix4(matrix42);
        uniforms.halfHeight.applyMatrix4(matrix42);

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.state.point[pointLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        pointLength++;
      } else if (light.isHemisphereLight) {
        var uniforms = this.state.hemi[hemiLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        uniforms.direction.transformDirection(viewMatrix);

        hemiLength++;
      }
    }
  }
}

class State {
  public var version:Int;
  public var hash:Hash;
  public var ambient:Array<Float>;
  public var probe:Array<Vector3>;
  public var directional:Array<{direction:Vector3, color:Color}>;
  public var directionalShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var directionalShadowMap:Array<Texture>;
  public var directionalShadowMatrix:Array<Matrix3D>;
  public var spot:Array<{
    position:Vector3,
    direction:Vector3,
    color:Color,
    distance:Float,
    coneCos:Float,
    penumbraCos:Float,
    decay:Float
  }>;
  public var spotLightMap:Array<Texture>;
  public var spotShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var spotShadowMap:Array<Texture>;
  public var spotLightMatrix:Array<Matrix3D>;
  public var rectArea:Array<{
    color:Color,
    position:Vector3,
    halfWidth:Vector3,
    halfHeight:Vector3
  }>;
  public var rectAreaLTC1:Dynamic;
  public var rectAreaLTC2:Dynamic;
  public var point:Array<{
    position:Vector3,
    color:Color,
    distance:Float,
    decay:Float
  }>;
  public var pointShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;
  public var pointShadowMap:Array<Texture>;
  public var pointShadowMatrix:Array<Matrix3D>;
  public var hemi:Array<{
    direction:Vector3,
    skyColor:Color,
    groundColor:Color
  }>;
  public var numSpotLightShadowsWithMaps:Int;
  public var numLightProbes:Int;

  public function new(extensions:Dynamic) {
    this.version = 0;
    this.hash = new Hash();
    this.ambient = [0, 0, 0];
    this.probe = new Array<Vector3>();
    this.directional = new Array<{direction:Vector3, color:Color}>();
    this.directionalShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.directionalShadowMap = new Array<Texture>();
    this.directionalShadowMatrix = new Array<Matrix3D>();
    this.spot = new Array<{position:Vector3, direction:Vector3, color:Color, distance:Float, coneCos:Float, penumbraCos:Float, decay:Float}>();
    this.spotLightMap = new Array<Texture>();
    this.spotShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.spotShadowMap = new Array<Texture>();
    this.spotLightMatrix = new Array<Matrix3D>();
    this.rectArea = new Array<{color:Color, position:Vector3, halfWidth:Vector3, halfHeight:Vector3}>();
    this.rectAreaLTC1 = null;
    this.rectAreaLTC2 = null;
    this.point = new Array<{position:Vector3, color:Color, distance:Float, decay:Float}>();
    this.pointShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
    this.pointShadowMap = new Array<Texture>();
    this.pointShadowMatrix = new Array<Matrix3D>();
    this.hemi = new Array<{direction:Vector3, skyColor:Color, groundColor:Color}>();
    this.numSpotLightShadowsWithMaps = 0;
    this.numLightProbes = 0;

    for (i in 0...9) {
      this.probe.push(new Vector3());
    }
  }
}

class Color {
  public var r:Float;
  public var g:Float;
  public var b:Float;

  public function new(r:Float = 0, g:Float = 0, b:Float = 0) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  public function copy(color:Color):Color {
    this.r = color.r;
    this.g = color.g;
    this.b = color.b;

    return this;
  }

  public function multiplyScalar(s:Float):Color {
    this.r *= s;
    this.g *= s;
    this.b *= s;

    return this;
  }
}

class Vector2 {
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  public function set(x:Float, y:Float):Vector2 {
    this.x = x;
    this.y = y;

    return this;
  }
}

class Vector3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function set(x:Float, y:Float, z:Float):Vector3 {
    this.x = x;
    this.y = y;
    this.z = z;

    return this;
  }

  public function addScaledVector(v:Vector3, s:Float):Vector3 {
    this.x += v.x * s;
    this.y += v.y * s;
    this.z += v.z * s;

    return this;
  }

  public function copy(v:Vector3):Vector3 {
    this.x = v.x;
    this.y = v.y;
    this.z = v.z;

    return this;
  }

  public function sub(v:Vector3):Vector3 {
    this.x -= v.x;
    this.y -= v.y;
    this.z -= v.z;

    return this;
  }

  public function transformDirection(m:Matrix3D):Vector3 {
    var x = this.x;
    var y = this.y;
    var z = this.z;

    this.x = m.n11 * x + m.n12 * y + m.n13 * z;
    this.y = m.n21 * x + m.n22 * y + m.n23 * z;
    this.z = m.n31 * x + m.n32 * y + m.n33 * z;

    return this;
  }
}

class Matrix3D {
  public var n11:Float;
  public var n12:Float;
  public var n13:Float;
  public var n14:Float;
  public var n21:Float;
  public var n22:Float;
  public var n23:Float;
  public var n24:Float;
  public var n31:Float;
  public var n32:Float;
  public var n33:Float;
  public var n34:Float;
  public var n41:Float;
  public var n42:Float;
  public var n43:Float;
  public var n44:Float;

  public function new(n11:Float = 1, n12:Float = 0, n13:Float = 0, n14:Float = 0,
                    n21:Float = 0, n22:Float = 1, n23:Float = 0, n24:Float = 0,
                    n31:Float = 0, n32:Float = 0, n33:Float = 1, n34:Float = 0,
                    n41:Float = 0, n42:Float = 0, n43:Float = 0, n44:Float = 1) {
    this.n11 = n11;
    this.n12 = n12;
    this.n13 = n13;
    this.n14 = n14;
    this.n21 = n21;
    this.n22 = n22;
    this.n23 = n23;
    this.n24 = n24;
    this.n31 = n31;
    this.n32 = n32;
    this.n33 = n33;
    this.n34 = n34;
    this.n41 = n41;
    this.n42 = n42;
    this.n43 = n43;
    this.n44 = n44;
  }

  public function identity():Matrix3D {
    this.n11 = 1;
    this.n12 = 0;
    this.n13 = 0;
    this.n14 = 0;
    this.n21 = 0;
    this.n22 = 1;
    this.n23 = 0;
    this.n24 = 0;
    this.n31 = 0;
    this.n32 = 0;
    this.n33 = 1;
    this.n34 = 0;
    this.n41 = 0;
    this.n42 = 0;
    this.n43 = 0;
    this.n44 = 1;

    return this;
  }

  public function copy(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n14 = m.n14;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n24 = m.n24;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;
    this.n34 = m.n34;
    this.n41 = m.n41;
    this.n42 = m.n42;
    this.n43 = m.n43;
    this.n44 = m.n44;

    return this;
  }

  public function premultiply(m:Matrix3D):Matrix3D {
    var n11 = this.n11;
    var n12 = this.n12;
    var n13 = this.n13;
    var n14 = this.n14;
    var n21 = this.n21;
    var n22 = this.n22;
    var n23 = this.n23;
    var n24 = this.n24;
    var n31 = this.n31;
    var n32 = this.n32;
    var n33 = this.n33;
    var n34 = this.n34;
    var n41 = this.n41;
    var n42 = this.n42;
    var n43 = this.n43;
    var n44 = this.n44;

    this.n11 = m.n11 * n11 + m.n12 * n21 + m.n13 * n31 + m.n14 * n41;
    this.n12 = m.n11 * n12 + m.n12 * n22 + m.n13 * n32 + m.n14 * n42;
    this.n13 = m.n11 * n13 + m.n12 * n23 + m.n13 * n33 + m.n14 * n43;
    this.n14 = m.n11 * n14 + m.n12 * n24 + m.n13 * n34 + m.n14 * n44;

    this.n21 = m.n21 * n11 + m.n22 * n21 + m.n23 * n31 + m.n24 * n41;
    this.n22 = m.n21 * n12 + m.n22 * n22 + m.n23 * n32 + m.n24 * n42;
    this.n23 = m.n21 * n13 + m.n22 * n23 + m.n23 * n33 + m.n24 * n43;
    this.n24 = m.n21 * n14 + m.n22 * n24 + m.n23 * n34 + m.n24 * n44;

    this.n31 = m.n31 * n11 + m.n32 * n21 + m.n33 * n31 + m.n34 * n41;
    this.n32 = m.n31 * n12 + m.n32 * n22 + m.n33 * n32 + m.n34 * n42;
    this.n33 = m.n31 * n13 + m.n32 * n23 + m.n33 * n33 + m.n34 * n43;
    this.n34 = m.n31 * n14 + m.n32 * n24 + m.n33 * n34 + m.n34 * n44;

    this.n41 = m.n41 * n11 + m.n42 * n21 + m.n43 * n31 + m.n44 * n41;
    this.n42 = m.n41 * n12 + m.n42 * n22 + m.n43 * n32 + m.n44 * n42;
    this.n43 = m.n41 * n13 + m.n42 * n23 + m.n43 * n33 + m.n44 * n43;
    this.n44 = m.n41 * n14 + m.n42 * n24 + m.n43 * n34 + m.n44 * n44;

    return this;
  }

  public function extractRotation(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;

    return this;
  }
}

class Light {
  public var id:Int;
  public var type:String;
  public var color:Color;
  public var intensity:Float;
  public var distance:Float;
  public var castShadow:Bool;
  public var map:Texture;
  public var shadow:Dynamic;
  public var isAmbientLight:Bool;
  public var isLightProbe:Bool;
  public var isDirectionalLight:Bool;
  public var isSpotLight:Bool;
  public var isRectAreaLight:Bool;
  public var isPointLight:Bool;
  public var isHemisphereLight:Bool;
  public var matrixWorld:Matrix3D;
  public var target:Dynamic;
  public var angle:Float;
  public var penumbra:Float;
  public var decay:Float;
  public var sh:Dynamic;
  public var width:Float;
  public var height:Float;

  public function new() {
    this.id = 0;
    this.type = "";
    this.color = new Color();
    this.intensity = 1;
    this.distance = 0;
    this.castShadow = false;
    this.map = null;
    this.shadow = null;
    this.isAmbientLight = false;
    this.isLightProbe = false;
    this.isDirectionalLight = false;
    this.isSpotLight = false;

import haxe.io.Bytes;
import haxe.io.Output;
import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3;
import openfl.utils.ByteArray;

class UniformsCache {
  public var lights:Map<Int, {
    direction:Vector3,
    color:Color
  }>;

  public function new() {
    this.lights = new Map<Int, {direction:Vector3, color:Color}>();
  }

  public function get(light:Light):{direction:Vector3, color:Color} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
    }

    var uniforms:Dynamic = null;

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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

class ShadowUniformsCache {
  public var lights:Map<Int, {
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;

  public function new() {
    this.lights = new Map<Int, {shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
  }

  public function get(light:Light):{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Light, lightB:Light):Int {
  return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
  public var cache:UniformsCache;
  public var shadowCache:ShadowUniformsCache;
  public var state:State;

  public function new(extensions:Dynamic) {
    this.cache = new UniformsCache();
    this.shadowCache = new ShadowUniformsCache();
    this.state = new State(extensions);
  }

  public function setup(lights:Array<Light>, useLegacyLights:Bool) {
    var r = 0;
    var g = 0;
    var b = 0;

    for (i in 0...9) {
      this.state.probe[i].set(0, 0, 0);
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

      var shadowMap = (light.shadow != null && light.shadow.map != null) ? light.shadow.map.texture : null;

      if (light.isAmbientLight) {
        r += color.r * intensity * scaleFactor;
        g += color.g * intensity * scaleFactor;
        b += color.b * intensity * scaleFactor;
      } else if (light.isLightProbe) {
        for (j in 0...9) {
          this.state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
        }

        numLightProbes++;
      } else if (light.isDirectionalLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.directionalShadow[directionalLength] = shadowUniforms;
          this.state.directionalShadowMap[directionalLength] = shadowMap;
          this.state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;

          numDirectionalShadows++;
        }

        this.state.directional[directionalLength] = uniforms;

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.cache.get(light);

        uniforms.position.setFromMatrixPosition(light.matrixWorld);

        uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
        uniforms.distance = distance;

        uniforms.coneCos = Math.cos(light.angle);
        uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
        uniforms.decay = light.decay;

        this.state.spot[spotLength] = uniforms;

        var shadow = light.shadow;

        if (light.map != null) {
          this.state.spotLightMap[numSpotMaps] = light.map;
          numSpotMaps++;

          // make sure the lightMatrix is up to date
          // TODO : do it if required only
          shadow.updateMatrices(light);

          if (light.castShadow) numSpotShadowsWithMaps++;
        }

        this.state.spotLightMatrix[spotLength] = shadow.matrix;

        if (light.castShadow) {
          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.spotShadow[spotLength] = shadowUniforms;
          this.state.spotShadowMap[spotLength] = shadowMap;

          numSpotShadows++;
        }

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(color).multiplyScalar(intensity);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        this.state.rectArea[rectAreaLength] = uniforms;

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
        uniforms.distance = light.distance;
        uniforms.decay = light.decay;

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);
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
        var uniforms = this.cache.get(light);

        uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
        uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

        this.state.hemi[hemiLength] = uniforms;

        hemiLength++;
      }
    }

    if (rectAreaLength > 0) {
      if (extensions.has('OES_texture_float_linear')) {
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

    var hash = this.state.hash;

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

  public function setupView(lights:Array<Light>, camera:Camera) {
    var directionalLength = 0;
    var pointLength = 0;
    var spotLength = 0;
    var rectAreaLength = 0;
    var hemiLength = 0;

    var viewMatrix = camera.matrixWorldInverse;

    for (i in 0...lights.length) {
      var light = lights[i];

      if (light.isDirectionalLight) {
        var uniforms = this.state.directional[directionalLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.state.spot[spotLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.state.rectArea[rectAreaLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        // extract local rotation of light to derive width/height half vectors
        var matrix42 = new Matrix3D();
        matrix42.identity();
        var matrix4 = new Matrix3D();
        matrix4.copy(light.matrixWorld);
        matrix4.premultiply(viewMatrix);
        matrix42.extractRotation(matrix4);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        uniforms.halfWidth.applyMatrix4(matrix42);
        uniforms.halfHeight.applyMatrix4(matrix42);

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.state.point[pointLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        pointLength++;
      } else if (light.isHemisphereLight) {
        var uniforms = this.state.hemi[hemiLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        uniforms.direction.transformDirection(viewMatrix);

        hemiLength++;
      }
    }
  }
}

class State {
  public var version:Int;
  public var hash:Hash;
  public var ambient:Array<Float>;
  public var probe:Array<Vector3>;
  public var directional:Array<{direction:Vector3, color:Color}>;
  public var directionalShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var directionalShadowMap:Array<Texture>;
  public var directionalShadowMatrix:Array<Matrix3D>;
  public var spot:Array<{
    position:Vector3,
    direction:Vector3,
    color:Color,
    distance:Float,
    coneCos:Float,
    penumbraCos:Float,
    decay:Float
  }>;
  public var spotLightMap:Array<Texture>;
  public var spotShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var spotShadowMap:Array<Texture>;
  public var spotLightMatrix:Array<Matrix3D>;
  public var rectArea:Array<{
    color:Color,
    position:Vector3,
    halfWidth:Vector3,
    halfHeight:Vector3
  }>;
  public var rectAreaLTC1:Dynamic;
  public var rectAreaLTC2:Dynamic;
  public var point:Array<{
    position:Vector3,
    color:Color,
    distance:Float,
    decay:Float
  }>;
  public var pointShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;
  public var pointShadowMap:Array<Texture>;
  public var pointShadowMatrix:Array<Matrix3D>;
  public var hemi:Array<{
    direction:Vector3,
    skyColor:Color,
    groundColor:Color
  }>;
  public var numSpotLightShadowsWithMaps:Int;
  public var numLightProbes:Int;

  public function new(extensions:Dynamic) {
    this.version = 0;
    this.hash = new Hash();
    this.ambient = [0, 0, 0];
    this.probe = new Array<Vector3>();
    this.directional = new Array<{direction:Vector3, color:Color}>();
    this.directionalShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.directionalShadowMap = new Array<Texture>();
    this.directionalShadowMatrix = new Array<Matrix3D>();
    this.spot = new Array<{position:Vector3, direction:Vector3, color:Color, distance:Float, coneCos:Float, penumbraCos:Float, decay:Float}>();
    this.spotLightMap = new Array<Texture>();
    this.spotShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.spotShadowMap = new Array<Texture>();
    this.spotLightMatrix = new Array<Matrix3D>();
    this.rectArea = new Array<{color:Color, position:Vector3, halfWidth:Vector3, halfHeight:Vector3}>();
    this.rectAreaLTC1 = null;
    this.rectAreaLTC2 = null;
    this.point = new Array<{position:Vector3, color:Color, distance:Float, decay:Float}>();
    this.pointShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
    this.pointShadowMap = new Array<Texture>();
    this.pointShadowMatrix = new Array<Matrix3D>();
    this.hemi = new Array<{direction:Vector3, skyColor:Color, groundColor:Color}>();
    this.numSpotLightShadowsWithMaps = 0;
    this.numLightProbes = 0;

    for (i in 0...9) {
      this.probe.push(new Vector3());
    }
  }
}

class Color {
  public var r:Float;
  public var g:Float;
  public var b:Float;

  public function new(r:Float = 0, g:Float = 0, b:Float = 0) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  public function copy(color:Color):Color {
    this.r = color.r;
    this.g = color.g;
    this.b = color.b;

    return this;
  }

  public function multiplyScalar(s:Float):Color {
    this.r *= s;
    this.g *= s;
    this.b *= s;

    return this;
  }
}

class Vector2 {
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  public function set(x:Float, y:Float):Vector2 {
    this.x = x;
    this.y = y;

    return this;
  }
}

class Vector3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function set(x:Float, y:Float, z:Float):Vector3 {
    this.x = x;
    this.y = y;
    this.z = z;

    return this;
  }

  public function addScaledVector(v:Vector3, s:Float):Vector3 {
    this.x += v.x * s;
    this.y += v.y * s;
    this.z += v.z * s;

    return this;
  }

  public function copy(v:Vector3):Vector3 {
    this.x = v.x;
    this.y = v.y;
    this.z = v.z;

    return this;
  }

  public function sub(v:Vector3):Vector3 {
    this.x -= v.x;
    this.y -= v.y;
    this.z -= v.z;

    return this;
  }

  public function transformDirection(m:Matrix3D):Vector3 {
    var x = this.x;
    var y = this.y;
    var z = this.z;

    this.x = m.n11 * x + m.n12 * y + m.n13 * z;
    this.y = m.n21 * x + m.n22 * y + m.n23 * z;
    this.z = m.n31 * x + m.n32 * y + m.n33 * z;

    return this;
  }
}

class Matrix3D {
  public var n11:Float;
  public var n12:Float;
  public var n13:Float;
  public var n14:Float;
  public var n21:Float;
  public var n22:Float;
  public var n23:Float;
  public var n24:Float;
  public var n31:Float;
  public var n32:Float;
  public var n33:Float;
  public var n34:Float;
  public var n41:Float;
  public var n42:Float;
  public var n43:Float;
  public var n44:Float;

  public function new(n11:Float = 1, n12:Float = 0, n13:Float = 0, n14:Float = 0,
                    n21:Float = 0, n22:Float = 1, n23:Float = 0, n24:Float = 0,
                    n31:Float = 0, n32:Float = 0, n33:Float = 1, n34:Float = 0,
                    n41:Float = 0, n42:Float = 0, n43:Float = 0, n44:Float = 1) {
    this.n11 = n11;
    this.n12 = n12;
    this.n13 = n13;
    this.n14 = n14;
    this.n21 = n21;
    this.n22 = n22;
    this.n23 = n23;
    this.n24 = n24;
    this.n31 = n31;
    this.n32 = n32;
    this.n33 = n33;
    this.n34 = n34;
    this.n41 = n41;
    this.n42 = n42;
    this.n43 = n43;
    this.n44 = n44;
  }

  public function identity():Matrix3D {
    this.n11 = 1;
    this.n12 = 0;
    this.n13 = 0;
    this.n14 = 0;
    this.n21 = 0;
    this.n22 = 1;
    this.n23 = 0;
    this.n24 = 0;
    this.n31 = 0;
    this.n32 = 0;
    this.n33 = 1;
    this.n34 = 0;
    this.n41 = 0;
    this.n42 = 0;
    this.n43 = 0;
    this.n44 = 1;

    return this;
  }

  public function copy(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n14 = m.n14;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n24 = m.n24;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;
    this.n34 = m.n34;
    this.n41 = m.n41;
    this.n42 = m.n42;
    this.n43 = m.n43;
    this.n44 = m.n44;

    return this;
  }

  public function premultiply(m:Matrix3D):Matrix3D {
    var n11 = this.n11;
    var n12 = this.n12;
    var n13 = this.n13;
    var n14 = this.n14;
    var n21 = this.n21;
    var n22 = this.n22;
    var n23 = this.n23;
    var n24 = this.n24;
    var n31 = this.n31;
    var n32 = this.n32;
    var n33 = this.n33;
    var n34 = this.n34;
    var n41 = this.n41;
    var n42 = this.n42;
    var n43 = this.n43;
    var n44 = this.n44;

    this.n11 = m.n11 * n11 + m.n12 * n21 + m.n13 * n31 + m.n14 * n41;
    this.n12 = m.n11 * n12 + m.n12 * n22 + m.n13 * n32 + m.n14 * n42;
    this.n13 = m.n11 * n13 + m.n12 * n23 + m.n13 * n33 + m.n14 * n43;
    this.n14 = m.n11 * n14 + m.n12 * n24 + m.n13 * n34 + m.n14 * n44;

    this.n21 = m.n21 * n11 + m.n22 * n21 + m.n23 * n31 + m.n24 * n41;
    this.n22 = m.n21 * n12 + m.n22 * n22 + m.n23 * n32 + m.n24 * n42;
    this.n23 = m.n21 * n13 + m.n22 * n23 + m.n23 * n33 + m.n24 * n43;
    this.n24 = m.n21 * n14 + m.n22 * n24 + m.n23 * n34 + m.n24 * n44;

    this.n31 = m.n31 * n11 + m.n32 * n21 + m.n33 * n31 + m.n34 * n41;
    this.n32 = m.n31 * n12 + m.n32 * n22 + m.n33 * n32 + m.n34 * n42;
    this.n33 = m.n31 * n13 + m.n32 * n23 + m.n33 * n33 + m.n34 * n43;
    this.n34 = m.n31 * n14 + m.n32 * n24 + m.n33 * n34 + m.n34 * n44;

    this.n41 = m.n41 * n11 + m.n42 * n21 + m.n43 * n31 + m.n44 * n41;
    this.n42 = m.n41 * n12 + m.n42 * n22 + m.n43 * n32 + m.n44 * n42;
    this.n43 = m.n41 * n13 + m.n42 * n23 + m.n43 * n33 + m.n44 * n43;
    this.n44 = m.n41 * n14 + m.n42 * n24 + m.n43 * n34 + m.n44 * n44;

    return this;
  }

  public function extractRotation(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;

    return this;
  }
}

class Light {
  public var id:Int;
  public var type:String;
  public var color:Color;
  public var intensity:Float;
  public var distance:Float;
  public var castShadow:Bool;
  public var map:Texture;
  public var shadow:Dynamic;
  public var isAmbientLight:Bool;
  public var isLightProbe:Bool;
  public var isDirectionalLight:Bool;
  public var isSpotLight:Bool;
  public var isRectAreaLight:Bool;
  public var isPointLight:Bool;
  public var isHemisphereLight:Bool;
  public var matrixWorld:Matrix3D;
  public var target:Dynamic;
  public var angle:Float;
  public var penumbra:Float;
  public var decay:Float;
  public var sh:Dynamic;
  public var width:Float;
  public var height:Float;

  public function new() {
    this.id = 0;
    this.type = "";
    this.color = new Color();
    this.intensity = 1;
    this.distance = 0;
    this.castShadow = false;
    this.map = null;
    this.shadow = null;
    this.isAmbientLight = false;
    this.isLightProbe = false;
    this.isDirectionalLight = false;
    this.isSpotLight = false;

import haxe.io.Bytes;
import haxe.io.Output;
import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3;
import openfl.utils.ByteArray;

class UniformsCache {
  public var lights:Map<Int, {
    direction:Vector3,
    color:Color
  }>;

  public function new() {
    this.lights = new Map<Int, {direction:Vector3, color:Color}>();
  }

  public function get(light:Light):{direction:Vector3, color:Color} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
    }

    var uniforms:Dynamic = null;

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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

class ShadowUniformsCache {
  public var lights:Map<Int, {
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;

  public function new() {
    this.lights = new Map<Int, {shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
  }

  public function get(light:Light):{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float} {
    if (this.lights.exists(light.id)) {
      return this.lights.get(light.id);
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

    this.lights.set(light.id, cast uniforms);

    return cast uniforms;
  }
}

var nextVersion = 0;

function shadowCastingAndTexturingLightsFirst(lightA:Light, lightB:Light):Int {
  return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);
}

class WebGLLights {
  public var cache:UniformsCache;
  public var shadowCache:ShadowUniformsCache;
  public var state:State;

  public function new(extensions:Dynamic) {
    this.cache = new UniformsCache();
    this.shadowCache = new ShadowUniformsCache();
    this.state = new State(extensions);
  }

  public function setup(lights:Array<Light>, useLegacyLights:Bool) {
    var r = 0;
    var g = 0;
    var b = 0;

    for (i in 0...9) {
      this.state.probe[i].set(0, 0, 0);
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

      var shadowMap = (light.shadow != null && light.shadow.map != null) ? light.shadow.map.texture : null;

      if (light.isAmbientLight) {
        r += color.r * intensity * scaleFactor;
        g += color.g * intensity * scaleFactor;
        b += color.b * intensity * scaleFactor;
      } else if (light.isLightProbe) {
        for (j in 0...9) {
          this.state.probe[j].addScaledVector(light.sh.coefficients[j], intensity);
        }

        numLightProbes++;
      } else if (light.isDirectionalLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.directionalShadow[directionalLength] = shadowUniforms;
          this.state.directionalShadowMap[directionalLength] = shadowMap;
          this.state.directionalShadowMatrix[directionalLength] = light.shadow.matrix;

          numDirectionalShadows++;
        }

        this.state.directional[directionalLength] = uniforms;

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.cache.get(light);

        uniforms.position.setFromMatrixPosition(light.matrixWorld);

        uniforms.color.copy(color).multiplyScalar(intensity * scaleFactor);
        uniforms.distance = distance;

        uniforms.coneCos = Math.cos(light.angle);
        uniforms.penumbraCos = Math.cos(light.angle * (1 - light.penumbra));
        uniforms.decay = light.decay;

        this.state.spot[spotLength] = uniforms;

        var shadow = light.shadow;

        if (light.map != null) {
          this.state.spotLightMap[numSpotMaps] = light.map;
          numSpotMaps++;

          // make sure the lightMatrix is up to date
          // TODO : do it if required only
          shadow.updateMatrices(light);

          if (light.castShadow) numSpotShadowsWithMaps++;
        }

        this.state.spotLightMatrix[spotLength] = shadow.matrix;

        if (light.castShadow) {
          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);

          this.state.spotShadow[spotLength] = shadowUniforms;
          this.state.spotShadowMap[spotLength] = shadowMap;

          numSpotShadows++;
        }

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(color).multiplyScalar(intensity);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        this.state.rectArea[rectAreaLength] = uniforms;

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.cache.get(light);

        uniforms.color.copy(light.color).multiplyScalar(light.intensity * scaleFactor);
        uniforms.distance = light.distance;
        uniforms.decay = light.decay;

        if (light.castShadow) {
          var shadow = light.shadow;

          var shadowUniforms = this.shadowCache.get(light);

          shadowUniforms.shadowBias = shadow.bias;
          shadowUniforms.shadowNormalBias = shadow.normalBias;
          shadowUniforms.shadowRadius = shadow.radius;
          shadowUniforms.shadowMapSize.set(shadow.mapSize.x, shadow.mapSize.y);
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
        var uniforms = this.cache.get(light);

        uniforms.skyColor.copy(light.color).multiplyScalar(intensity * scaleFactor);
        uniforms.groundColor.copy(light.groundColor).multiplyScalar(intensity * scaleFactor);

        this.state.hemi[hemiLength] = uniforms;

        hemiLength++;
      }
    }

    if (rectAreaLength > 0) {
      if (extensions.has('OES_texture_float_linear')) {
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

    var hash = this.state.hash;

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

  public function setupView(lights:Array<Light>, camera:Camera) {
    var directionalLength = 0;
    var pointLength = 0;
    var spotLength = 0;
    var rectAreaLength = 0;
    var hemiLength = 0;

    var viewMatrix = camera.matrixWorldInverse;

    for (i in 0...lights.length) {
      var light = lights[i];

      if (light.isDirectionalLight) {
        var uniforms = this.state.directional[directionalLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        directionalLength++;
      } else if (light.isSpotLight) {
        var uniforms = this.state.spot[spotLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        var vector3 = new Vector3();
        vector3.setFromMatrixPosition(light.target.matrixWorld);
        uniforms.direction.sub(vector3);
        uniforms.direction.transformDirection(viewMatrix);

        spotLength++;
      } else if (light.isRectAreaLight) {
        var uniforms = this.state.rectArea[rectAreaLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        // extract local rotation of light to derive width/height half vectors
        var matrix42 = new Matrix3D();
        matrix42.identity();
        var matrix4 = new Matrix3D();
        matrix4.copy(light.matrixWorld);
        matrix4.premultiply(viewMatrix);
        matrix42.extractRotation(matrix4);

        uniforms.halfWidth.set(light.width * 0.5, 0.0, 0.0);
        uniforms.halfHeight.set(0.0, light.height * 0.5, 0.0);

        uniforms.halfWidth.applyMatrix4(matrix42);
        uniforms.halfHeight.applyMatrix4(matrix42);

        rectAreaLength++;
      } else if (light.isPointLight) {
        var uniforms = this.state.point[pointLength];

        uniforms.position.setFromMatrixPosition(light.matrixWorld);
        uniforms.position.applyMatrix4(viewMatrix);

        pointLength++;
      } else if (light.isHemisphereLight) {
        var uniforms = this.state.hemi[hemiLength];

        uniforms.direction.setFromMatrixPosition(light.matrixWorld);
        uniforms.direction.transformDirection(viewMatrix);

        hemiLength++;
      }
    }
  }
}

class State {
  public var version:Int;
  public var hash:Hash;
  public var ambient:Array<Float>;
  public var probe:Array<Vector3>;
  public var directional:Array<{direction:Vector3, color:Color}>;
  public var directionalShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var directionalShadowMap:Array<Texture>;
  public var directionalShadowMatrix:Array<Matrix3D>;
  public var spot:Array<{
    position:Vector3,
    direction:Vector3,
    color:Color,
    distance:Float,
    coneCos:Float,
    penumbraCos:Float,
    decay:Float
  }>;
  public var spotLightMap:Array<Texture>;
  public var spotShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2
  }>;
  public var spotShadowMap:Array<Texture>;
  public var spotLightMatrix:Array<Matrix3D>;
  public var rectArea:Array<{
    color:Color,
    position:Vector3,
    halfWidth:Vector3,
    halfHeight:Vector3
  }>;
  public var rectAreaLTC1:Dynamic;
  public var rectAreaLTC2:Dynamic;
  public var point:Array<{
    position:Vector3,
    color:Color,
    distance:Float,
    decay:Float
  }>;
  public var pointShadow:Array<{
    shadowBias:Float,
    shadowNormalBias:Float,
    shadowRadius:Float,
    shadowMapSize:Vector2,
    shadowCameraNear:Float,
    shadowCameraFar:Float
  }>;
  public var pointShadowMap:Array<Texture>;
  public var pointShadowMatrix:Array<Matrix3D>;
  public var hemi:Array<{
    direction:Vector3,
    skyColor:Color,
    groundColor:Color
  }>;
  public var numSpotLightShadowsWithMaps:Int;
  public var numLightProbes:Int;

  public function new(extensions:Dynamic) {
    this.version = 0;
    this.hash = new Hash();
    this.ambient = [0, 0, 0];
    this.probe = new Array<Vector3>();
    this.directional = new Array<{direction:Vector3, color:Color}>();
    this.directionalShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.directionalShadowMap = new Array<Texture>();
    this.directionalShadowMatrix = new Array<Matrix3D>();
    this.spot = new Array<{position:Vector3, direction:Vector3, color:Color, distance:Float, coneCos:Float, penumbraCos:Float, decay:Float}>();
    this.spotLightMap = new Array<Texture>();
    this.spotShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2}>();
    this.spotShadowMap = new Array<Texture>();
    this.spotLightMatrix = new Array<Matrix3D>();
    this.rectArea = new Array<{color:Color, position:Vector3, halfWidth:Vector3, halfHeight:Vector3}>();
    this.rectAreaLTC1 = null;
    this.rectAreaLTC2 = null;
    this.point = new Array<{position:Vector3, color:Color, distance:Float, decay:Float}>();
    this.pointShadow = new Array<{shadowBias:Float, shadowNormalBias:Float, shadowRadius:Float, shadowMapSize:Vector2, shadowCameraNear:Float, shadowCameraFar:Float}>();
    this.pointShadowMap = new Array<Texture>();
    this.pointShadowMatrix = new Array<Matrix3D>();
    this.hemi = new Array<{direction:Vector3, skyColor:Color, groundColor:Color}>();
    this.numSpotLightShadowsWithMaps = 0;
    this.numLightProbes = 0;

    for (i in 0...9) {
      this.probe.push(new Vector3());
    }
  }
}

class Color {
  public var r:Float;
  public var g:Float;
  public var b:Float;

  public function new(r:Float = 0, g:Float = 0, b:Float = 0) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  public function copy(color:Color):Color {
    this.r = color.r;
    this.g = color.g;
    this.b = color.b;

    return this;
  }

  public function multiplyScalar(s:Float):Color {
    this.r *= s;
    this.g *= s;
    this.b *= s;

    return this;
  }
}

class Vector2 {
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  public function set(x:Float, y:Float):Vector2 {
    this.x = x;
    this.y = y;

    return this;
  }
}

class Vector3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function set(x:Float, y:Float, z:Float):Vector3 {
    this.x = x;
    this.y = y;
    this.z = z;

    return this;
  }

  public function addScaledVector(v:Vector3, s:Float):Vector3 {
    this.x += v.x * s;
    this.y += v.y * s;
    this.z += v.z * s;

    return this;
  }

  public function copy(v:Vector3):Vector3 {
    this.x = v.x;
    this.y = v.y;
    this.z = v.z;

    return this;
  }

  public function sub(v:Vector3):Vector3 {
    this.x -= v.x;
    this.y -= v.y;
    this.z -= v.z;

    return this;
  }

  public function transformDirection(m:Matrix3D):Vector3 {
    var x = this.x;
    var y = this.y;
    var z = this.z;

    this.x = m.n11 * x + m.n12 * y + m.n13 * z;
    this.y = m.n21 * x + m.n22 * y + m.n23 * z;
    this.z = m.n31 * x + m.n32 * y + m.n33 * z;

    return this;
  }
}

class Matrix3D {
  public var n11:Float;
  public var n12:Float;
  public var n13:Float;
  public var n14:Float;
  public var n21:Float;
  public var n22:Float;
  public var n23:Float;
  public var n24:Float;
  public var n31:Float;
  public var n32:Float;
  public var n33:Float;
  public var n34:Float;
  public var n41:Float;
  public var n42:Float;
  public var n43:Float;
  public var n44:Float;

  public function new(n11:Float = 1, n12:Float = 0, n13:Float = 0, n14:Float = 0,
                    n21:Float = 0, n22:Float = 1, n23:Float = 0, n24:Float = 0,
                    n31:Float = 0, n32:Float = 0, n33:Float = 1, n34:Float = 0,
                    n41:Float = 0, n42:Float = 0, n43:Float = 0, n44:Float = 1) {
    this.n11 = n11;
    this.n12 = n12;
    this.n13 = n13;
    this.n14 = n14;
    this.n21 = n21;
    this.n22 = n22;
    this.n23 = n23;
    this.n24 = n24;
    this.n31 = n31;
    this.n32 = n32;
    this.n33 = n33;
    this.n34 = n34;
    this.n41 = n41;
    this.n42 = n42;
    this.n43 = n43;
    this.n44 = n44;
  }

  public function identity():Matrix3D {
    this.n11 = 1;
    this.n12 = 0;
    this.n13 = 0;
    this.n14 = 0;
    this.n21 = 0;
    this.n22 = 1;
    this.n23 = 0;
    this.n24 = 0;
    this.n31 = 0;
    this.n32 = 0;
    this.n33 = 1;
    this.n34 = 0;
    this.n41 = 0;
    this.n42 = 0;
    this.n43 = 0;
    this.n44 = 1;

    return this;
  }

  public function copy(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n14 = m.n14;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n24 = m.n24;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;
    this.n34 = m.n34;
    this.n41 = m.n41;
    this.n42 = m.n42;
    this.n43 = m.n43;
    this.n44 = m.n44;

    return this;
  }

  public function premultiply(m:Matrix3D):Matrix3D {
    var n11 = this.n11;
    var n12 = this.n12;
    var n13 = this.n13;
    var n14 = this.n14;
    var n21 = this.n21;
    var n22 = this.n22;
    var n23 = this.n23;
    var n24 = this.n24;
    var n31 = this.n31;
    var n32 = this.n32;
    var n33 = this.n33;
    var n34 = this.n34;
    var n41 = this.n41;
    var n42 = this.n42;
    var n43 = this.n43;
    var n44 = this.n44;

    this.n11 = m.n11 * n11 + m.n12 * n21 + m.n13 * n31 + m.n14 * n41;
    this.n12 = m.n11 * n12 + m.n12 * n22 + m.n13 * n32 + m.n14 * n42;
    this.n13 = m.n11 * n13 + m.n12 * n23 + m.n13 * n33 + m.n14 * n43;
    this.n14 = m.n11 * n14 + m.n12 * n24 + m.n13 * n34 + m.n14 * n44;

    this.n21 = m.n21 * n11 + m.n22 * n21 + m.n23 * n31 + m.n24 * n41;
    this.n22 = m.n21 * n12 + m.n22 * n22 + m.n23 * n32 + m.n24 * n42;
    this.n23 = m.n21 * n13 + m.n22 * n23 + m.n23 * n33 + m.n24 * n43;
    this.n24 = m.n21 * n14 + m.n22 * n24 + m.n23 * n34 + m.n24 * n44;

    this.n31 = m.n31 * n11 + m.n32 * n21 + m.n33 * n31 + m.n34 * n41;
    this.n32 = m.n31 * n12 + m.n32 * n22 + m.n33 * n32 + m.n34 * n42;
    this.n33 = m.n31 * n13 + m.n32 * n23 + m.n33 * n33 + m.n34 * n43;
    this.n34 = m.n31 * n14 + m.n32 * n24 + m.n33 * n34 + m.n34 * n44;

    this.n41 = m.n41 * n11 + m.n42 * n21 + m.n43 * n31 + m.n44 * n41;
    this.n42 = m.n41 * n12 + m.n42 * n22 + m.n43 * n32 + m.n44 * n42;
    this.n43 = m.n41 * n13 + m.n42 * n23 + m.n43 * n33 + m.n44 * n43;
    this.n44 = m.n41 * n14 + m.n42 * n24 + m.n43 * n34 + m.n44 * n44;

    return this;
  }

  public function extractRotation(m:Matrix3D):Matrix3D {
    this.n11 = m.n11;
    this.n12 = m.n12;
    this.n13 = m.n13;
    this.n21 = m.n21;
    this.n22 = m.n22;
    this.n23 = m.n23;
    this.n31 = m.n31;
    this.n32 = m.n32;
    this.n33 = m.n33;

    return this;
  }
}

class Light {
  public var id:Int;
  public var type:String;
  public var color:Color;
  public var intensity:Float;
  public var distance:Float;
  public var castShadow:Bool;
  public var map:Texture;
  public var shadow:Dynamic;
  public var isAmbientLight:Bool;
  public var isLightProbe:Bool;
  public var isDirectionalLight:Bool;
  public var isSpotLight:Bool;
  public var isRectAreaLight:Bool;
  public var isPointLight:Bool;
  public var isHemisphereLight:Bool;
  public var matrixWorld:Matrix3D;
  public var target:Dynamic;
  public var angle:Float;
  public var penumbra:Float;
  public var decay:Float;
  public var sh:Dynamic;
  public var width:Float;
  public var height:Float;

  public function new() {
    this.id = 0;
    this.type = "";
    this.color = new Color();
    this.intensity = 1;
    this.distance = 0;
    this.castShadow = false;
    this.map = null;
    this.shadow = null;
    this.isAmbientLight = false;
    this.isLightProbe = false;
    this.isDirectionalLight = false;
    this.isSpotLight = false;