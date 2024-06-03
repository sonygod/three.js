import Line from "./Line.hx";
import Vector3 from "../math/Vector3.hx";
import Float32BufferAttribute from "../core/BufferAttribute.hx";

class LineSegments extends Line {

	public var isLineSegments:Bool = true;
	public var type:String = "LineSegments";

	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);
	}

	public function computeLineDistances():LineSegments {
		var geometry = this.geometry;

		// we assume non-indexed geometry
		if (geometry.index == null) {
			var positionAttribute = geometry.attributes.position;
			var lineDistances:Array<Float> = [];

			for (var i = 0; i < positionAttribute.count; i += 2) {
				var _start = Vector3.fromBufferAttribute(positionAttribute, i);
				var _end = Vector3.fromBufferAttribute(positionAttribute, i + 1);

				lineDistances[i] = (i == 0) ? 0 : lineDistances[i - 1];
				lineDistances[i + 1] = lineDistances[i] + _start.distanceTo(_end);
			}

			geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
		} else {
			Sys.println("THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
		}

		return this;
	}
}

class LineSegments {
	static inline function __init__() {
		_start = new Vector3();
		_end = new Vector3();
	}
	static public var _start:Vector3;
	static public var _end:Vector3;
}

LineSegments.__init__();

export { LineSegments };