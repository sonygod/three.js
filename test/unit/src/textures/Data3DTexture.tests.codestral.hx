import qunit.QUnit;
import three.src.textures.Data3DTexture;
import three.src.textures.Texture;

@:jsDoc("Data3DTexture tests")
class Data3DTextureTests {
    public static function main() {
        QUnit.module("Textures", () -> {
            QUnit.module("Data3DTexture", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:Data3DTexture = new Data3DTexture();
                    assert.strictEqual(Std.is(object, Texture), true, 'Data3DTexture extends from Texture');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:Data3DTexture = new Data3DTexture();
                    assert.ok(object != null, 'Can instantiate a Data3DTexture.');
                });

                // TODO: PROPERTIES

                // PUBLIC
                QUnit.test("isData3DTexture", (assert) -> {
                    var object:Data3DTexture = new Data3DTexture();
                    assert.ok(object.isData3DTexture, 'Data3DTexture.isData3DTexture should be true');
                });
            });
        });
    }
}