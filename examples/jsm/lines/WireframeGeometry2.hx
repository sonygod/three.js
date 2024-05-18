package three.js.examples.jsm.lines;

import three.WireframeGeometry;
import three.lines.LineSegmentsGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {

	public var isWireframeGeometry2:Bool = true;

	public var type:String = 'WireframeGeometry2';

	public function new(geometry:Dynamic) {
		super();
		fromWireframeGeometry(new WireframeGeometry(geometry));
		// set colors, maybe
	}
}