package three.js.src.renderers;

import three.js.src.renderers.WebGLRenderer;

class WebGLRenderer_func_part2 {
  // ...

  private function clear Color(r:Float, g:Float, b:Float, a:Float):Void {
    if (isUnsignedType) {
      uintClearColor[0] = r;
      uintClearColor[1] = g;
      uintClearColor[2] = b;
      uintClearColor[3] = a;
      _gl.clearBufferuiv(_gl.COLOR, 0, uintClearColor);
    } else {
      intClearColor[0] = r;
      intClearColor[1] = g;
      intClearColor[2] = b;
      intClearColor[3] = a;
      _gl.clearBufferiv(_gl.COLOR, 0, intClearColor);
    }
  }

  public function clearColor():Void {
    clear(true, false, false);
  }

  public function clearDepth():Void {
    clear(false, true, false);
  }

  public function clearStencil():Void {
    clear(false, false, true);
  }

  public function dispose():Void {
    canvas.removeEventListener('webglcontextlost', onContextLost, false);
    canvas.removeEventListener('webglcontextrestored', onContextRestore, false);
    canvas.removeEventListener('webglcontextcreationerror', onContextCreationError, false);

    renderLists.dispose();
    renderStates.dispose();
    properties.dispose();
    cubemaps.dispose();
    cubeuvmaps.dispose();
    objects.dispose();
    bindingStates.dispose();
    uniformsGroups.dispose();
    programCache.dispose();

    xr.dispose();

    xr.removeEventListener('sessionstart', onXRSessionStart);
    xr.removeEventListener('sessionend', onXRSessionEnd);

    animation.stop();
  }

  // ...

  private function onContextLost(event:Dynamic):Void {
    event.preventDefault();
    console.log('THREE.WebGLRenderer: Context Lost.');
    _isContextLost = true;
  }

  private function onContextRestore(/*event:Dynamic*/):Void {
    console.log('THREE.WebGLRenderer: Context Restored.');
    _isContextLost = false;

    var infoAutoReset = info.autoReset;
    var shadowMapEnabled = shadowMap.enabled;
    var shadowMapAutoUpdate = shadowMap.autoUpdate;
    var shadowMapNeedsUpdate = shadowMap.needsUpdate;
    var shadowMapType = shadowMap.type;

    initGLContext();

    info.autoReset = infoAutoReset;
    shadowMap.enabled = shadowMapEnabled;
    shadowMap.autoUpdate = shadowMapAutoUpdate;
    shadowMap.needsUpdate = shadowMapNeedsUpdate;
    shadowMap.type = shadowMapType;
  }

  private function onContextCreationError(event:Dynamic):Void {
    console.error('THREE.WebGLRenderer: A WebGL context could not be created. Reason: ', event.statusMessage);
  }

  private function onMaterialDispose(event:MaterialEvent):Void {
    var material:Material = event.target;

    material.removeEventListener('dispose', onMaterialDispose);

    deallocateMaterial(material);
  }

  private function deallocateMaterial(material:Material):Void {
    releaseMaterialProgramReferences(material);
    properties.remove(material);
  }

  private function releaseMaterialProgramReferences(material:Material):Void {
    var programs:Array<Program> = properties.get(material).programs;

    if (programs != null) {
      for (program in programs) {
        programCache.releaseProgram(program);
      }

      if (material.isShaderMaterial) {
        programCache.releaseShaderCache(material);
      }
    }
  }

  public function renderBufferDirect(camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object3D, group:Object3D):Void {
    // ...
  }

  // ...
}