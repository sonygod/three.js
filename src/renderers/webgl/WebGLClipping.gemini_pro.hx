import haxe.io.Bytes;
import math.Matrix3;
import math.Plane;

class WebGLClipping {
  
  private var globalState:Bytes = null;
  private var numGlobalPlanes:Int = 0;
  private var localClippingEnabled:Bool = false;
  private var renderingShadows:Bool = false;
  
  private var plane:Plane = new Plane();
  private var viewNormalMatrix:Matrix3 = new Matrix3();
  
  public var uniform: { value:Bytes, needsUpdate:Bool };
  public var numPlanes:Int = 0;
  public var numIntersection:Int = 0;
  
  public function new() {
    uniform = { value: null, needsUpdate: false };
  }
  
  public function init(planes:Array<Plane>, enableLocalClipping:Bool):Bool {
    
    var enabled = planes.length != 0 || enableLocalClipping || numGlobalPlanes != 0 || localClippingEnabled;
    
    localClippingEnabled = enableLocalClipping;
    numGlobalPlanes = planes.length;
    
    return enabled;
  }
  
  public function beginShadows() {
    
    renderingShadows = true;
    projectPlanes(null);
  }
  
  public function endShadows() {
    renderingShadows = false;
  }
  
  public function setGlobalState(planes:Array<Plane>, camera:Dynamic) {
    globalState = projectPlanes(planes, camera, 0);
  }
  
  public function setState(material:Dynamic, camera:Dynamic, useCache:Bool) {
    
    var planes = material.clippingPlanes;
    var clipIntersection = material.clipIntersection;
    var clipShadows = material.clipShadows;
    
    if (!localClippingEnabled || planes == null || planes.length == 0 || renderingShadows && !clipShadows) {
      
      if (renderingShadows) {
        projectPlanes(null);
      } else {
        resetGlobalState();
      }
      
    } else {
      
      var nGlobal = renderingShadows ? 0 : numGlobalPlanes;
      var lGlobal = nGlobal * 4;
      
      var dstArray = material.clippingState;
      
      uniform.value = dstArray;
      
      dstArray = projectPlanes(planes, camera, lGlobal, useCache);
      
      for (i in 0...lGlobal) {
        dstArray[i] = globalState[i];
      }
      
      material.clippingState = dstArray;
      numIntersection = clipIntersection ? numPlanes : 0;
      numPlanes += nGlobal;
      
    }
    
  }
  
  private function resetGlobalState() {
    
    if (uniform.value != globalState) {
      uniform.value = globalState;
      uniform.needsUpdate = numGlobalPlanes > 0;
    }
    
    numPlanes = numGlobalPlanes;
    numIntersection = 0;
  }
  
  private function projectPlanes(planes:Array<Plane>, camera:Dynamic, dstOffset:Int, skipTransform:Bool = false):Bytes {
    
    var nPlanes = planes != null ? planes.length : 0;
    var dstArray:Bytes = null;
    
    if (nPlanes != 0) {
      
      dstArray = uniform.value;
      
      if (skipTransform != true || dstArray == null) {
        
        var flatSize = dstOffset + nPlanes * 4;
        var viewMatrix = camera.matrixWorldInverse;
        
        viewNormalMatrix.getNormalMatrix(viewMatrix);
        
        if (dstArray == null || dstArray.length < flatSize) {
          dstArray = Bytes.alloc(flatSize * 4);
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
    
    numPlanes = nPlanes;
    numIntersection = 0;
    
    return dstArray;
  }
  
}