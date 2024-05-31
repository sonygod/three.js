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

    private static var _matrix:Matrix4 = new Matrix4();

    public function new(origin:Dynamic, direction:Dynamic, ?near:Float = 0, ?far:Float = Math.POSITIVE_INFINITY) {
        this.ray = new Ray(origin, direction);
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
        this.ray.set(origin, direction);
    }

    public function setFromCamera(coords:Dynamic, camera:Dynamic):Void {
        if (camera.isPerspectiveCamera) {
            this.ray.origin.setFromMatrixPosition(camera.matrixWorld);
            this.ray.direction.set(coords.x, coords.y, 0.5).unproject(camera).sub(this.ray.origin).normalize();
            this.camera = camera;
        } else if (camera.isOrthographicCamera) {
            this.ray.origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
            this.ray.direction.set(0, 0, -1).transformDirection(camera.matrixWorld);
            this.camera = camera;
        } else {
            trace('THREE.Raycaster: Unsupported camera type: ' + camera.type);
        }
    }

    public function setFromXRController(controller:Dynamic):Raycaster {
        _matrix.identity().extractRotation(controller.matrixWorld);
        this.ray.origin.setFromMatrixPosition(controller.matrixWorld);
        this.ray.direction.set(0, 0, -1).applyMatrix4(_matrix);
        return this;
    }

    public function intersectObject(object:Dynamic, ?recursive:Bool = true, ?intersects:Array<Dynamic> = []):Array<Dynamic> {
        intersect(object, this, intersects, recursive);
        intersects.sort(ascSort);
        return intersects;
    }

    public function intersectObjects(objects:Array<Dynamic>, ?recursive:Bool = true, ?intersects:Array<Dynamic> = []):Array<Dynamic> {
        for (i in 0...objects.length) {
            intersect(objects[i], this, intersects, recursive);
        }
        intersects.sort(ascSort);
        return intersects;
    }

    private static function ascSort(a:Dynamic, b:Dynamic):Int {
        return a.distance - b.distance;
    }

    private static function intersect(object:Dynamic, raycaster:Raycaster, intersects:Array<Dynamic>, recursive:Bool):Void {
        var stopTraversal = false;
        if (object.layers.test(raycaster.layers)) {
            stopTraversal = object.raycast(raycaster, intersects);
        }
        if (recursive && !stopTraversal) {
            for (i in 0...object.children.length) {
                intersect(object.children[i], raycaster, intersects, true);
            }
        }
    }
}