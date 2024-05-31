package ;

import three.core.Geometry;
import three.geometries.WireframeGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {

	public var isWireframeGeometry2(get, never):Bool;

	public function new(geometry:Geometry) {
		super();

		this.type = 'WireframeGeometry2';

		this.fromWireframeGeometry(new WireframeGeometry(geometry));

		// set colors, maybe
	}

	inline function get_isWireframeGeometry2():Bool {
		return true;
	}

}