import js.Browser.document;
import threejs.src.textures.CompressedArrayTexture;
import threejs.src.textures.CompressedTexture;

class CompressedArrayTextureTests {

    public static function main() {
        js.JQuery.module("Textures", () -> {
            js.JQuery.module("CompressedArrayTexture", () -> {

                // INHERITANCE
                js.JQuery.test("Extending", (assert) -> {
                    var object = new CompressedArrayTexture();
                    assert.strictEqual(
                        js.Boot.isInstanceOf(object, CompressedTexture),
                        true,
                        'CompressedArrayTexture extends from CompressedTexture'
                    );
                });

                // INSTANCING
                js.JQuery.test("Instancing", (assert) -> {
                    var object = new CompressedArrayTexture();
                    assert.ok(object, 'Can instantiate a CompressedArrayTexture.');
                });

                // PUBLIC
                js.JQuery.test("isCompressedArrayTexture", (assert) -> {
                    var object = new CompressedArrayTexture();
                    assert.ok(
                        object.isCompressedArrayTexture,
                        'CompressedArrayTexture.isCompressedArrayTexture should be true'
                    );
                });
            });
        });
    }
}