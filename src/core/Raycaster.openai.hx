import three.math.Matrix4;
import three.math.Ray;
import three.core.Layers;

class Raycaster {
    
    public var ray:Ray;
    public var near:Float;
    public var far:Float;
    public var camera:Null<Any>;
    public var layers:Layers;
    public var params:{ Mesh:{}, Line:{ threshold: Int }, LOD:{}, Points:{ threshold: Int }, Sprite:{} };
    
    public function new(origin:Vector3, direction:Vector3, near:Float = 0, far:Float = Infinity) {
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
    
    public function set(origin:Vector3, direction:Vector3):Void {
        this.ray.set(origin, direction);
    }
    
    public function setFromCamera(coords:Vector2, camera:Any):Void {
        switch camera{
            case camera:Object of any:{
                var perspectiveCamera = camera.AsPerspectiveCamera();
                this.ray.origin.setFromMatrixPosition(perspectiveCamera.matrixWorld);
                this.ray.direction.set(coords.x, coords.y, 0.5).unproject(perspectiveCamera).sub(this.ray.origin).normalize();
                this.camera = perspectiveCamera;
            }
            
            case camera:Object of any:{
                var orthographicCamera = camera.AsOrthographicCamera();
                this.ray.origin.set(coords.x, coords.y, (orthoCamera.near + orthoCamera.far) / (orthoCamera.near - orthoCamera.far)).unproject(orthoCamera);
                this.ray.direction.set(0, 0, - 1).transformDirection(orthoCamera.matrixWorld);
                this.camera = orthoCamera;
            }
            
            default:
                trace('THREE.Raycaster: Unsupported camera type: ' + camera.type);
        }
    }
    
    public function setFromXRController(controller:Any):Raycaster {
        var matrix:Matrix4 = new Matrix4().identity().extractRotation(controller.matrixWorld);
        this.ray.origin.setFromMatrixPosition(controller.matrixWorld);
        this.ray.direction.set(0, 0, - 1).applyMatrix4(matrix);
        return this;
    }
    
    public function intersectObject(object:Any, recursive:Bool = true, intersects:Array<Dynamic> = []):Array<Dynamic> {
        intersect(object, this, intersects, recursive);
        intersects.sort(ascSort);
        return intersects;
    }
    
    public function intersectObjects(objects:Array<Any>, recursive:Bool = true, intersects:Array<Dynamic> = []):Array<Dynamic> {
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

function intersect(object:Any, raycaster:Raycaster, intersects:Array<Dynamic>, recursive:Bool):Void {
    var stopTraversal = false;
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