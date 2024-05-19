import three.math.Matrix4;
import three.math.Ray;
import three.core.Layers;

class Raycaster {

	var ray:Ray;
	var near:Float;
	var far:Float;
	var camera:Dynamic;
	var layers:Layers;
	var params:Dynamic;

	public function new(origin, direction, near = 0, far = Infinity) {
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

	public function set(origin, direction) {
		this.ray.set(origin, direction);
	}

	public function setFromCamera(coords, camera) {
		if (Std.is(camera.isPerspectiveCamera, true)) {
			this.ray.origin.setFromMatrixPosition(camera.matrixWorld);
			this.ray.direction.set(coords.x, coords.y, 0.5).unproject(camera).sub(this.ray.origin).normalize();
			this.camera = camera;
		} else if (Std.is(camera.isOrthographicCamera, true)) {
			this.ray.origin.set(coords.x, coords.y, (camera.near + camera.far) / (camera.near - camera.far)).unproject(camera);
			this.ray.direction.set(0, 0, -1).transformDirection(camera.matrixWorld);
			this.camera = camera;
		} else {
			trace('THREE.Raycaster: Unsupported camera type: ' + camera.type);
		}
	}

	public function setFromXRController(controller) {
		var _matrix = new Matrix4().identity().extractRotation(controller.matrixWorld);
		this.ray.origin.setFromMatrixPosition(controller.matrixWorld);
		this.ray.direction.set(0, 0, -1).applyMatrix4(_matrix);
		return this;
	}

	public function intersectObject(object, recursive = true, intersects = []) {
		intersect(object, this, intersects, recursive);
		intersects.sort(ascSort);
		return intersects;
	}

	public function intersectObjects(objects, recursive = true, intersects = []) {
		for (i in objects) {
			intersect(objects[i], this, intersects, recursive);
		}
		intersects.sort(ascSort);
		return intersects;
	}

	static function ascSort(a, b) {
		return a.distance - b.distance;
	}

	static function intersect(object, raycaster, intersects, recursive) {
		var stopTraversal = false;
		if (object.layers.test(raycaster.layers)) {
			stopTraversal = object.raycast(raycaster, intersects);
		}
		if (Std.is(recursive, true) && stopTraversal !== true) {
			var children = object.children;
			for (i in children) {
				intersect(children[i], raycaster, intersects, true);
			}
		}
	}
}