import three.js.examples.jsm.lines.LineSegmentsGeometry;

class LineGeometry extends LineSegmentsGeometry {

	public function new() {
		super();
		this.isLineGeometry = true;
		this.type = 'LineGeometry';
	}

	public function setPositions(array:Array<Float>) {
		var length = array.length - 3;
		var points = new Float32Array(2 * length);
		for (i in 0...length) {
			var j = i * 3;
			points[j] = array[j];
			points[j + 1] = array[j + 1];
			points[j + 2] = array[j + 2];
			points[j + 3] = array[j + 3];
			points[j + 4] = array[j + 4];
			points[j + 5] = array[j + 5];
		}
		super.setPositions(points);
		return this;
	}

	public function setColors(array:Array<Float>) {
		var length = array.length - 3;
		var colors = new Float32Array(2 * length);
		for (i in 0...length) {
			var j = i * 3;
			colors[j] = array[j];
			colors[j + 1] = array[j + 1];
			colors[j + 2] = array[j + 2];
			colors[j + 3] = array[j + 3];
			colors[j + 4] = array[j + 4];
			colors[j + 5] = array[j + 5];
		}
		super.setColors(colors);
		return this;
	}

	public function fromLine(line:Line) {
		var geometry = line.geometry;
		this.setPositions(geometry.attributes.position.array);
		return this;
	}
}