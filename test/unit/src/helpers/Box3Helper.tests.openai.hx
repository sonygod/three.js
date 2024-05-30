import haxe.unit.TestCase;
import helpers.Box3Helper;
import objects.LineSegments;

class TestBox3Helper extends TestCase {

    public function new() {
        super();
    }

    public function testExtending() {
        var object = new Box3Helper();
        assertTrue(Std.is(object, LineSegments));
    }

    public function testInstancing() {
        var object = new Box3Helper();
        assertNotNull(object);
    }

    public function testPropertiesType() {
        var object = new Box3Helper();
        assertEquals(object.type, 'Box3Helper');
    }

    public function testPropertiesBox() {
        // TODO: implement me
        assertTrue(false);
    }

    public function testUpdateMatrixWorld() {
        // TODO: implement me
        assertTrue(false);
    }

    public function testDispose() {
        var object = new Box3Helper();
        object.dispose();
        // no assertions, just test that dispose doesn't throw
    }
}