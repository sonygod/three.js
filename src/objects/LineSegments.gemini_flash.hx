package ;

import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.math.Vector3;
import three.objects.Line;

class LineSegments extends Line {

	public var isLineSegments(default, null) : Bool;

	public function new(geometry : Dynamic, material : Dynamic) {
		super(geometry, material);

		isLineSegments = true;

		this.type = "LineSegments";
	}

	public function computeLineDistances() : LineSegments {
		var geometry = this.geometry;

		// we assume non-indexed geometry
		if (geometry.index == null) {
			var positionAttribute = geometry.attributes.position;
			var lineDistances = [];
			var _start = new Vector3();
			var _end = new Vector3();

			var i = 0;
			while (i < positionAttribute.count) {
				_start.fromBufferAttribute(positionAttribute, i);
				_end.fromBufferAttribute(positionAttribute, i + 1);

				lineDistances[i] = (i == 0) ? 0 : lineDistances[i - 1];
				lineDistances[i + 1] = lineDistances[i] + _start.distanceTo(_end);
				i += 2;
			}

			geometry.setAttribute("lineDistance", new Float32BufferAttribute(lineDistances, 1));
		} else {
			trace('THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
		}

		return this;
	}

}