package three.js.test.unit.src.textures;

import three.js.src.textures.DataArrayTexture;
import three.js.src.textures.Texture;

class DataArrayTextureTests {

    static function main() {
        QUnit.module('Textures', () -> {
            QUnit.module('DataArrayTexture', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new DataArrayTexture();
                    assert.strictEqual(
                        Std.instanceof(object, Texture), true,
                        'DataArrayTexture extends from Texture'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new DataArrayTexture();
                    assert.ok(object, 'Can instantiate a DataArrayTexture.');
                });

                // PROPERTIES
                QUnit.todo('image', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('magFilter', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('minFilter', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('wrapR', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('generateMipmaps', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('flipY', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('unpackAlignment', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isDataArrayTexture', (assert) -> {
                    var object = new DataArrayTexture();
                    assert.ok(
                        object.isDataArrayTexture,
                        'DataArrayTexture.isDataArrayTexture should be true'
                    );
                });
            });
        });
    }
}