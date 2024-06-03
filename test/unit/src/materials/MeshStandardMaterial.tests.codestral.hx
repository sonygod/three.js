import js.Browser.document;
import js.html.QUnit;
import three.materials.MeshStandardMaterial;
import three.materials.Material;

class MeshStandardMaterialTests {
    public static function main() {
        QUnit.module("Materials", () -> {
            QUnit.module("MeshStandardMaterial", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:MeshStandardMaterial = new MeshStandardMaterial();
                    assert.strictEqual(Std.is(object, Material), true, 'MeshStandardMaterial extends from Material');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:MeshStandardMaterial = new MeshStandardMaterial();
                    assert.ok(object != null, 'Can instantiate a MeshStandardMaterial.');
                });

                // PROPERTIES
                QUnit.todo("defines", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("type", (assert) -> {
                    var object:MeshStandardMaterial = new MeshStandardMaterial();
                    assert.ok(object.type == "MeshStandardMaterial", 'MeshStandardMaterial.type should be MeshStandardMaterial');
                });

                // ... (continue with the rest of the properties)

                // PUBLIC
                QUnit.test("isMeshStandardMaterial", (assert) -> {
                    var object:MeshStandardMaterial = new MeshStandardMaterial();
                    assert.ok(object.isMeshStandardMaterial, 'MeshStandardMaterial.isMeshStandardMaterial should be true');
                });

                QUnit.todo("copy", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}