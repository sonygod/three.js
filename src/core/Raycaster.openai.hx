package three.core;

import three.math.Matrix4;
import three.math.Ray;
import three.core.Layers;

class Raycaster {
  private var _matrix:Matrix4 = new Matrix4();

  public var ray:Ray;
  public var near:Float = 0;
  public var far:Float = Math.POSITIVE_INFINITY;
  public var camera:Camera;
  public var layers:Layers;
  public var params:Dynamic = {
    Mesh: {},
    Line: { threshold: 1 },
    LOD: {},
    Points: { threshold: 1 },
    Sprite: {}
  };

  public function new(origin:Array<Float>, direction:Array<Float>, near:Float = 0, far:Float = Math.POSITIVE_INFINITY) {
    ray = new Ray(origin, direction);
    this.near = near;
    this.far = far;
    camera = null;
    layers = new Layers();
  }

  public function set(origin:Array<Float>, direction:Array<Float>):Void {
    ray.set(origin, direction);
  }

  public function setFromCamera(coords:Array<Float>, camera:Camera):Void {
    if (camera.isPerspectiveCamera) {
      ray.origin.setFromMatrixPosition(camera.matrixWorld);
      ray.direction.set(coords[0], coords[1], 0.5).unproject(camera).sub(ray.origin).normalize();
      this.camera = camera;
    } else if (camera.isOrthographicCamera) {
      ray.origin.set(coords[0], coords[1], (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
      ray.direction.set(0, 0, -1).transformDirection(camera.matrixWorld);
      this.camera = camera;
    } else {
      trace("THREE.Raycaster: Unsupported camera type: " + camera.type);
    }
  }

  public function setFromXRController(controller:Dynamic):Raycaster {
    _matrix.identity().extractRotation(controller.matrixWorld);
    ray.origin.setFromMatrixPosition(controller.matrixWorld);
    ray.direction.set(0, 0, -1).applyMatrix4(_matrix);
    return this;
  }

  public function intersectObject(object:Dynamic, recursive:Bool = true, intersects:Array<Dynamic> = []):Array<Dynamic> {
    intersect(object, this, intersects, recursive);
    intersects.sort(ascSort);
    return intersects;
  }

  public function intersectObjects(objects:Array<Dynamic>, recursive:Bool = true, intersects:Array<Dynamic> = []):Array<Dynamic> {
    for (i in 0...objects.length) {
      intersect(objects[i], this, intersects, recursive);
    }
    intersects.sort(ascSort);
    return intersects;
  }
}

private function ascSort(a:Dynamic, b:Dynamic):Int {
  return a.distance - b.distance;
}

private function intersect(object:Dynamic, raycaster:Raycaster, intersects:Array<Dynamic>, recursive:Bool):Void {
  var stopTraversal:Bool = false;
  if (object.layers.test(raycaster.layers)) {
    stopTraversal = object.raycast(raycaster, intersects);
  }
  if (recursive && !stopTraversal) {
    var children:Array<Dynamic> = object.children;
    for (i in 0...children.length) {
      intersect(children[i], raycaster, intersects, true);
    }
  }
}