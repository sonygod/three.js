package three.js.test.unit.src.textures;

import js.Lib.QUnit;
import three.js.src.textures.CubeTexture;
import three.js.src.textures.Texture;

class CubeTextureTests {

    public static function main() {

        QUnit.module('Textures', () -> {

            QUnit.module('CubeTexture', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new CubeTexture();
                    assert.strictEqual(
                        Std.is(object, Texture), true,
                        'CubeTexture extends from Texture'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new CubeTexture();
                    assert.ok(object, 'Can instantiate a CubeTexture.');

                });

                // PROPERTIES
                QUnit.todo('images', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('flipY', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isCubeTexture', (assert) -> {

                    var object = new CubeTexture();
                    assert.ok(
                        object.isCubeTexture,
                        'CubeTexture.isCubeTexture should be true'
                    );

                });

            });

        });

    }

}