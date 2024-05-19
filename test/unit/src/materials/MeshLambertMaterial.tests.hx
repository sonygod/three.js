package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.MeshLambertMaterial;
import three.materials.Material;

class MeshLambertMaterialTest extends TestCase {
    public function new() {
        super();
    }

    public function testInheritance():Void {
        var object = new MeshLambertMaterial();
        assertEquals(true, Std.is(object, Material), "MeshLambertMaterial extends from Material");
    }

    public function testInstancing():Void {
        var object = new MeshLambertMaterial();
        assertNotNull(object, "Can instantiate a MeshLambertMaterial.");
    }

    public function testType():Void {
        var object = new MeshLambertMaterial();
        assertEquals("MeshLambertMaterial", object.type, "MeshLambertMaterial.type should be MeshLambertMaterial");
    }

    // TODO: Implement these tests
    public function testColor():Void {
        todo("Implement color test");
    }

    public function testMap():Void {
        todo("Implement map test");
    }

    public function testLightMap():Void {
        todo("Implement lightMap test");
    }

    public function testLightMapIntensity():Void {
        todo("Implement lightMapIntensity test");
    }

    public function testAoMap():Void {
        todo("Implement aoMap test");
    }

    public function testAoMapIntensity():Void {
        todo("Implement aoMapIntensity test");
    }

    public function testEmissive():Void {
        todo("Implement emissive test");
    }

    public function testEmissiveIntensity():Void {
        todo("Implement emissiveIntensity test");
    }

    public function testEmissiveMap():Void {
        todo("Implement emissiveMap test");
    }

    public function testBumpMap():Void {
        todo("Implement bumpMap test");
    }

    public function testBumpScale():Void {
        todo("Implement bumpScale test");
    }

    public function testNormalMap():Void {
        todo("Implement normalMap test");
    }

    public function testNormalMapType():Void {
        todo("Implement normalMapType test");
    }

    public function testNormalScale():Void {
        todo("Implement normalScale test");
    }

    public function testDisplacementMap():Void {
        todo("Implement displacementMap test");
    }

    public function testDisplacementScale():Void {
        todo("Implement displacementScale test");
    }

    public function testDisplacementBias():Void {
        todo("Implement displacementBias test");
    }

    public function testSpecularMap():Void {
        todo("Implement specularMap test");
    }

    public function testAlphaMap():Void {
        todo("Implement alphaMap test");
    }

    public function testEnvMap():Void {
        todo("Implement envMap test");
    }

    public function testCombine():Void {
        todo("Implement combine test");
    }

    public function testReflectivity():Void {
        todo("Implement reflectivity test");
    }

    public function testRefractionRatio():Void {
        todo("Implement refractionRatio test");
    }

    public function testWireframe():Void {
        todo("Implement wireframe test");
    }

    public function testWireframeLinewidth():Void {
        todo("Implement wireframeLinewidth test");
    }

    public function testWireframeLinecap():Void {
        todo("Implement wireframeLinecap test");
    }

    public function testWireframeLinejoin():Void {
        todo("Implement wireframeLinejoin test");
    }

    public function testFlatShading():Void {
        todo("Implement flatShading test");
    }

    public function testFog():Void {
        todo("Implement fog test");
    }

    public function testIsMeshLambertMaterial():Void {
        var object = new MeshLambertMaterial();
        assertTrue(object.isMeshLambertMaterial, "MeshLambertMaterial.isMeshLambertMaterial should be true");
    }

    public function testCopy():Void {
        todo("Implement copy test");
    }
}