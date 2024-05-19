package three.test.unit.src.geometries;

import haxe.unit.TestCase;
import three.geometries.WireframeGeometry;
import three.core.BufferGeometry;

class WireframeGeometryTest extends TestCase {
    var geometries:Array<WireframeGeometry>;

    override public function setup():Void {
        geometries = [new WireframeGeometry()];
    }

    public function testExtending():Void {
        var object:WireframeGeometry = new WireframeGeometry();
        assertEquals(object instanceof BufferGeometry, true, 'WireframeGeometry extends from BufferGeometry');
    }

    public function testInstancing():Void {
        var object:WireframeGeometry = new WireframeGeometry();
        assertTrue(object != null, 'Can instantiate a WireframeGeometry.');
    }

    public function testType():Void {
        var object:WireframeGeometry = new WireframeGeometry();
        assertEquals(object.type, 'WireframeGeometry', 'WireframeGeometry.type should be WireframeGeometry');
    }

    public function todoParameters():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoStandardGeometryTests():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}