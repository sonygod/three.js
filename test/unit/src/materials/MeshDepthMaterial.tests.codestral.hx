// Haxe does not have global objects like JavaScript, so you need to import them.
import js.Browser.document;
import js.Browser.window;
import js.html.QUnit;
import three.src.materials.MeshDepthMaterial;
import three.src.materials.Material;

class MeshDepthMaterialTests {

    public function new() {
        QUnit.module("Materials", () -> {

            QUnit.module("MeshDepthMaterial", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {

                    var object:MeshDepthMaterial = new MeshDepthMaterial();
                    assert.strictEqual(
                        js.Boot.instanceof(object, Material), true,
                        'MeshDepthMaterial extends from Material'
                    );

                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {

                    var object:MeshDepthMaterial = new MeshDepthMaterial();
                    assert.isTrue(object != null, 'Can instantiate a MeshDepthMaterial.');

                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {

                    var object:MeshDepthMaterial = new MeshDepthMaterial();
                    assert.isTrue(
                        object.type == "MeshDepthMaterial",
                        'MeshDepthMaterial.type should be MeshDepthMaterial'
                    );

                });

                // PUBLIC
                QUnit.test("isMeshDepthMaterial", (assert) -> {

                    var object:MeshDepthMaterial = new MeshDepthMaterial();
                    assert.isTrue(
                        object.isMeshDepthMaterial,
                        'MeshDepthMaterial.isMeshDepthMaterial should be true'
                    );

                });

            });

        });
    }
}