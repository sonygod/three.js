import three.math.Matrix4;
import three.math.Ray;
import three.core.Layers;

class Raycaster {
  
    public var ray:Ray;
    public var near:Float;
    public var far:Float;
    public var camera:Null<Dynamic>;
    public var layers:Layers;
    public var params:{Mesh:Dynamic, Line:Dynamic, LOD:Dynamic, Points:Dynamic, Sprite:Dynamic};

    public function new(origin:Vector3, direction:Vector3, near:Float = 0, far:Float = Math.POSITIVE_INFINITY) {
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

    public function set(origin:Vector3, direction:Vector3):Void {
        // direction is assumed to be normalized (for accurate distance calculations)
        this.ray.set(origin, direction);
    }

    public function setFromCamera(coords:Vector2, camera:Dynamic):Void {
        switch (Type.enumEq(camera.type, "PerspectiveCamera")) {
            case true:
                this.ray.origin.setFromMatrixPosition(camera.matrixWorld);
                this.ray.direction.set(coords.x, coords.y, 0.5).unproject(camera).sub(this.ray.origin).normalize();
                this.camera = camera;
            case false:
                switch (Type.enumEq(camera.type, "OrthographicCamera")) {
                    case true:
                        this.ray.origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera); // set origin in plane of camera
                        this.ray.direction.set(0, 0, -1).transformDirection(camera.matrixWorld);
                        this.camera = camera;
                    case false:
                        trace('THREE.Raycaster: Unsupported camera type: ' + camera.type);
        }
        }
    }

    public function setFromXRController(controller:Dynamic):Raycaster {
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
    return Std.int(a.distance - b.distance);
}

function intersect(object:Dynamic, raycaster:Raycaster, intersects:Array<Dynamic>, recursive:Bool):Void {
    var stopTraversal:Bool = false;
    if (object.layers.test(raycaster.layers)) {
        stopTraversal = object.raycast(raycaster, intersects);
    }
    if (recursive && !stopTraversal) {
        var children = object.children;
        for (i in 0...children.length) {
            intersect(children[i], raycaster, intersects, true);
        }
    }
}