package three.js.src.renderers.webgl;

import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.WebGLBuffer;
import haxe.ds.WeakMap;

class WebGLObjects {
  private var gl:WebGLRenderingContext;
  private var geometries:Geometries;
  private var attributes:Attributes;
  private var info:RenderInfo;
  private var updateMap:WeakMap<Dynamic, Int>;

  public function new(gl:WebGLRenderingContext, geometries:Geometries, attributes:Attributes, info:RenderInfo) {
    this.gl = gl;
    this.geometries = geometries;
    this.attributes = attributes;
    this.info = info;
    this.updateMap = new WeakMap();
  }

  private function update(object:Object3D):WebGLGeometry {
    var frame:Int = info.render.frame;
    var geometry:Geometry = object.geometry;
    var bufferGeometry:WebGLGeometry = geometries.get(object, geometry);

    // Update once per frame
    if (!updateMap.exists(bufferGeometry) || updateMap.get(bufferGeometry) != frame) {
      geometries.update(bufferGeometry);
      updateMap.set(bufferGeometry, frame);
    }

    if (object.isInstancedMesh) {
      if (!object.hasEventListener('dispose', onInstancedMeshDispose)) {
        object.addEventListener('dispose', onInstancedMeshDispose);
      }

      if (!updateMap.exists(object) || updateMap.get(object) != frame) {
        attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);
        if (object.instanceColor != null) {
          attributes.update(object.instanceColor, gl.ARRAY_BUFFER);
        }
        updateMap.set(object, frame);
      }
    }

    if (object.isSkinnedMesh) {
      var skeleton:Skeleton = object.skeleton;
      if (!updateMap.exists(skeleton) || updateMap.get(skeleton) != frame) {
        skeleton.update();
        updateMap.set(skeleton, frame);
      }
    }

    return bufferGeometry;
  }

  private function dispose():Void {
    updateMap = new WeakMap();
  }

  private function onInstancedMeshDispose(event:Event):Void {
    var instancedMesh:Object3D = cast event.target;
    instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);
    attributes.remove(instancedMesh.instanceMatrix);
    if (instancedMesh.instanceColor != null) {
      attributes.remove(instancedMesh.instanceColor);
    }
  }

  public function getAPI():{ update:WebGLObject->Void, dispose:Void->Void } {
    return {
      update: update,
      dispose: dispose
    };
  }
}

extern class Geometries {
  public function get(object:Object3D, geometry:Geometry):WebGLGeometry;
  public function update(bufferGeometry:WebGLGeometry):Void;
}

extern class Attributes {
  public function update(data:Array<Float>, bufferType:Int):Void;
  public function remove(data:Array<Float>):Void;
}

extern class RenderInfo {
  public var render:Render;
}

extern class Render {
  public var frame:Int;
}

extern class Object3D {
  public var geometry:Geometry;
  public var isInstancedMesh:Bool;
  public var instanceMatrix:Array<Float>;
  public var instanceColor:Array<Float>;
  public var skeleton:Skeleton;
  public var isSkinnedMesh:Bool;
  public function hasEventListener(type:String, listener:Dynamic->Void):Bool;
  public function addEventListener(type:String, listener:Dynamic->Void):Void;
  public function removeEventListener(type:String, listener:Dynamic->Void):Void;
}

extern class Skeleton {
  public function update():Void;
}

extern class Geometry {
  // assuming this class has no fields or methods
}

extern class WebGLGeometry extends Geometry {
  // assuming this class has no fields or methods
}