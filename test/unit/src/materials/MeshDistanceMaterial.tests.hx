package three.materials;

import haxe.unit.TestCase;
import three.materials.MeshDistanceMaterial;
import three.materials.Material;

class MeshDistanceMaterialTest {
    public function new() {}

    public function testExtending():Void {
        var object = new MeshDistanceMaterial();
        assertTrue(object instanceof Material, 'MeshDistanceMaterial extends from Material');
    }

    public function testInstancing():Void {
        var object = new MeshDistanceMaterial();
        assertTrue(object != null, 'Can instantiate a MeshDistanceMaterial.');
    }

    public function testType():Void {
        var object = new MeshDistanceMaterial();
        assertEquals(object.type, 'MeshDistanceMaterial', 'MeshDistanceMaterial.type should be MeshDistanceMaterial');
    }

    public function testMap():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testAlphaMap():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDisplacementMap():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDisplacementScale():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDisplacementBias():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsMeshDistanceMaterial():Void {
        var object = new MeshDistanceMaterial();
        assertTrue(object.isMeshDistanceMaterial, 'MeshDistanceMaterial.isMeshDistanceMaterial should be true');
    }

    public function testCopy():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}