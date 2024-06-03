import three.math.Matrix4;
import three.math.Ray;
import three.core.Layers;

class Raycaster {
  public var ray:Ray;
  public var near:Float;
  public var far:Float;
  public var camera:Dynamic;
  public var layers:Layers;

  public var params:Dynamic;

  public function new(origin:Dynamic, direction:Dynamic, near:Float = 0, far:Float = Math.POSITIVE_INFINITY) {
    this.ray = new Ray(origin, direction);
    // direction is assumed to be normalized (for accurate distance calculations)

    this.near = near;
    this.far = far;
    this.camera = null;
    this.layers = new Layers();

    this.params = {
      Mesh: {},
      Line: { threshold: 1 },
      LOD: {},
      Points: { threshold: 1 },
      Sprite: {}
    };
  }

  public function set(origin:Dynamic, direction:Dynamic):Void {
    // direction is assumed to be normalized (for accurate distance calculations)

    this.ray.set(origin, direction);
  }

  public function setFromCamera(coords:Dynamic, camera:Dynamic):Void {
    if (cast camera.isPerspectiveCamera) {
      this.ray.origin.setFromMatrixPosition(camera.matrixWorld);
      this.ray.direction.set(coords.x, coords.y, 0.5).unproject(camera).sub(this.ray.origin).normalize();
      this.camera = camera;
    } else if (cast camera.isOrthographicCamera) {
      this.ray.origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera); // set origin in plane of camera
      this.ray.direction.set(0, 0, -1).transformDirection(camera.matrixWorld);
      this.camera = camera;
    } else {
      console.error('THREE.Raycaster: Unsupported camera type: ' + camera.type);
    }
  }

  public function setFromXRController(controller:Dynamic):Raycaster {
    var _matrix = new Matrix4().identity().extractRotation(controller.matrixWorld);

    this.ray.origin.setFromMatrixPosition(controller.matrixWorld);
    this.ray.direction.set(0, 0, -1).applyMatrix4(_matrix);

    return this;
  }

  public function intersectObject(object:Dynamic, recursive:Bool = true, intersects:Array<Dynamic> = []) {
    intersect(object, this, intersects, recursive);

    intersects.sort(ascSort);

    return intersects;
  }

  public function intersectObjects(objects:Array<Dynamic>, recursive:Bool = true, intersects:Array<Dynamic> = []) {
    for (i in 0...objects.length) {
      intersect(objects[i], this, intersects, recursive);
    }

    intersects.sort(ascSort);

    return intersects;
  }
}

function ascSort(a:Dynamic, b:Dynamic):Int {
  return cast a.distance - b.distance;
}

function intersect(object:Dynamic, raycaster:Raycaster, intersects:Array<Dynamic>, recursive:Bool) {
  var stopTraversal:Bool = false;

  if (object.layers.test(raycaster.layers)) {
    stopTraversal = cast object.raycast(raycaster, intersects);
  }

  if (recursive && !stopTraversal) {
    var children = cast object.children;

    for (i in 0...children.length) {
      intersect(children[i], raycaster, intersects, true);
    }
  }
}