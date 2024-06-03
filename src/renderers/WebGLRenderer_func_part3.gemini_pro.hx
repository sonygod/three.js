import three.WebGLAnimation;
import three.WebGLRenderer;
import three.Scene;
import three.Camera;
import three.XRManager;

class MyRenderer extends WebGLRenderer {
  var onAnimationFrameCallback:Dynamic = null;

  public function new() {
    super();
    var animation = new WebGLAnimation();
    animation.setAnimationLoop(onAnimationFrame);
    if (js.Lib.is(js.Lib.global, "self")) animation.setContext(js.Lib.global.self);
    this.setAnimationLoop = function(callback:Dynamic) {
      onAnimationFrameCallback = callback;
      xr.setAnimationLoop(callback);
      if (callback == null) animation.stop();
      else animation.start();
    };
    xr.addEventListener('sessionstart', onXRSessionStart);
    xr.addEventListener('sessionend', onXRSessionEnd);
  }

  public function render(scene:Scene, camera:Camera):Void {
    if (camera != null && !js.Lib.is(camera, Camera)) {
      js.Lib.console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
      return;
    }
    if (_isContextLost) return;
    if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
    if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
    if (xr.enabled && xr.isPresenting) {
      if (xr.cameraAutoUpdate) xr.updateCamera(camera);
      camera = xr.getCamera();
    }
    if (js.Lib.is(scene, Scene)) scene.onBeforeRender(this, scene, camera, _currentRenderTarget);
    currentRenderState = renderStates.get(scene, renderStateStack.length);
    currentRenderState.init(camera);
    renderStateStack.push(currentRenderState);
    _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
    _frustum.setFromProjectionMatrix(_projScreenMatrix);
    _localClippingEnabled = this.localClippingEnabled;
    _clippingEnabled = clipping.init(this.clippingPlanes, _localClippingEnabled);
    currentRenderList = renderLists.get(scene, renderListStack.length);
    currentRenderList.init();
    renderListStack.push(currentRenderList);
    projectObject(scene, camera, 0, this.sortObjects);
    currentRenderList.finish();
    if (this.sortObjects) {
      currentRenderList.sort(_opaqueSort, _transparentSort);
    }
    var renderBackground = !xr.enabled || !xr.isPresenting || !xr.hasDepthSensing();
    if (renderBackground) {
      background.addToRenderList(currentRenderList, scene);
    }
    this.info.render.frame++;
    if (_clippingEnabled) clipping.beginShadows();
    var shadowsArray = currentRenderState.state.shadowsArray;
    shadowMap.render(shadowsArray, scene, camera);
    if (_clippingEnabled) clipping.endShadows();
    if (this.info.autoReset) this.info.reset();
    var opaqueObjects = currentRenderList.opaque;
    var transmissiveObjects = currentRenderList.transmissive;
    currentRenderState.setupLights(_this._useLegacyLights);
    if (js.Lib.is(camera, three.ArrayCamera)) {
      var cameras = camera.cameras;
      if (transmissiveObjects.length > 0) {
        for (i in 0...cameras.length) {
          var camera2 = cameras[i];
          renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera2);
        }
      }
      if (renderBackground) background.render(scene);
      for (i in 0...cameras.length) {
        var camera2 = cameras[i];
        renderScene(currentRenderList, scene, camera2, camera2.viewport);
      }
    } else {
      if (transmissiveObjects.length > 0) renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera);
      if (renderBackground) background.render(scene);
      renderScene(currentRenderList, scene, camera);
    }
    if (_currentRenderTarget != null) {
      textures.updateMultisampleRenderTarget(_currentRenderTarget);
      textures.updateRenderTargetMipmap(_currentRenderTarget);
    }
    if (js.Lib.is(scene, Scene)) scene.onAfterRender(this, scene, camera);
    bindingStates.resetDefaultState();
    _currentMaterialId = -1;
    _currentCamera = null;
    renderStateStack.pop();
    if (renderStateStack.length > 0) {
      currentRenderState = renderStateStack[renderStateStack.length - 1];
      if (_clippingEnabled) clipping.setGlobalState(this.clippingPlanes, currentRenderState.state.camera);
    } else {
      currentRenderState = null;
    }
    renderListStack.pop();
    if (renderListStack.length > 0) {
      currentRenderList = renderListStack[renderListStack.length - 1];
    } else {
      currentRenderList = null;
    }
  }

  function onAnimationFrame(time:Float):Void {
    if (onAnimationFrameCallback != null) onAnimationFrameCallback(time);
  }

  function onXRSessionStart():Void {
    animation.stop();
  }

  function onXRSessionEnd():Void {
    animation.start();
  }

  function projectObject(object:Dynamic, camera:Camera, groupOrder:Int, sortObjects:Bool):Void {
    if (!object.visible) return;
    var visible = object.layers.test(camera.layers);
    if (visible) {
      if (js.Lib.is(object, three.Group)) {
        groupOrder = object.renderOrder;
      } else if (js.Lib.is(object, three.LOD)) {
        if (object.autoUpdate) object.update(camera);
      } else if (js.Lib.is(object, three.Light)) {
        currentRenderState.pushLight(object);
        if (object.castShadow) {
          currentRenderState.pushShadow(object);
        }
      } else if (js.Lib.is(object, three.Sprite)) {
        if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
          if (sortObjects) {
            _vector3.setFromMatrixPosition(object.matrixWorld).applyMatrix4(_projScreenMatrix);
          }
          var geometry = objects.update(object);
          var material = object.material;
          if (material.visible) {
            currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
          }
        }
      } else if (js.Lib.is(object, three.Mesh) || js.Lib.is(object, three.Line) || js.Lib.is(object, three.Points)) {
        if (!object.frustumCulled || _frustum.intersectsObject(object)) {
          var geometry = objects.update(object);
          var material = object.material;
          if (sortObjects) {
            if (object.boundingSphere != null) {
              if (object.boundingSphere == null) object.computeBoundingSphere();
              _vector3.copy(object.boundingSphere.center);
            } else {
              if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
              _vector3.copy(geometry.boundingSphere.center);
            }
            _vector3.applyMatrix4(object.matrixWorld).applyMatrix4(_projScreenMatrix);
          }
          if (js.Lib.is(material, Array)) {
            var groups = geometry.groups;
            for (i in 0...groups.length) {
              var group = groups[i];
              var groupMaterial = material[group.materialIndex];
              if (groupMaterial != null && groupMaterial.visible) {
                currentRenderList.push(object, geometry, groupMaterial, groupOrder, _vector3.z, group);
              }
            }
          } else if (material.visible) {
            currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
          }
        }
      }
    }
    var children = object.children;
    for (i in 0...children.length) {
      projectObject(children[i], camera, groupOrder, sortObjects);
    }
  }

  function renderScene(currentRenderList:Dynamic, scene:Scene, camera:Camera, viewport:Dynamic):Void {
    var opaqueObjects = currentRenderList.opaque;
    var transmissiveObjects = currentRenderList.transmissive;
    var transparentObjects = currentRenderList.transparent;
    currentRenderState.setupLightsView(camera);
    if (_clippingEnabled) clipping.setGlobalState(this.clippingPlanes, camera);
    if (viewport != null) state.viewport(_currentViewport.copy(viewport));
    if (opaqueObjects.length > 0) renderObjects(opaqueObjects, scene, camera);
    if (transmissiveObjects.length > 0) renderObjects(transmissiveObjects, scene, camera);
    if (transparentObjects.length > 0) renderObjects(transparentObjects, scene, camera);
    state.buffers.depth.setTest(true);
    state.buffers.depth.setMask(true);
    state.buffers.color.setMask(true);
    state.setPolygonOffset(false);
  }

  function renderTransmissionPass(opaqueObjects:Dynamic, transmissiveObjects:Dynamic, scene:Scene, camera:Camera):Void {
    var overrideMaterial = js.Lib.is(scene, Scene) ? scene.overrideMaterial : null;
    if (overrideMaterial != null) {
      return;
    }
    if (currentRenderState.state.transmissionRenderTarget[camera.id] == null) {
      currentRenderState.state.transmissionRenderTarget[camera.id] = new three.WebGLRenderTarget(1, 1, {
        generateMipmaps: true,
        type: (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float')) ? three.HalfFloatType : three.UnsignedByteType,
        minFilter: three.LinearMipmapLinearFilter,
        samples: 4,
        stencilBuffer: stencil,
        resolveDepthBuffer: false,
        resolveStencilBuffer: false
      });
      /*
      var geometry = new three.PlaneGeometry();
      var material = new three.MeshBasicMaterial({map: _transmissionRenderTarget.texture});
      var mesh = new three.Mesh(geometry, material);
      scene.add(mesh);
      */
    }
    var transmissionRenderTarget = currentRenderState.state.transmissionRenderTarget[camera.id];
    var activeViewport = camera.viewport != null ? camera.viewport : _currentViewport;
    transmissionRenderTarget.setSize(activeViewport.z, activeViewport.w);
    var currentRenderTarget = this.getRenderTarget();
    this.setRenderTarget(transmissionRenderTarget);
    this.getClearColor(_currentClearColor);
    _currentClearAlpha = this.getClearAlpha();
    if (_currentClearAlpha < 1) this.setClearColor(0xffffff, 0.5);
    this.clear();
    var currentToneMapping = this.toneMapping;
    this.toneMapping = three.NoToneMapping;
    var currentCameraViewport = camera.viewport;
    if (camera.viewport != null) camera.viewport = null;
    currentRenderState.setupLightsView(camera);
    if (_clippingEnabled) clipping.setGlobalState(this.clippingPlanes, camera);
    renderObjects(opaqueObjects, scene, camera);
    textures.updateMultisampleRenderTarget(transmissionRenderTarget);
    textures.updateRenderTargetMipmap(transmissionRenderTarget);
    if (!extensions.has('WEBGL_multisampled_render_to_texture')) {
      var renderTargetNeedsUpdate = false;
      for (i in 0...transmissiveObjects.length) {
        var renderItem = transmissiveObjects[i];
        var object = renderItem.object;
        var geometry = renderItem.geometry;
        var material = overrideMaterial == null ? renderItem.material : overrideMaterial;
        var group = renderItem.group;
        if (material.side == three.DoubleSide && object.layers.test(camera.layers)) {
          var currentSide = material.side;
          material.side = three.BackSide;
          material.needsUpdate = true;
          renderObject(object, scene, camera, geometry, material, group);
          material.side = currentSide;
          material.needsUpdate = true;
          renderTargetNeedsUpdate = true;
        }
      }
      if (renderTargetNeedsUpdate) {
        textures.updateMultisampleRenderTarget(transmissionRenderTarget);
        textures.updateRenderTargetMipmap(transmissionRenderTarget);
      }
    }
    this.setRenderTarget(currentRenderTarget);
    this.setClearColor(_currentClearColor, _currentClearAlpha);
    if (currentCameraViewport != null) camera.viewport = currentCameraViewport;
    this.toneMapping = currentToneMapping;
  }

  function renderObjects(renderList:Dynamic, scene:Scene, camera:Camera):Void {
    var overrideMaterial = js.Lib.is(scene, Scene) ? scene.overrideMaterial : null;
    for (i in 0...renderList.length) {
      var renderItem = renderList[i];
      var object = renderItem.object;
      var geometry = renderItem.geometry;
      var material = overrideMaterial == null ? renderItem.material : overrideMaterial;
      var group = renderItem.group;
      if (object.layers.test(camera.layers)) {
        renderObject(object, scene, camera, geometry, material, group);
      }
    }
  }

  private var animation:WebGLAnimation;
  private var xr:XRManager = new XRManager();
  private var _projScreenMatrix:three.Matrix4 = new three.Matrix4();
  private var _frustum:three.Frustum = new three.Frustum();
  private var _vector3:three.Vector3 = new three.Vector3();
  private var _currentViewport:three.Vector4 = new three.Vector4();
  private var _currentClearColor:three.Color = new three.Color();
  private var _currentClearAlpha:Float = 1.;
  private var _localClippingEnabled:Bool = false;
  private var _clippingEnabled:Bool = false;
  private var _currentMaterialId:Int = -1;
  private var _currentCamera:Camera = null;
  private var _isContextLost:Bool = false;
  private var _useLegacyLights:Bool = false;
  private var currentRenderState:Dynamic = null;
  private var currentRenderList:Dynamic = null;
  private var renderStateStack:Array<Dynamic> = [];
  private var renderListStack:Array<Dynamic> = [];
  private var _opaqueSort:Dynamic = null;
  private var _transparentSort:Dynamic = null;
}