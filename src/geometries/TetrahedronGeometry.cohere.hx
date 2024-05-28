package;

import js.PolyhedronGeometry;

class TetrahedronGeometry extends PolyhedronGeometry {
	public function new(radius:Float = 1., detail:Int = 0) {
		super([1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1], [2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1], radius, detail);
		this.type = 'TetrahedronGeometry';
		this.parameters = { 'radius': radius, 'detail': detail };
	}

	public static function fromJSON(data:Dynamic) {
		return new TetrahedronGeometry(data.radius, data.detail);
	}
}