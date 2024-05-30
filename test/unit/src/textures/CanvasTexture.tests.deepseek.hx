package;

import three.textures.CanvasTexture;
import three.textures.Texture;
import js.Lib.QUnit;

class CanvasTextureTests {

    public static function main() {
        QUnit.module('Textures', () -> {
            QUnit.module('CanvasTexture', () -> {
                QUnit.test('Extending', (assert) -> {
                    var object = new CanvasTexture();
                    assert.strictEqual(
                        Std.is(object, Texture), true,
                        'CanvasTexture extends from Texture'
                    );
                });

                QUnit.test('Instancing', (assert) -> {
                    var object = new CanvasTexture();
                    assert.ok(object, 'Can instantiate a CanvasTexture.');
                });

                QUnit.todo('needsUpdate', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('isCanvasTexture', (assert) -> {
                    var object = new CanvasTexture();
                    assert.ok(
                        object.isCanvasTexture,
                        'CanvasTexture.isCanvasTexture should be true'
                    );
                });
            });
        });
    }
}