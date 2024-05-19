import haxe.unit.TestCase;
import three.materials.MeshMatcapMaterial;
import three.materials.Material;

class MeshMatcapMaterialTests {
    public function new() {}

    public function testAll() {
        testInheritance();
        testInstancing();
        testDefines();
        testType();
        testColor();
        testMatcap();
        testMap();
        testBumpMap();
        testBumpScale();
        testNormalMap();
        testNormalMapType();
        testNormalScale();
        testDisplacementMap();
        testDisplacementScale();
        testDisplacementBias();
        testAlphaMap();
        testFlatShading();
        testFog();
        testIsMeshMatcapMaterial();
        testCopy();
    }

    private function testInheritance() {
        var object = new MeshMatcapMaterial();
        assertTrue(object instanceof Material, 'MeshMatcapMaterial extends from Material');
    }

    private function testInstancing() {
        var object = new MeshMatcapMaterial();
        assertNotNull(object, 'Can instantiate a MeshMatcapMaterial.');
    }

    private function testDefines() {
        var actual = new MeshMatcapMaterial().defines;
        var expected = { MATCAP: '' };
        assertEquals(actual, expected, 'Contains a MATCAP definition.');
    }

    private function testType() {
        var object = new MeshMatcapMaterial();
        assertEquals(object.type, 'MeshMatcapMaterial', 'MeshMatcapMaterial.type should be MeshMatcapMaterial');
    }

    private function testColor() {
        todo('color', 'everything\'s gonna be alright');
    }

    private function testMatcap() {
        todo('matcap', 'everything\'s gonna be alright');
    }

    private function testMap() {
        todo('map', 'everything\'s gonna be alright');
    }

    private function testBumpMap() {
        todo('bumpMap', 'everything\'s gonna be alright');
    }

    private function testBumpScale() {
        todo('bumpScale', 'everything\'s gonna be alright');
    }

    private function testNormalMap() {
        todo('normalMap', 'everything\'s gonna be alright');
    }

    private function testNormalMapType() {
        todo('normalMapType', 'everything\'s gonna be alright');
    }

    private function testNormalScale() {
        todo('normalScale', 'everything\'s gonna be alright');
    }

    private function testDisplacementMap() {
        todo('displacementMap', 'everything\'s gonna be alright');
    }

    private function testDisplacementScale() {
        todo('displacementScale', 'everything\'s gonna be alright');
    }

    private function testDisplacementBias() {
        todo('displacementBias', 'everything\'s gonna be alright');
    }

    private function testAlphaMap() {
        todo('alphaMap', 'everything\'s gonna be alright');
    }

    private function testFlatShading() {
        todo('flatShading', 'everything\'s gonna be alright');
    }

    private function testFog() {
        todo('fog', 'everything\'s gonna be alright');
    }

    private function testIsMeshMatcapMaterial() {
        var object = new MeshMatcapMaterial();
        assertTrue(object.isMeshMatcapMaterial, 'MeshMatcapMaterial.isMeshMatcapMaterial should be true');
    }

    private function testCopy() {
        todo('copy', 'everything\'s gonna be alright');
    }
}