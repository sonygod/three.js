package three.js.test.unit.src.loaders;

import js.Lib.QUnit;
import three.js.src.loaders.DataTextureLoader;
import three.js.src.loaders.Loader;

class DataTextureLoaderTests {

    public static function main() {

        QUnit.module('Loaders', () -> {

            QUnit.module('DataTextureLoader', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new DataTextureLoader();
                    assert.strictEqual(
                        Std.is(object, Loader), true,
                        'DataTextureLoader extends from Loader'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new DataTextureLoader();
                    assert.ok(object, 'Can instantiate a DataTextureLoader.');

                });

                // PUBLIC
                QUnit.todo('load', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}