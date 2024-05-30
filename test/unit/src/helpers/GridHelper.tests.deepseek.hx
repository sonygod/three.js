package three.js.test.unit.src.helpers;

import three.js.src.helpers.GridHelper;
import three.js.src.objects.LineSegments;
import js.Lib.QUnit;

class GridHelperTests {

    public static function main() {

        QUnit.module('Helpers', () -> {

            QUnit.module('GridHelper', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new GridHelper();
                    assert.strictEqual(
                        Std.is(object, LineSegments), true,
                        'GridHelper extends from LineSegments'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new GridHelper();
                    assert.ok(object, 'Can instantiate a GridHelper.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new GridHelper();
                    assert.ok(
                        object.type == 'GridHelper',
                        'GridHelper.type should be GridHelper'
                    );

                });

                // PUBLIC
                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new GridHelper();
                    object.dispose();

                });

            });

        });

    }

}