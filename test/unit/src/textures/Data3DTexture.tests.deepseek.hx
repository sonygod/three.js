import js.Lib;
import three.js.textures.Data3DTexture;
import three.js.textures.Texture;

class Data3DTextureTests {
    static function main() {
        QUnit.module('Textures', () -> {
            QUnit.module('Data3DTexture', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new Data3DTexture();
                    assert.strictEqual(
                        Std.is(object, Texture), true,
                        'Data3DTexture extends from Texture'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new Data3DTexture();
                    assert.ok(object, 'Can instantiate a Data3DTexture.');
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
                QUnit.test('isData3DTexture', (assert) -> {
                    var object = new Data3DTexture();
                    assert.ok(
                        object.isData3DTexture,
                        'Data3DTexture.isData3DTexture should be true'
                    );
                });
            });
        });
    }
}