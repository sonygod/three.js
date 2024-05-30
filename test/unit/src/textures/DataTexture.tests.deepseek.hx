package three.js.test.unit.src.textures;

import three.js.src.textures.DataTexture;
import three.js.src.textures.Texture;
import js.Lib;

class DataTextureTests {

    static function main() {
        QUnit.module('Textures', () -> {
            QUnit.module('DataTexture', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new DataTexture();
                    assert.strictEqual(
                        Std.instanceof(object, Texture), true,
                        'DataTexture extends from Texture'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new DataTexture();
                    assert.ok(object, 'Can instantiate a DataTexture.');
                });

                // PROPERTIES
                QUnit.todo('image', (assert) -> {
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
                QUnit.test('isDataTexture', (assert) -> {
                    var object = new DataTexture();
                    assert.ok(
                        object.isDataTexture,
                        'DataTexture.isDataTexture should be true'
                    );
                });
            });
        });
    }
}