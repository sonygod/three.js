package three.js.test.unit.src.loaders;

import three.js.src.loaders.CubeTextureLoader;
import three.js.src.loaders.Loader;

class CubeTextureLoaderTests {

    static function main() {

        QUnit.module('Loaders', () -> {

            QUnit.module('CubeTextureLoader', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new CubeTextureLoader();
                    assert.strictEqual(
                        Std.instanceof(object, Loader), true,
                        'CubeTextureLoader extends from Loader'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new CubeTextureLoader();
                    assert.ok(object, 'Can instantiate a CubeTextureLoader.');

                });

                // PUBLIC
                QUnit.todo('load', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}