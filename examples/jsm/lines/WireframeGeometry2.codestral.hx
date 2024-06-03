import three.WireframeGeometry;
import three.lines.LineSegmentsGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {

    public function new(geometry:WireframeGeometry) {
        super();

        this.isWireframeGeometry2 = true;

        this.type = 'WireframeGeometry2';

        this.fromWireframeGeometry(new WireframeGeometry(geometry));

        // set colors, maybe
    }

}