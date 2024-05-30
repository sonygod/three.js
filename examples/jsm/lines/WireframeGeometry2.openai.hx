package three.js.examples.jsm.lines;

import three.WireframeGeometry;
import three.lines.LineSegmentsGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {

    public function new(geometry:Geometry) {
        super();

        this.isWireframeGeometry2 = true;

        this.type = 'WireframeGeometry2';

        fromWireframeGeometry(new WireframeGeometry(geometry));

        // set colors, maybe
    }
}