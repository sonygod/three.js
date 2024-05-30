package three.js.test.unit.src.helpers;

import three.js.src.helpers.AxesHelper;
import three.js.src.objects.LineSegments;
import js.Lib.QUnit;

class AxesHelperTests {

    public static function main() {

        QUnit.module('Helpers', () -> {

            QUnit.module('AxesHelper', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new AxesHelper();
                    assert.strictEqual(
                        Std.is(object, LineSegments), true,
                        'AxesHelper extends from LineSegments'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new AxesHelper();
                    assert.ok(object, 'Can instantiate an AxesHelper.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new AxesHelper();
                    assert.ok(
                        object.type == 'AxesHelper',
                        'AxesHelper.type should be AxesHelper'
                    );

                });

                // PUBLIC
                QUnit.todo('setColors', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new AxesHelper();
                    object.dispose();

                });

            });

        });

    }

}