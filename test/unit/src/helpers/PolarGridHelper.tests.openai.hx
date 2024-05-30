package three.helpers.tests;

import three.helpers.PolarGridHelper;
import three.objects.LineSegments;

class PolarGridHelperTests {

    public function new() {}

    public function testExtending():Void {
        var object:PolarGridHelper = new PolarGridHelper();
        assertTrue(Std.is(object, LineSegments), 'PolarGridHelper extends from LineSegments');
    }

    public function testInstancing():Void {
        var object:PolarGridHelper = new PolarGridHelper();
        assertNotNull(object, 'Can instantiate a PolarGridHelper.');
    }

    public function testType():Void {
        var object:PolarGridHelper = new PolarGridHelper();
        assertEquals(object.type, 'PolarGridHelper', 'PolarGridHelper.type should be PolarGridHelper');
    }

    public function testDispose():Void {
        var object:PolarGridHelper = new PolarGridHelper();
        object.dispose();
        // no assertions, just test that dispose doesn't throw
    }

}