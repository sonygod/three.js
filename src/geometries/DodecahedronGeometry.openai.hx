import three.js.src.geometries.PolyhedronGeometry;

class DodecahedronGeometry extends PolyhedronGeometry {

	public var radius(default, null):Float;
	public var detail(default, null):Int;

	public function new(radius = 1, detail = 0) {
		super();
		var t:Float = (1 + Math.sqrt(5)) / 2;
		var r:Float = 1 / t;

		var vertices:Array<Float> = [
			-1, -1, -1, -1, -1, 1, -1, 1, -1, -1, 1, 1,
			1, -1, -1, 1, -1, 1, 1, 1, -1, 1, 1, 1,
			0, -r, -t, 0, -r, t, 0, r, -t, 0, r, t,
			-r, -t, 0, -r, t, 0, r, -t, 0, r, t, 0,
			-t, 0, -r, t, 0, -r, -t, 0, r, t, 0, r
		];

		var indices:Array<Int> = [
			3, 11, 7, 3, 7, 15, 3, 15, 13,
			7, 19, 17, 7, 17, 6, 7, 6, 15,
			17, 4, 8, 17, 8, 10, 17, 10, 6,
			8, 0, 16, 8, 16, 2, 8, 2, 10,
			0, 12, 1, 0, 1, 18, 0, 18, 16,
			6, 10, 2, 6, 2, 13, 6, 13, 15,
			2, 16, 18, 2, 18, 3, 2, 3, 13,
			18, 1, 9, 18, 9, 11, 18, 11, 3,
			4, 14, 12, 4, 12, 0, 4, 0, 8,
			11, 9, 5, 11, 5, 19, 11, 19, 7,
			19, 5, 14, 19, 14, 4, 19, 4, 17,
			1, 12, 14, 1, 14, 5, 1, 5, 9
		];

		this.vertices = vertices;
		this.indices = indices;
		this.radius = radius;
		this.detail = detail;
		this.type = "DodecahedronGeometry";
		this.parameters = {radius: radius, detail: detail};
	}

	public static function fromJSON(data):DodecahedronGeometry {
		return new DodecahedronGeometry(data.radius, data.detail);
	}

}

export { DodecahedronGeometry };