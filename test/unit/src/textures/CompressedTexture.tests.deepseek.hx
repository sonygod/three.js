package three.js.test.unit.src.textures;

import three.js.src.textures.CompressedTexture;
import three.js.src.textures.Texture;
import js.Lib;

class CompressedTextureTests {
    static function main() {
        QUnit.module('Textures', () -> {
            QUnit.module('CompressedTexture', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new CompressedTexture();
                    assert.strictEqual(
                        Std.instanceof(object, Texture), true,
                        'CompressedTexture extends from Texture'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new CompressedTexture();
                    assert.ok(object, 'Can instantiate a CompressedTexture.');
                });

                // PROPERTIES
                QUnit.todo('image', (assert) -> {
                    // { width: width, height: height }
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('mipmaps', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('flipY', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('generateMipmaps', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isCompressedTexture', (assert) -> {
                    var object = new CompressedTexture();
                    assert.ok(
                        object.isCompressedTexture,
                        'CompressedTexture.isCompressedTexture should be true'
                    );
                });
            });
        });
    }
}