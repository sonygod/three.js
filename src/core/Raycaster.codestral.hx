import three.math.Matrix4;
import three.math.Ray;
import three.core.Layers;

class Raycaster {
    private var _matrix: Matrix4 = new Matrix4();
    public var ray: Ray;
    public var near: Float;
    public var far: Float;
    public var camera: dynamic;
    public var layers: Layers;
    public var params: Dynamic;

    public function new(origin: Float, direction: Float, near: Float = 0., far: Float = Float.POSITIVE_INFINITY) {
        this.ray = new Ray(origin, direction);
        this.near = near;
        this.far = far;
        this.camera = null;
        this.layers = new Layers();
        this.params = {
            Mesh: {},
            Line: {threshold: 1},
            LOD: {},
            Points: {threshold: 1},
            Sprite: {}
        };
    }

    public function set(origin: Float, direction: Float) {
        this.ray.set(origin, direction);
    }

    public function setFromCamera(coords: Dynamic, camera: dynamic) {
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

    public function setFromXRController(controller: dynamic) {
        _matrix.identity().extractRotation(controller.matrixWorld);
        this.ray.origin.setFromMatrixPosition(controller.matrixWorld);
        this.ray.direction.set(0, 0, -1).applyMatrix4(_matrix);
        return this;
    }

    public function intersectObject(object: dynamic, recursive: Bool = true, intersects: Array<Dynamic> = []) {
        intersect(object, this, intersects, recursive);
        intersects.sort(ascSort);
        return intersects;
    }

    public function intersectObjects(objects: Array<Dynamic>, recursive: Bool = true, intersects: Array<Dynamic> = []) {
        for (object in objects) {
            intersect(object, this, intersects, recursive);
        }
        intersects.sort(ascSort);
        return intersects;
    }
}

function ascSort(a: Dynamic, b: Dynamic): Int {
    return a.distance - b.distance;
}

function intersect(object: dynamic, raycaster: Raycaster, intersects: Array<Dynamic>, recursive: Bool) {
    var stopTraversal: Bool = false;

    if (object.layers.test(raycaster.layers)) {
        stopTraversal = object.raycast(raycaster, intersects);
    }

    if (recursive && !stopTraversal) {
        var children: Array<Dynamic> = object.children;
        for (child in children) {
            intersect(child, raycaster, intersects, true);
        }
    }
}