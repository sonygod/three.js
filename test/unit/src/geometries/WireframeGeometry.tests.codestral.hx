import three.geometries.WireframeGeometry;
import three.core.BufferGeometry;
import haxe.unit.TestCase;

class WireframeGeometryTests extends TestCase {

    public function new() {
        super("WireframeGeometryTests");
    }

    public function testExtending(): Void {
        var object = new WireframeGeometry();
        assertTrue(Std.is(object, BufferGeometry), "WireframeGeometry extends from BufferGeometry");
    }

    public function testInstancing(): Void {
        var object = new WireframeGeometry();
        assertNotNull(object, "Can instantiate a WireframeGeometry.");
    }

    public function testType(): Void {
        var object = new WireframeGeometry();
        assertEquals(object.type, "WireframeGeometry", "WireframeGeometry.type should be WireframeGeometry");
    }

    // TODO: Implement tests for parameters and standard geometry tests
}