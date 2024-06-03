import js.Browser.document;
import js.html.QUnit;
import three.src.textures.DataTexture;
import three.src.textures.Texture;

class DataTextureTests {
    public function new() {
        QUnit.module("Textures", () -> {
            QUnit.module("DataTexture", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:DataTexture = new DataTexture();
                    assert.strictEqual(Std.is(object, Texture), true, "DataTexture extends from Texture");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:DataTexture = new DataTexture();
                    assert.ok(object != null, "Can instantiate a DataTexture.");
                });

                // PROPERTIES
                QUnit.todo("image", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("generateMipmaps", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("flipY", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("unpackAlignment", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isDataTexture", (assert) -> {
                    var object:DataTexture = new DataTexture();
                    assert.ok(object.isDataTexture, "DataTexture.isDataTexture should be true");
                });
            });
        });
    }
}