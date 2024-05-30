package three.js.test.unit.src.helpers;

import three.js.src.helpers.ArrowHelper;
import three.js.src.core.Object3D;
import js.Lib.QUnit;

class ArrowHelperTests {

    public static function main() {

        QUnit.module('Helpers', () -> {

            QUnit.module('ArrowHelper', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new ArrowHelper();
                    assert.strictEqual(
                        Std.instanceof(object, Object3D), true,
                        'ArrowHelper extends from Object3D'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new ArrowHelper();
                    assert.ok(object, 'Can instantiate an ArrowHelper.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new ArrowHelper();
                    assert.ok(
                        object.type == 'ArrowHelper',
                        'ArrowHelper.type should be ArrowHelper'
                    );

                });

                QUnit.todo('position', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('line', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('cone', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('setDirection', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('setLength', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('setColor', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new ArrowHelper();
                    object.dispose();

                });

            });

        });

    }

}