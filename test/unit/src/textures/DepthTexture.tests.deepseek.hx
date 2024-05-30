package three.js.test.unit.src.textures;

import three.js.src.textures.DepthTexture;
import three.js.src.textures.Texture;
import js.Lib;

class DepthTextureTests {
    static function main() {
        Lib.QUnit.module('Textures', () -> {
            Lib.QUnit.module('DepthTexture', () -> {
                // INHERITANCE
                Lib.QUnit.test('Extending', (assert) -> {
                    var object = new DepthTexture();
                    assert.strictEqual(
                        Std.instanceof(object, Texture), true,
                        'DepthTexture extends from Texture'
                    );
                });

                // INSTANCING
                Lib.QUnit.test('Instancing', (assert) -> {
                    var object = new DepthTexture();
                    assert.ok(object, 'Can instantiate a DepthTexture.');
                });

                // PROPERTIES
                Lib.QUnit.todo('image', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                Lib.QUnit.todo('magFilter', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                Lib.QUnit.todo('minFilter', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                Lib.QUnit.todo('flipY', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                Lib.QUnit.todo('generateMipmaps', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                Lib.QUnit.test('isDepthTexture', (assert) -> {
                    var object = new DepthTexture();
                    assert.ok(
                        object.isDepthTexture,
                        'DepthTexture.isDepthTexture should be true'
                    );
                });
            });
        });
    }
}