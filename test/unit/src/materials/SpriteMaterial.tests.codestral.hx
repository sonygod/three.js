import js.Browser.document;
import three.materials.SpriteMaterial;
import three.materials.Material;

class SpriteMaterialTests {
    public function new() {
        QUnit.module("Materials", () -> {
            QUnit.module("SpriteMaterial", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:SpriteMaterial = new SpriteMaterial();
                    assert.strictEqual(Std.is(object, Material), true, "SpriteMaterial extends from Material");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:SpriteMaterial = new SpriteMaterial();
                    assert.ok(object != null, "Can instantiate a SpriteMaterial.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object:SpriteMaterial = new SpriteMaterial();
                    assert.ok(object.type == "SpriteMaterial", "SpriteMaterial.type should be SpriteMaterial");
                });

                // PUBLIC
                QUnit.test("isSpriteMaterial", (assert) -> {
                    var object:SpriteMaterial = new SpriteMaterial();
                    assert.ok(object.isSpriteMaterial, "SpriteMaterial.isSpriteMaterial should be true");
                });
            });
        });
    }
}