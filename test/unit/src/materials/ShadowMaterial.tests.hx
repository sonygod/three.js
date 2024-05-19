package three.test.unit.src.materials;

import three.materials.ShadowMaterial;
import three.materials.Material;

class ShadowMaterialTests {
    public function new() {}

    public static function main() {
        test("Materials", () => {
            test("ShadowMaterial", () => {
                // INHERITANCE
                test("Extending", () => {
                    var object = new ShadowMaterial();
                    assertTrue(object instanceof Material, "ShadowMaterial extends from Material");
                });

                // INSTANCING
                test("Instancing", () => {
                    var object = new ShadowMaterial();
                    assertTrue(object != null, "Can instantiate a ShadowMaterial.");
                });

                // PROPERTIES
                test("type", () => {
                    var object = new ShadowMaterial();
                    assertEquals(object.type, "ShadowMaterial", "ShadowMaterial.type should be ShadowMaterial");
                });

                todo("color", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("transparent", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                todo("fog", () => {
                    assertTrue(false, "everything's gonna be alright");
                });

                // PUBLIC
                test("isShadowMaterial", () => {
                    var object = new ShadowMaterial();
                    assertTrue(object.isShadowMaterial, "ShadowMaterial.isShadowMaterial should be true");
                });

                todo("copy", () => {
                    assertTrue(false, "everything's gonna be alright");
                });
            });
        });
    }
}