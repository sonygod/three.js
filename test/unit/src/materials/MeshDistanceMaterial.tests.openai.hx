package three.materials;

import three.materials.MeshDistanceMaterial;
import three.materials.Material;

class MeshDistanceMaterialTests {
    public function new() {}

    public function testAll() {
        testExtending();
        testInstancing();
        testType();
        testIsMeshDistanceMaterial();
        // todo: implement the TODO tests
    }

    function testExtending() {
        var object = new MeshDistanceMaterial();
        assertTrue(object instanceof Material, 'MeshDistanceMaterial extends from Material');
    }

    function testInstancing() {
        var object = new MeshDistanceMaterial();
        assertTrue(object != null, 'Can instantiate a MeshDistanceMaterial.');
    }

    function testType() {
        var object = new MeshDistanceMaterial();
        assertEquals(object.type, 'MeshDistanceMaterial', 'MeshDistanceMaterial.type should be MeshDistanceMaterial');
    }

    function testIsMeshDistanceMaterial() {
        var object = new MeshDistanceMaterial();
        assertTrue(object.isMeshDistanceMaterial, 'MeshDistanceMaterial.isMeshDistanceMaterial should be true');
    }
}