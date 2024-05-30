package three.js.test.unit.src.loaders;

import three.js.src.loaders.ObjectLoader;
import three.js.src.loaders.Loader;

class ObjectLoaderTests {

    static function main() {

        QUnit.module('Loaders', () -> {

            QUnit.module('ObjectLoader', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new ObjectLoader();
                    assert.strictEqual(
                        Std.instance(object, Loader), true,
                        'ObjectLoader extends from Loader'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new ObjectLoader();
                    assert.ok(object, 'Can instantiate an ObjectLoader.');

                });

                // PUBLIC
                QUnit.todo('load', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('loadAsync', (assert) -> {

                    // async loadAsync(url, onProgress)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parse', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseAsync', (assert) -> {

                    // async parseAsync(json)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseShapes', (assert) -> {

                    // parseShapes(json)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseSkeletons', (assert) -> {

                    // parseSkeletons(json, object)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseGeometries', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseMaterials', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseAnimations', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseImages', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseImagesAsync', (assert) -> {

                    // async parseImagesAsync(json)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseTextures', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('parseObject', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('bindSkeletons', (assert) -> {

                    // bindSkeletons(object, skeletons)
                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}