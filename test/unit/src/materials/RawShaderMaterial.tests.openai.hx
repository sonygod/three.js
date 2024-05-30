package three.test.unit.src.materials;

import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;

class RawShaderMaterialTests {
    public function new() {}

    public function testExtending() {
        var object = new RawShaderMaterial();
        Assert.isTrue(Std.is(object, ShaderMaterial), 'RawShaderMaterial extends from ShaderMaterial');
    }

    public function testInstancing() {
        var object = new RawShaderMaterial();
        Assert.isTrue(object != null, 'Can instantiate a RawShaderMaterial.');
    }

    public function testType() {
        var object = new RawShaderMaterial();
        Assert.equals(object.type, 'RawShaderMaterial', 'RawShaderMaterial.type should be RawShaderMaterial');
    }

    public function testIsRawShaderMaterial() {
        var object = new RawShaderMaterial();
        Assert.isTrue(object.isRawShaderMaterial, 'RawShaderMaterial.isRawShaderMaterial should be true');
    }
}