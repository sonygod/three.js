import qunit.QUnit;
import three.src.textures.DataArrayTexture;
import three.src.textures.Texture;

class DataArrayTextureTests {

    public function new() {
        QUnit.module("Textures", () -> {

            QUnit.module("DataArrayTexture", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {

                    var object:DataArrayTexture = new DataArrayTexture();
                    assert.isTrue(Std.is(object, Texture), 'DataArrayTexture extends from Texture');

                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {

                    var object:DataArrayTexture = new DataArrayTexture();
                    assert.isNotNull(object, 'Can instantiate a DataArrayTexture.');

                });

                // TODOs are not converted here, as they are placeholders for unimplemented tests.

                // PUBLIC
                QUnit.test("isDataArrayTexture", (assert) -> {

                    var object:DataArrayTexture = new DataArrayTexture();
                    assert.isTrue(object.isDataArrayTexture, 'DataArrayTexture.isDataArrayTexture should be true');

                });

            });

        });
    }
}