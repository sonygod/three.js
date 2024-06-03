package threejs.test.unit.src.materials;

import threejs.src.materials.ShaderMaterial;
import threejs.src.materials.Material;

class ShaderMaterialTests {
    public function new() {
        testExtending();
        testInstancing();
        testType();
        testIsShaderMaterial();
    }

    private function testExtending():Void {
        var object:ShaderMaterial = new ShaderMaterial();
        haxe.unit.Assert.isTrue(Std.is(object, Material), "ShaderMaterial extends from Material");
    }

    private function testInstancing():Void {
        var object:ShaderMaterial = new ShaderMaterial();
        haxe.unit.Assert.isNotNull(object, "Can instantiate a ShaderMaterial.");
    }

    private function testType():Void {
        var object:ShaderMaterial = new ShaderMaterial();
        haxe.unit.Assert.is("ShaderMaterial", object.type, "ShaderMaterial.type should be ShaderMaterial");
    }

    private function testIsShaderMaterial():Void {
        var object:ShaderMaterial = new ShaderMaterial();
        haxe.unit.Assert.isTrue(object.isShaderMaterial, "ShaderMaterial.isShaderMaterial should be true");
    }
}