import qunit.QUnit;
import three.materials.MeshNormalMaterial;
import three.materials.Material;

class MeshNormalMaterialTests {
    public function new() {
        QUnit.module("Materials", () -> {
            QUnit.module("MeshNormalMaterial", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new MeshNormalMaterial();
                    assert.strictEqual(Std.is(object, Material), true, "MeshNormalMaterial extends from Material");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new MeshNormalMaterial();
                    assert.ok(object, "Can instantiate a MeshNormalMaterial.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new MeshNormalMaterial();
                    assert.ok(object.type == "MeshNormalMaterial", "MeshNormalMaterial.type should be MeshNormalMaterial");
                });

                // PUBLIC
                QUnit.test("isMeshNormalMaterial", (assert) -> {
                    var object = new MeshNormalMaterial();
                    assert.ok(object.isMeshNormalMaterial, "MeshNormalMaterial.isMeshNormalMaterial should be true");
                });
            });
        });
    }
}