import haxe.unit.TestRunner;
import haxe.unit.TestCase;

import three.materials.MeshToonMaterial;
import three.materials.Material;

class MeshToonMaterialTests {
    public function new() {}

    public static function main() {
        var runner = new TestRunner();
        runner.add(new MeshToonMaterialTests());
        runner.run();
    }

    public function testExtending() {
        var object = new MeshToonMaterial();
        assertEquals(true, Std.is(object, Material), 'MeshToonMaterial extends from Material');
    }

    public function testInstancing() {
        var object = new MeshToonMaterial();
        assertNotNull(object, 'Can instantiate a MeshToonMaterial.');
    }

    public function testType() {
        var object = new MeshToonMaterial();
        assertEquals('MeshToonMaterial', object.type, 'MeshToonMaterial.type should be MeshToonMaterial');
    }

    public function todo_defines() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_color() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    // ... and so on for all the todo tests...

    public function testIsMeshToonMaterial() {
        var object = new MeshToonMaterial();
        assertTrue(object.isMeshToonMaterial, 'MeshToonMaterial.isMeshToonMaterial should be true');
    }

    public function todo_copy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}