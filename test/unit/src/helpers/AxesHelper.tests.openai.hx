import haxe_unit.TestCase;
import three.js.helpers.AxesHelper;
import three.js.objects.LineSegments;

class AxesHelperTest extends TestCase {

    public function new() { super(); }

    public function testExtending() {
        var object = new AxesHelper();
        assertEquals(true, Std.is(object, LineSegments), 'AxesHelper extends from LineSegments');
    }

    public function testInstancing() {
        var object = new AxesHelper();
        assertNotNull(object, 'Can instantiate an AxesHelper.');
    }

    public function testType() {
        var object = new AxesHelper();
        assertEquals('AxesHelper', object.type, 'AxesHelper.type should be AxesHelper');
    }

    public function testSetColors() {
        // NOTE: Haxe doesn't have a direct equivalent to QUnit.todo, so I've simply commented out the test for now
        // assertEquals(false, true, "everything's gonna be alright");
    }

    public function testDispose() {
        var object = new AxesHelper();
        object.dispose();
        // assertEquals(0, 0); // No assertions expected
    }
}