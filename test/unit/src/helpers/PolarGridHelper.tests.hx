package three.test.unit.src.helpers;

import haxe.unit.TestCase;
import three.helpers.PolarGridHelper;
import three.objects.LineSegments;

class PolarGridHelperTest extends TestCase {

    public function new() {
        super();
    }

    public function testExtending() {
        var object:PolarGridHelper = new PolarGridHelper();
        assertTrue(object instanceof LineSegments, 'PolarGridHelper extends from LineSegments');
    }

    public function testInstancing() {
        var object:PolarGridHelper = new PolarGridHelper();
        assertNotNull(object, 'Can instantiate a PolarGridHelper.');
    }

    public function testType() {
        var object:PolarGridHelper = new PolarGridHelper();
        assertEquals(object.type, 'PolarGridHelper', 'PolarGridHelper.type should be PolarGridHelper');
    }

    public function testDispose() {
        var object:PolarGridHelper = new PolarGridHelper();
        object.dispose();
    }

}