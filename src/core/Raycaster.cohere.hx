import Matrix4 from '../math/Matrix4.hx';
import Ray from '../math/Ray.hx';
import Layers from './Layers.hx';

class Raycaster {
    public var ray:Ray;
    public var near:Float;
    public var far:Float;
    public var camera:Camera;
    public var layers:Layers;
    public var params:Dynamic;

    public function new(origin:Float32Array, direction:Float32Array, near:Float = 0, far:Float = Infinity) {
        this.ray = Ray(origin, direction);
        this.near = near;
        this.far = far;
        this.camera = null;
        this.layers = Layers();
        this.params = {
            Mesh: {},
            Line: { threshold: 1 },
            LOD: {},
            Points: { threshold: 1 },
            Sprite: {}
        };
    }

    public function set(origin:Float32Array, direction:Float32Array):Void {
        this.ray.set(origin, direction);
    }

    public function setFromCamera(coords:Float32Array, camera:Camera):Void {
        if (camera.isPerspectiveCamera) {
            this.ray.origin.setFromMatrixPosition(camera.matrixWorld);
            this.ray.direction.set(coords.x, coords.y, 0.5).unproject(camera).sub(this.ray.origin).normalize();
            this.camera = camera;
        } else if (camera.isOrthographicCamera) {
            this.ray.origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
            this.ray.direction.set(0, 0, -1).transformDirection(camera.matrixWorld);
            this.camera = camera;
        } else {
            trace('Raycaster: Unsupported camera type: ' + camera.getType());
        }
    }

    public function setFromXRController(controller:Dynamic):Raycaster {
        var _matrix = Matrix4();
        _matrix.identity().extractRotation(controller.matrixWorld);

        this.ray.origin.setFromMatrixPosition(controller.matrixWorld);
        this.ray.direction.set(0, 0, -1).applyMatrix4(_matrix);

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

function ascSort(a:Dynamic, b:Dynamic):Int {
    return a.distance - b.distance;
}

function intersect(object:Dynamic, raycaster:Raycaster, intersects:Array<Dynamic>, recursive:Bool):Void {
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

class Export {
    public static function get Raycaster():Raycaster {
        return Raycaster;
    }
}