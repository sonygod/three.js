import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.InstancedBufferGeometry;
import three.core.InstancedBufferAttribute;
import three.math.Box3;
import three.math.Sphere;
import three.math.Vector3;

class InstancedPointsGeometry extends InstancedBufferGeometry {
	public var isInstancedPointsGeometry:Bool = true;
	public var type:String = "InstancedPointsGeometry";

	public function new() {
		super();

		var positions = [-1, 1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];
		var uvs = [-1, 1, 1, 1, -1, -1, 1, -1];
		var index = [0, 2, 1, 2, 3, 1];

		setIndex(index);
		setAttribute("position", new Float32BufferAttribute(positions, 3));
		setAttribute("uv", new Float32BufferAttribute(uvs, 2));
	}

	public function applyMatrix4(matrix:Dynamic):InstancedPointsGeometry {
		var pos = attributes.instancePosition;

		if (pos != null) {
			pos.applyMatrix4(matrix);
			pos.needsUpdate = true;
		}

		if (boundingBox != null) {
			computeBoundingBox();
		}

		if (boundingSphere != null) {
			computeBoundingSphere();
		}

		return this;
	}

	public function setPositions(array:Dynamic):InstancedPointsGeometry {
		var points:Float32Array;

		if (Std.is(array, Float32Array)) {
			points = array;
		} else if (Std.is(array, Array)) {
			points = new Float32Array(array);
		}

		setAttribute("instancePosition", new InstancedBufferAttribute(points, 3));

		computeBoundingBox();
		computeBoundingSphere();

		return this;
	}

	public function setColors(array:Dynamic):InstancedPointsGeometry {
		var colors:Float32Array;

		if (Std.is(array, Float32Array)) {
			colors = array;
		} else if (Std.is(array, Array)) {
			colors = new Float32Array(array);
		}

		setAttribute("instanceColor", new InstancedBufferAttribute(colors, 3));

		return this;
	}

	public function computeBoundingBox():Void {
		if (boundingBox == null) {
			boundingBox = new Box3();
		}

		var pos = attributes.instancePosition;

		if (pos != null) {
			boundingBox.setFromBufferAttribute(pos);
		}
	}

	public function computeBoundingSphere():Void {
		if (boundingSphere == null) {
			boundingSphere = new Sphere();
		}

		if (boundingBox == null) {
			computeBoundingBox();
		}

		var pos = attributes.instancePosition;

		if (pos != null) {
			var center = boundingSphere.center;
			boundingBox.getCenter(center);

			var maxRadiusSq = 0;

			for (var i = 0; i < pos.count; i++) {
				var vector = new Vector3();
				vector.fromBufferAttribute(pos, i);
				maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(vector));
			}

			boundingSphere.radius = Math.sqrt(maxRadiusSq);

			if (Math.isNaN(boundingSphere.radius)) {
				console.error("THREE.InstancedPointsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.", this);
			}
		}
	}

	public function toJSON():Dynamic {
		// todo
		return null;
	}
}