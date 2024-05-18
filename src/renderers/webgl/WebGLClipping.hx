package three.src.renderers.webgl;

import three.math.Matrix3;
import three.math.Plane;

class WebGLClipping {
  private var globalState:Null<Float32Array>;
  private var numGlobalPlanes:Int = 0;
  private var localClippingEnabled:Bool = false;
  private var renderingShadows:Bool = false;

  private var plane:Plane = new Plane();
  private var viewNormalMatrix:Matrix3 = new Matrix3();

  public var uniform:{ value:Null<Float32Array>, needsUpdate:Bool } = { value: null, needsUpdate: false };
  public var numPlanes:Int = 0;
  public var numIntersection:Int = 0;

  public function new(properties:Dynamic) {}

  public function init(planes:Array<Plane>, enableLocalClipping:Bool):Bool {
    var enabled:Bool = planes.length != 0 || enableLocalClipping || numGlobalPlanes != 0 || localClippingEnabled;
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
    var planes:Array<Plane> = material.clippingPlanes;
    var clipIntersection:Bool = material.clipIntersection;
    var clipShadows:Bool = material.clipShadows;

    var materialProperties:Dynamic = properties.get(material);

    if (!localClippingEnabled || planes == null || planes.length == 0 || renderingShadows && !clipShadows) {
      if (renderingShadows) {
        projectPlanes(null);
      } else {
        resetGlobalState();
      }
    } else {
      var nGlobal:Int = renderingShadows ? 0 : numGlobalPlanes;
      var lGlobal:Int = nGlobal * 4;

      var dstArray:Float32Array = materialProperties.clippingState || null;

      uniform.value = dstArray; // ensure unique state

      dstArray = projectPlanes(planes, camera, lGlobal, useCache);

      for (i in 0...lGlobal) {
        dstArray[i] = globalState[i];
      }

      materialProperties.clippingState = dstArray;
      numIntersection = clipIntersection ? numPlanes : 0;
      numPlanes += nGlobal;
    }
  }

  private function resetGlobalState():Void {
    if (uniform.value != globalState) {
      uniform.value = globalState;
      uniform.needsUpdate = numGlobalPlanes > 0;
    }

    numPlanes = numGlobalPlanes;
    numIntersection = 0;
  }

  private function projectPlanes(planes:Array<Plane>, camera:Dynamic, dstOffset:Int, skipTransform:Bool = false):Float32Array {
    var nPlanes:Int = planes != null ? planes.length : 0;
    var dstArray:Float32Array = null;

    if (nPlanes != 0) {
      dstArray = uniform.value;

      if (skipTransform != true || dstArray == null) {
        var flatSize:Int = dstOffset + nPlanes * 4;
        var viewMatrix:Matrix4 = camera.matrixWorldInverse;

        viewNormalMatrix.getNormalMatrix(viewMatrix);

        if (dstArray == null || dstArray.length < flatSize) {
          dstArray = new Float32Array(flatSize);
        }

        for (i in 0...nPlanes) {
          plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
          plane.normal.toArray(dstArray, i * 4);
          dstArray[i * 4 + 3] = plane.constant;
        }
      }

      uniform.value = dstArray;
      uniform.needsUpdate = true;
    }

    numPlanes = nPlanes;
    numIntersection = 0;

    return dstArray;
  }
}