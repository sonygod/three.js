package three.helpers;

import haxe.unit.TestCase;
import three.helpers.PlaneHelper;
import three.objects.Line;

class PlaneHelperTest {
    public function new() {}

    public function testExtending():Void {
        var object:PlaneHelper = new PlaneHelper();
        assertEquals(true, Std.is(object, Line), 'PlaneHelper extends from Line');
    }

    public function testInstancing():Void {
        var object:PlaneHelper = new PlaneHelper();
        assertTrue(object != null, 'Can instantiate a PlaneHelper.');
    }

    public function testType():Void {
        var object:PlaneHelper = new PlaneHelper();
        assertEquals('PlaneHelper', object.type, 'PlaneHelper.type should be PlaneHelper');
    }

    public function testTodoPlane():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testTodoSize():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testTodoUpdateMatrixWorld():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDispose():Void {
        var object:PlaneHelper = new PlaneHelper();
        object.dispose();
    }
}