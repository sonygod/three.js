package three.js.test.unit.src.loaders;

import three.js.src.loaders.MaterialLoader;
import three.js.src.loaders.Loader;
import js.Lib;

class MaterialLoaderTests {

    static function main() {
        QUnit.module('Loaders', () -> {
            QUnit.module('MaterialLoader', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new MaterialLoader();
                    assert.strictEqual(
                        Std.instanceof(object, Loader), true,
                        'MaterialLoader extends from Loader'
                    );
                });

                // PROPERTIES
                QUnit.test('textures', (assert) -> {
                    var actual = new MaterialLoader().textures;
                    var expected = {};
                    assert.deepEqual(actual, expected, 'MaterialLoader defines textures.');
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new MaterialLoader();
                    assert.ok(object, 'Can instantiate a MaterialLoader.');
                });

                // PUBLIC
                QUnit.todo('load', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('parse', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('setTextures', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo('createMaterialFromType', (assert) -> {
                    // static createMaterialFromType(type)
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}