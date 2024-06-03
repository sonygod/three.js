import js.Browser.document;
import js.JQuery;
import js.html.QUnit;
import three.src.textures.CompressedTexture;
import three.src.textures.Texture;

class CompressedTextureTests {
    public function new() {
        QUnit.module("Textures", () -> {
            QUnit.module("CompressedTexture", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:CompressedTexture = new CompressedTexture();
                    js.Boot.instanceof(object, Texture); // CompressedTexture extends from Texture
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:CompressedTexture = new CompressedTexture();
                    assert.notNull(object, "Can instantiate a CompressedTexture.");
                });

                // PUBLIC
                QUnit.test("isCompressedTexture", (assert) -> {
                    var object:CompressedTexture = new CompressedTexture();
                    assert.isTrue(object.isCompressedTexture, "CompressedTexture.isCompressedTexture should be true");
                });
            });
        });
    }
}