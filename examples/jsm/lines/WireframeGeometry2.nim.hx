import three.examples.jsm.lines.WireframeGeometry;
import three.examples.jsm.lines.LineSegmentsGeometry;

class WireframeGeometry2 extends LineSegmentsGeometry {

    public function new(geometry:Dynamic) {

        super();

        this.isWireframeGeometry2 = true;

        this.type = 'WireframeGeometry2';

        this.fromWireframeGeometry(new WireframeGeometry(geometry));

        // set colors, maybe

    }

}

export class Main {
    public static function main() {
        trace('WireframeGeometry2 is ready to be used.');
    }
}