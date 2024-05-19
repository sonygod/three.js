package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.LineBasicMaterial;
import three.materials.Material;

class LineBasicMaterialTests extends TestCase {

    public function new() {}

    public function testExtending():Void {
        var object = new LineBasicMaterial();
        assertEquals(true, Std.is(object, Material), 'LineBasicMaterial extends from Material');
    }

    public function testInstancing():Void {
        var object = new LineBasicMaterial();
        assertNotNull(object, 'Can instantiate a LineBasicMaterial.');
    }

    public function testType():Void {
        var object = new LineBasicMaterial();
        assertEquals('LineBasicMaterial', object.type, 'LineBasicMaterial.type should be LineBasicMaterial');
    }

    public function todoColor():Void {
        // todo
    }

    public function todoLinewidth():Void {
        // todo
    }

    public function todoLinecap():Void {
        // todo
    }

    public function todoLinejoin():Void {
        // todo
    }

    public function todoFog():Void {
        // todo
    }

    public function testIsLineBasicMaterial():Void {
        var object = new LineBasicMaterial();
        assertTrue(object.isLineBasicMaterial, 'LineBasicMaterial.isLineBasicMaterial should be true');
    }

    public function todoCopy():Void {
        // todo
    }
}