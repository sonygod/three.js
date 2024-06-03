import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.objects.Line;

class LineSegments extends Line {

	public function new(geometry:Geometry, material:Material) {
		super(geometry, material);
		this.isLineSegments = true;
		this.type = 'LineSegments';
	}

	public function computeLineDistances():LineSegments {
		if (this.geometry.index == null) {
			var positionAttribute = this.geometry.attributes.position;
			var lineDistances = new Array<Float>();

			for (var i = 0; i < positionAttribute.count; i += 2) {
				var _start:Vector3 = new Vector3();
				var _end:Vector3 = new Vector3();

				_start.fromBufferAttribute(positionAttribute, i);
				_end.fromBufferAttribute(positionAttribute, i + 1);

				lineDistances[i] = (i == 0) ? 0.0 : lineDistances[i - 1];
				lineDistances[i + 1] = lineDistances[i] + _start.distanceTo(_end);
			}

			this.geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
		} else {
			trace('THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
		}

		return this;
	}
}