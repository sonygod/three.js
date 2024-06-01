import  haxe.io.Bytes;
import  haxe.ui.backend.AbstractRenderer;

import  math.Matrix3;
import  math.Plane;

class WebGLClipping {
  var globalState:Bytes;
  var numGlobalPlanes:Int;
  var localClippingEnabled:Bool;
  var renderingShadows:Bool;
  var plane:Plane;
  var viewNormalMatrix:Matrix3;
  var uniform:AbstractRenderer.Uniform;
  var numPlanes:Int;
  var numIntersection:Int;

  public function new(properties:Dynamic) {
    globalState = null;
    numGlobalPlanes = 0;
    localClippingEnabled = false;
    renderingShadows = false;
    plane = new Plane();
    viewNormalMatrix = new Matrix3();
    uniform = { value: null, needsUpdate: false };
    this.uniform = uniform;
    numPlanes = 0;
    numIntersection = 0;
  }

  public function init(planes:Array<Plane>, enableLocalClipping:Bool):Bool {
    var enabled = planes.length != 0 || enableLocalClipping || numGlobalPlanes != 0 || localClippingEnabled;
    localClippingEnabled = enableLocalClipping;
    numGlobalPlanes = planes.length;
    return enabled;
  }

  public function beginShadows():Void {
    renderingShadows = true;
    projectPlanes(null);
  }

  public function endShadows():Void {
    renderingShadows = false;
  }

  public function setGlobalState(planes:Array<Plane>, camera:Dynamic):Void {
    globalState = projectPlanes(planes, camera, 0);
  }

  public function setState(material:Dynamic, camera:Dynamic, useCache:Bool):Void {
    var planes = material.clippingPlanes;
    var clipIntersection = material.clipIntersection;
    var clipShadows = material.clipShadows;
    var materialProperties = properties.get(material);

    if (!localClippingEnabled || planes == null || planes.length == 0 || renderingShadows && !clipShadows) {
      if (renderingShadows) {
        projectPlanes(null);
      } else {
        resetGlobalState();
      }
    } else {
      var nGlobal = renderingShadows ? 0 : numGlobalPlanes;
      var lGlobal = nGlobal * 4;
      var dstArray = cast materialProperties.clippingState;
      uniform.value = dstArray;
      dstArray = projectPlanes(planes, camera, lGlobal, useCache);

      for (i in 0...lGlobal) {
        dstArray[i] = globalState[i];
      }
      materialProperties.clippingState = dstArray;
      this.numIntersection = clipIntersection ? this.numPlanes : 0;
      this.numPlanes += nGlobal;
    }
  }

  function resetGlobalState():Void {
    if (uniform.value != globalState) {
      uniform.value = globalState;
      uniform.needsUpdate = numGlobalPlanes > 0;
    }

    this.numPlanes = numGlobalPlanes;
    this.numIntersection = 0;
  }

  function projectPlanes(planes:Array<Plane>, camera:Dynamic, dstOffset:Int, skipTransform:Bool = false):Bytes {
    var nPlanes = planes != null ? planes.length : 0;
    var dstArray = null;

    if (nPlanes != 0) {
      dstArray = cast uniform.value;

      if (skipTransform != true || dstArray == null) {
        var flatSize = dstOffset + nPlanes * 4;
        var viewMatrix = camera.matrixWorldInverse;
        viewNormalMatrix.getNormalMatrix(viewMatrix);
        if (dstArray == null || dstArray.length < flatSize) {
          dstArray = new Bytes(flatSize * 4);
        }

        for (i in 0...nPlanes) {
          plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
          plane.normal.toArray(dstArray, i * 4);
          dstArray.set(i * 4 + 3, plane.constant);
        }
      }

      uniform.value = dstArray;
      uniform.needsUpdate = true;
    }

    this.numPlanes = nPlanes;
    this.numIntersection = 0;

    return dstArray;
  }
}