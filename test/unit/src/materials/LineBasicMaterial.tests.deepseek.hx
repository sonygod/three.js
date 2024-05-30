package three.js.test.unit.src.materials;

import three.js.src.materials.LineBasicMaterial;
import three.js.src.materials.Material;
import js.Lib.QUnit;

class LineBasicMaterialTest {

    public static function main() {

        QUnit.module('Materials', () -> {

            QUnit.module('LineBasicMaterial', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new LineBasicMaterial();
                    assert.strictEqual(
                        Std.is(object, Material), true,
                        'LineBasicMaterial extends from Material'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new LineBasicMaterial();
                    assert.ok(object, 'Can instantiate a LineBasicMaterial.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new LineBasicMaterial();
                    assert.ok(
                        object.type == 'LineBasicMaterial',
                        'LineBasicMaterial.type should be LineBasicMaterial'
                    );

                });

                QUnit.todo('color', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('linewidth', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('linecap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('linejoin', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('fog', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isLineBasicMaterial', (assert) -> {

                    var object = new LineBasicMaterial();
                    assert.ok(
                        object.isLineBasicMaterial,
                        'LineBasicMaterial.isLineBasicMaterial should be true'
                    );

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}