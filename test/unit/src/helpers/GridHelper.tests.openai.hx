import haxe.unit.TestCase;
import three.helpers.GridHelper;
import three.objects.LineSegments;

class GridHelperTests {
    public function new() {}

    public function testExtending():Void {
        var object:GridHelper = new GridHelper();
        assertTrue(object instanceof LineSegments, 'GridHelper extends from LineSegments');
    }

    public function testInstancing():Void {
        var object:GridHelper = new GridHelper();
        assertNotNull(object, 'Can instantiate a GridHelper.');
    }

    public function testType():Void {
        var object:GridHelper = new GridHelper();
        assertEquals(object.type, 'GridHelper', 'GridHelper.type should be GridHelper');
    }

    public function testDispose():Void {
        var object:GridHelper = new GridHelper();
        object.dispose();
    }
}