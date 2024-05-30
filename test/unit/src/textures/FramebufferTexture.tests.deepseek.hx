package three.js.test.unit.src.textures;

import js.Lib;
import js.QUnit;
import three.js.src.textures.FramebufferTexture;
import three.js.src.textures.Texture;

class FramebufferTextureTests {
    static function main() {
        QUnit.module('Textures', () -> {
            QUnit.module('FramebufferTexture', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new FramebufferTexture();
                    assert.strictEqual(
                        Std.is(object, Texture), true,
                        'FramebufferTexture extends from Texture'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new FramebufferTexture();
                    assert.ok(object, 'Can instantiate a FramebufferTexture.');
                });

                // PROPERTIES
                QUnit.todo('format', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('magFilter', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('minFilter', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('generateMipmaps', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('needsUpdate', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isFramebufferTexture', (assert) -> {
                    var object = new FramebufferTexture();
                    assert.ok(
                        object.isFramebufferTexture,
                        'FramebufferTexture.isFramebufferTexture should be true'
                    );
                });
            });
        });
    }
}