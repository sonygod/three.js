import three.geometries.TubeGeometry;
import three.extras.curves.LineCurve3;
import three.math.Vector3;
import three.core.BufferGeometry;

class TubeGeometryTests {
    public function new() {
        var path = new LineCurve3(new Vector3(0, 0, 0), new Vector3(0, 1, 0));
        var geometries = [new TubeGeometry(path)];

        testExtending();
        testInstancing();
        testType();
    }

    private function testExtending() {
        var object = new TubeGeometry();
        if (Std.is(object, BufferGeometry)) {
            trace('TubeGeometry extends from BufferGeometry');
        } else {
            trace('Test failed: TubeGeometry does not extend from BufferGeometry');
        }
    }

    private function testInstancing() {
        var object = new TubeGeometry();
        if (object != null) {
            trace('Can instantiate a TubeGeometry.');
        } else {
            trace('Test failed: Cannot instantiate a TubeGeometry.');
        }
    }

    private function testType() {
        var object = new TubeGeometry();
        if (object.type == 'TubeGeometry') {
            trace('TubeGeometry.type should be TubeGeometry');
        } else {
            trace('Test failed: TubeGeometry.type is not TubeGeometry');
        }
    }
}