import LineSegmentsGeometry from '../lines/LineSegmentsGeometry';

class LineGeometry extends LineSegmentsGeometry {

	public function new() {

		super();

		this.isLineGeometry = true;

		this.type = 'LineGeometry';

	}

	public function setPositions(array:Float32Array):LineGeometry {

		// converts [ x1, y1, z1,  x2, y2, z2, ... ] to pairs format

		var length = array.length - 3;
		var points = new Float32Array(2 * length);

		for (i in 0...length) {

			points[2 * i] = array[i];
			points[2 * i + 1] = array[i + 1];
			points[2 * i + 2] = array[i + 2];

			points[2 * i + 3] = array[i + 3];
			points[2 * i + 4] = array[i + 4];
			points[2 * i + 5] = array[i + 5];

		}

		super.setPositions(points);

		return this;

	}

	public function setColors(array:Float32Array):LineGeometry {

		// converts [ r1, g1, b1,  r2, g2, b2, ... ] to pairs format

		var length = array.length - 3;
		var colors = new Float32Array(2 * length);

		for (i in 0...length) {

			colors[2 * i] = array[i];
			colors[2 * i + 1] = array[i + 1];
			colors[2 * i + 2] = array[i + 2];

			colors[2 * i + 3] = array[i + 3];
			colors[2 * i + 4] = array[i + 4];
			colors[2 * i + 5] = array[i + 5];

		}

		super.setColors(colors);

		return this;

	}

	public function fromLine(line):LineGeometry {

		var geometry = line.geometry;

		this.setPositions(geometry.attributes.position.array); // assumes non-indexed

		// set colors, maybe

		return this;

	}

}

export LineGeometry;