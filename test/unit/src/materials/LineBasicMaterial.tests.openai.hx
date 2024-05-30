package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.LineBasicMaterial;
import three.materials.Material;

class LineBasicMaterialTest {
    public function new() {}

    public function testExtending():Void {
        var object = new LineBasicMaterial();
        assertEquals(true, Std.is(object, Material));
    }

    public function testInstancing():Void {
        var object = new LineBasicMaterial();
        assertNotNull(object);
    }

    public function testType():Void {
        var object = new LineBasicMaterial();
        assertEquals('LineBasicMaterial', object.type);
    }

    // TODO: implement these tests
    public function testColor():Void {
        fail('not implemented');
    }

    public function testLinewidth():Void {
        fail('not implemented');
    }

    public function testLinecap():Void {
        fail('not implemented');
    }

    public function testLinejoin():Void {
        fail('not implemented');
    }

    public function testFog():Void {
        fail('not implemented');
    }

    public function testIsLineBasicMaterial():Void {
        var object = new LineBasicMaterial();
        assertTrue(object.isLineBasicMaterial);
    }

    public function testCopy():Void {
        fail('not implemented');
    }
}