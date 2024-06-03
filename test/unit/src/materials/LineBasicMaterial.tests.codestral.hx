import qunit.QUnit;
import three.src.materials.LineBasicMaterial;
import three.src.materials.Material;

class LineBasicMaterialTests {
    public function new() {
        QUnit.module("Materials", () -> {
            QUnit.module("LineBasicMaterial", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:LineBasicMaterial = new LineBasicMaterial();
                    assert.strictEqual(Std.is(object, Material), true, "LineBasicMaterial extends from Material");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:LineBasicMaterial = new LineBasicMaterial();
                    assert.ok(object != null, "Can instantiate a LineBasicMaterial.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object:LineBasicMaterial = new LineBasicMaterial();
                    assert.ok(object.type == "LineBasicMaterial", "LineBasicMaterial.type should be LineBasicMaterial");
                });

                // PUBLIC
                QUnit.test("isLineBasicMaterial", (assert) -> {
                    var object:LineBasicMaterial = new LineBasicMaterial();
                    assert.ok(object.isLineBasicMaterial, "LineBasicMaterial.isLineBasicMaterial should be true");
                });
            });
        });
    }
}