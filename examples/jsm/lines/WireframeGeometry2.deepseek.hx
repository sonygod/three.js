import three.WireframeGeometry;
import three.examples.jsm.lines.LineSegmentsGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {

	public function new(geometry:Geometry) {

		super();

		this.isWireframeGeometry2 = true;

		this.type = 'WireframeGeometry2';

		this.fromWireframeGeometry(new WireframeGeometry(geometry));

		// set colors, maybe

	}

}

typedef WireframeGeometry2 = three.examples.jsm.lines.WireframeGeometry2;