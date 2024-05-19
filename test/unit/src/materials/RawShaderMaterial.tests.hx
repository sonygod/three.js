package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;

class RawShaderMaterialTests {
    public function new() {}

    public function testExtending():Void {
        var object:RawShaderMaterial = new RawShaderMaterial();
        assertEquals(true, Std.is(object, ShaderMaterial), 'RawShaderMaterial extends from ShaderMaterial');
    }

    public function testInstancing():Void {
        var object:RawShaderMaterial = new RawShaderMaterial();
        assertNotNull(object, 'Can instantiate a RawShaderMaterial.');
    }

    public function testType():Void {
        var object:RawShaderMaterial = new RawShaderMaterial();
        assertEquals('RawShaderMaterial', object.type, 'RawShaderMaterial.type should be RawShaderMaterial');
    }

    public function testIsRawShaderMaterial():Void {
        var object:RawShaderMaterial = new RawShaderMaterial();
        assertTrue(object.isRawShaderMaterial, 'RawShaderMaterial.isRawShaderMaterial should be true');
    }
}