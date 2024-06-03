import three.materials.ShadowMaterial;
import three.materials.Material;

class ShadowMaterialTests {
    public static function main() {
        testExtending();
        testInstancing();
        testType();
        testIsShadowMaterial();
    }

    private static function testExtending() {
        var object = new ShadowMaterial();
        if (Std.is(object, Material)) {
            trace("ShadowMaterial extends from Material");
        } else {
            trace("Error: ShadowMaterial does not extend from Material");
        }
    }

    private static function testInstancing() {
        var object = new ShadowMaterial();
        if (object != null) {
            trace("Can instantiate a ShadowMaterial.");
        } else {
            trace("Error: Cannot instantiate a ShadowMaterial.");
        }
    }

    private static function testType() {
        var object = new ShadowMaterial();
        if (object.type == "ShadowMaterial") {
            trace("ShadowMaterial.type should be ShadowMaterial");
        } else {
            trace("Error: ShadowMaterial.type is not ShadowMaterial");
        }
    }

    private static function testIsShadowMaterial() {
        var object = new ShadowMaterial();
        if (object.isShadowMaterial) {
            trace("ShadowMaterial.isShadowMaterial should be true");
        } else {
            trace("Error: ShadowMaterial.isShadowMaterial is not true");
        }
    }
}