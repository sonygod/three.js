Here is the converted Haxe code:
```
package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.MeshToonMaterial;
import three.materials.Material;

class MeshToonMaterialTest {
    public function new() {}

    public function testInheritance() {
        var object = new MeshToonMaterial();
        assertTrue(object instanceof Material, 'MeshToonMaterial extends from Material');
    }

    public function testInstancing() {
        var object = new MeshToonMaterial();
        assertNotNull(object, 'Can instantiate a MeshToonMaterial.');
    }

    public function testType() {
        var object = new MeshToonMaterial();
        assertEquals(object.type, 'MeshToonMaterial', 'MeshToonMaterial.type should be MeshToonMaterial');
    }

    // TODO: implement tests for properties
    public function testDefines() {
        fail('everything\'s gonna be alright');
    }

    public function testColor() {
        fail('everything\'s gonna be alright');
    }

    public function testMap() {
        fail('everything\'s gonna be alright');
    }

    public function testGradientMap() {
        fail('everything\'s gonna be alright');
    }

    public function testLightMap() {
        fail('everything\'s gonna be alright');
    }

    public function testLightMapIntensity() {
        fail('everything\'s gonna be alright');
    }

    public function testAOMap() {
        fail('everything\'s gonna be alright');
    }

    public function testAOMapIntensity() {
        fail('everything\'s gonna be alright');
    }

    public function testEmissive() {
        fail('everything\'s gonna be alright');
    }

    public function testEmissiveIntensity() {
        fail('everything\'s gonna be alright');
    }

    public function testEmissiveMap() {
        fail('everything\'s gonna be alright');
    }

    public function testBumpMap() {
        fail('everything\'s gonna be alright');
    }

    public function testBumpScale() {
        fail('everything\'s gonna be alright');
    }

    public function testNormalMap() {
        fail('everything\'s gonna be alright');
    }

    public function testNormalMapType() {
        fail('everything\'s gonna be alright');
    }

    public function testNormalScale() {
        fail('everything\'s gonna be alright');
    }

    public function testDisplacementMap() {
        fail('everything\'s gonna be alright');
    }

    public function testDisplacementScale() {
        fail('everything\'s gonna be alright');
    }

    public function testDisplacementBias() {
        fail('everything\'s gonna be alright');
    }

    public function testAlphaMap() {
        fail('everything\'s gonna be alright');
    }

    public function testWireframe() {
        fail('everything\'s gonna be alright');
    }

    public function testWireframeLinewidth() {
        fail('everything\'s gonna be alright');
    }

    public function testWireframeLinecap() {
        fail('everything\'s gonna be alright');
    }

    public function testWireframeLinejoin() {
        fail('everything\'s gonna be alright');
    }

    public function testFog() {
        fail('everything\'s gonna be alright');
    }

    public function testIsMeshToonMaterial() {
        var object = new MeshToonMaterial();
        assertTrue(object.isMeshToonMaterial, 'MeshToonMaterial.isMeshToonMaterial should be true');
    }

    public function testCopy() {
        fail('everything\'s gonna be alright');
    }
}
```
Note that I've used the `haxe.unit` package for testing, and `assertTrue` and `assertEquals` for assertions. Also, I've replaced `QUnit.todo` with `fail` to indicate that those tests are not implemented yet.