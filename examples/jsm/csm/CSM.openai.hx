package three.js.examples.csm;

import three.Vector2;
import three.Vector3;
import three.DirectionalLight;
import three.MathUtils;
import three.ShaderChunk;
import three.Matrix4;
import three.Box3;

class CSM {
  public var camera:three.Camera;
  public var parent:three.Object3D;
  public var cascades:Int;
  public var maxFar:Float;
  public var mode:String;
  public var shadowMapSize:Int;
  public var shadowBias:Float;
  public var lightDirection:Vector3;
  public var lightIntensity:Float;
  public var lightNear:Float;
  public var lightFar:Float;
  public var lightMargin:Float;
  public var customSplitsCallback:Void->Void;
  public var fade:Bool;
  public var mainFrustum:CSMFustrum;
  public var frustums:Array<CSMFustrum>;
  public var breaks:Array<Float>;
  public var lights:Array<three.DirectionalLight>;
  public var shaders:Map<three.Material, three.Shader>;

  private var _cameraToLightMatrix:Matrix4;
  private var _lightSpaceFrustum:CSMFustrum;
  private var _center:Vector3;
  private var _bbox:Box3;
  private var _uniformArray:Array<Float>;
  private var _logArray:Array<Float>;
  private var _lightOrientationMatrix:Matrix4;
  private var _lightOrientationMatrixInverse:Matrix4;
  private var _up:Vector3;

  public function new(data:Dynamic) {
    camera = data.camera;
    parent = data.parent;
    cascades = data.cascades != null ? data.cascades : 3;
    maxFar = data.maxFar != null ? data.maxFar : 100000;
    mode = data.mode != null ? data.mode : 'practical';
    shadowMapSize = data.shadowMapSize != null ? data.shadowMapSize : 2048;
    shadowBias = data.shadowBias != null ? data.shadowBias : 0.000001;
    lightDirection = data.lightDirection != null ? data.lightDirection : new Vector3(1, -1, 1).normalize();
    lightIntensity = data.lightIntensity != null ? data.lightIntensity : 3;
    lightNear = data.lightNear != null ? data.lightNear : 1;
    lightFar = data.lightFar != null ? data.lightFar : 2000;
    lightMargin = data.lightMargin != null ? data.lightMargin : 200;
    customSplitsCallback = data.customSplitsCallback;
    fade = false;
    mainFrustum = new CSMFrustum();
    frustums = [];
    breaks = [];
    lights = [];
    shaders = new Map<three.Material, three.Shader>();

    createLights();
    updateFrustums();
    injectInclude();
  }

  private function createLights() {
    for (i in 0...cascades) {
      var light:DirectionalLight = new DirectionalLight(0xffffff, lightIntensity);
      light.castShadow = true;
      light.shadow.mapSize.width = shadowMapSize;
      light.shadow.mapSize.height = shadowMapSize;
      light.shadow.camera.near = lightNear;
      light.shadow.camera.far = lightFar;
      light.shadow.bias = shadowBias;
      parent.add(light);
      parent.add(light.target);
      lights.push(light);
    }
  }

  public function initCascades() {
    var camera:three.Camera = this.camera;
    camera.updateProjectionMatrix();
    mainFrustum.setFromProjectionMatrix(camera.projectionMatrix, maxFar);
    mainFrustum.split(breaks, frustums);
  }

  public function updateShadowBounds() {
    for (frustum in frustums) {
      var light:DirectionalLight = lights[frustum.index];
      var shadowCam:three.OrthographicCamera = light.shadow.camera;
      // ...
    }
  }

  public function getBreaks() {
    var camera:three.Camera = this.camera;
    var far:Float = Math.min(camera.far, maxFar);
    breaks.length = 0;
    switch (mode) {
      case 'uniform':
        uniformSplit(cascades, camera.near, far, breaks);
        break;
      case 'logarithmic':
        logarithmicSplit(cascades, camera.near, far, breaks);
        break;
      case 'practical':
        practicalSplit(cascades, camera.near, far, 0.5, breaks);
        break;
      case 'custom':
        if (customSplitsCallback == null) {
          throw new Error("CSM: Custom split scheme callback not defined.");
        }
        customSplitsCallback(cascades, camera.near, far, breaks);
        break;
    }
  }

  public function update() {
    var camera:three.Camera = this.camera;
    // ...
  }

  public function injectInclude() {
    ShaderChunk.lights_fragment_begin = CSMShader.lights_fragment_begin;
    ShaderChunk.lights_pars_begin = CSMShader.lights_pars_begin;
  }

  public function setupMaterial(material:three.Material) {
    material.defines.USE_CSM = 1;
    material.defines.CSM_CASCADES = cascades;
    if (fade) {
      material.defines.CSM_FADE = '';
    }
    material.onBeforeCompile = function(shader:three.Shader) {
      var far:Float = Math.min(camera.far, maxFar);
      getExtendedBreaks(breaksVec2);
      shader.uniforms.CSM_cascades.value = breaksVec2;
      shader.uniforms.cameraNear.value = camera.near;
      shader.uniforms.shadowFar.value = far;
    };
  }

  public function updateUniforms() {
    var far:Float = Math.min(camera.far, maxFar);
    for (shader in shaders) {
      shader.uniforms.CSM_cascades.value = breaksVec2;
      shader.uniforms.cameraNear.value = camera.near;
      shader.uniforms.shadowFar.value = far;
    }
  }

  public function getExtendedBreaks(target:Array<Vector2>) {
    while (target.length < breaks.length) {
      target.push(new Vector2());
    }
    target.length = breaks.length;
    for (i in 0...cascades) {
      var amount = breaks[i];
      var prev = breaks[i - 1] || 0;
      target[i].x = prev;
      target[i].y = amount;
    }
  }

  public function updateFrustums() {
    getBreaks();
    initCascades();
    updateShadowBounds();
    updateUniforms();
  }

  public function remove() {
    for (light in lights) {
      parent.remove(light.target);
      parent.remove(light);
    }
  }

  public function dispose() {
    for (shader in shaders) {
      shader.uniforms.CSM_cascades = null;
      shader.uniforms.cameraNear = null;
      shader.uniforms.shadowFar = null;
    }
    shaders.clear();
  }
}