import haxe.unit.TestCase;
import three.js.geometries.ShapeGeometry;
import three.js.extras.core.Shape;
import three.js.core.BufferGeometry;

class ShapeGeometryTest extends TestCase {
    var geometries:Array<ShapeGeometry>;

    override public function setup():Void {
        var triangleShape:Shape = new Shape();
        triangleShape.moveTo(0, -1);
        triangleShape.lineTo(1, 1);
        triangleShape.lineTo(-1, 1);

        geometries = [new ShapeGeometry(triangleShape)];
    }

    public function testExtending():Void {
        var object:ShapeGeometry = new ShapeGeometry();
        assertEquals(true, Std.is(object, BufferGeometry), 'ShapeGeometry extends from BufferGeometry');
    }

    public function testInstancing():Void {
        var object:ShapeGeometry = new ShapeGeometry();
        assertNotNull(object, 'Can instantiate a ShapeGeometry.');
    }

    public function testType():Void {
        var object:ShapeGeometry = new ShapeGeometry();
        assertEquals('ShapeGeometry', object.type, 'ShapeGeometry.type should be ShapeGeometry');
    }

    public function todoParameters():Void {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoToJSON():Void {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoFromJSON():Void {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }

    public function todoStandardGeometryTests():Void {
        assertEquals(true, false, 'everything\'s gonna be alright');
    }
}