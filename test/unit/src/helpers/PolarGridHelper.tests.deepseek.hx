import three.js.test.unit.src.helpers.PolarGridHelper;
import three.js.test.unit.src.objects.LineSegments;
import haxeunit.Test;
import haxeunit.TestSuite;

class PolarGridHelperTest extends Test {

    static function main() {
        var suite = new TestSuite();
        suite.add(new PolarGridHelperTest());
        haxeunit.ui.TestRunner.run(suite);
    }

    public function new() {
        super();
    }

    public function testExtending() {
        var object = new PolarGridHelper();
        assertTrue(object instanceof LineSegments, 'PolarGridHelper extends from LineSegments');
    }

    public function testInstancing() {
        var object = new PolarGridHelper();
        assertNotNull(object, 'Can instantiate a PolarGridHelper.');
    }

    public function testType() {
        var object = new PolarGridHelper();
        assertEquals('PolarGridHelper', object.type, 'PolarGridHelper.type should be PolarGridHelper');
    }

    public function testDispose() {
        var object = new PolarGridHelper();
        object.dispose();
    }
}