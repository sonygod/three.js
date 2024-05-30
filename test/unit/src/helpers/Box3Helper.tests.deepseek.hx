package three.js.test.unit.src.helpers;

import three.js.src.helpers.Box3Helper;
import three.js.src.objects.LineSegments;
import js.Lib.QUnit;

class Box3HelperTest {

    public static function main() {

        QUnit.module('Helpers', () -> {

            QUnit.module('Box3Helper', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new Box3Helper();
                    assert.strictEqual(
                        Std.is(object, LineSegments), true,
                        'Box3Helper extends from LineSegments'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new Box3Helper();
                    assert.ok(object, 'Can instantiate a Box3Helper.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new Box3Helper();
                    assert.ok(
                        object.type == 'Box3Helper',
                        'Box3Helper.type should be Box3Helper'
                    );

                });

                QUnit.todo('box', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('updateMatrixWorld', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new Box3Helper();
                    object.dispose();

                });

            });

        });

    }

}