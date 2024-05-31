package ;

import three.core.BufferGeometry;
import three.extras.core.Float32BufferAttribute;
import three.lines.LineSegmentsGeometry;
import three.objects.Line;

class LineGeometry extends LineSegmentsGeometry {

	public var isLineGeometry(default, null) : Bool;

	public function new() {
		super();
		isLineGeometry = true;
		type = 'LineGeometry';
	}
	
	public function setPositions(array : Array<Float>) : LineGeometry {
		// converts [ x1, y1, z1,  x2, y2, z2, ... ] to pairs format
		var length = array.length - 3;
		var points = new Float32Array(2 * length);
		
		for (i in 0...Std.int(length / 3)) {
			points[2 * i * 3] = array[i * 3];
			points[2 * i * 3 + 1] = array[i * 3 + 1];
			points[2 * i * 3 + 2] = array[i * 3 + 2];
			
			points[2 * i * 3 + 3] = array[i * 3 + 3];
			points[2 * i * 3 + 4] = array[i * 3 + 4];
			points[2 * i * 3 + 5] = array[i * 3 + 5];
		}
		
		super.setPositions(points);
		
		return this;
	}
	
	public function setColors(array : Array<Float>) : LineGeometry {
		// converts [ r1, g1, b1,  r2, g2, b2, ... ] to pairs format
		var length = array.length - 3;
		var colors = new Float32Array(2 * length);
		
		for (i in 0...Std.int(length / 3)) {
			colors[2 * i * 3] = array[i * 3];
			colors[2 * i * 3 + 1] = array[i * 3 + 1];
			colors[2 * i * 3 + 2] = array[i * 3 + 2];
			
			colors[2 * i * 3 + 3] = array[i * 3 + 3];
			colors[2 * i * 3 + 4] = array[i * 3 + 4];
			colors[2 * i * 3 + 5] = array[i * 3 + 5];
		}
		
		super.setColors(colors);
		
		return this;
	}
	
	public function fromLine(line : Line) : LineGeometry {
		var geometry = line.geometry;
		if (geometry != null) {
			var positionAttribute = geometry.attributes.get("position");
			if (positionAttribute != null) {
				setPositions(cast(positionAttribute, Float32BufferAttribute).array);
			}
			// set colors, maybe
		}
		return this;
	}
}