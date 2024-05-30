package three.js.test.unit.src.materials;

import three.js.src.materials.SpriteMaterial;
import three.js.src.materials.Material;
import js.QUnit;

class SpriteMaterialTests {

    public static function main() {

        QUnit.module('Materials', () -> {

            QUnit.module('SpriteMaterial', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new SpriteMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'SpriteMaterial extends from Material'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new SpriteMaterial();
                    assert.ok(object, 'Can instantiate a SpriteMaterial.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new SpriteMaterial();
                    assert.ok(
                        object.type == 'SpriteMaterial',
                        'SpriteMaterial.type should be SpriteMaterial'
                    );

                });

                QUnit.todo('color', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('map', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('alphaMap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('rotation', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('sizeAttenuation', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('transparent', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('fog', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isSpriteMaterial', (assert) -> {

                    var object = new SpriteMaterial();
                    assert.ok(
                        object.isSpriteMaterial,
                        'SpriteMaterial.isSpriteMaterial should be true'
                    );

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}