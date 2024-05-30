package three.js.test.unit.src.objects;

import three.js.src.core.Object3D;
import three.js.src.objects.Line;
import three.js.src.objects.LineSegments;

class LineSegmentsTests {

    static function main() {

        QUnit.module('Objects', () -> {

            QUnit.module('LineSegments', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var lineSegments = new LineSegments();
                    assert.strictEqual(Std.is(lineSegments, Object3D), true, 'LineSegments extends from Object3D');
                    assert.strictEqual(Std.is(lineSegments, Line), true, 'LineSegments extends from Line');

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new LineSegments();
                    assert.ok(object != null, 'Can instantiate a LineSegments.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new LineSegments();
                    assert.ok(
                        object.type == 'LineSegments',
                        'LineSegments.type should be LineSegments'
                    );

                });

                // PUBLIC
                QUnit.test('isLineSegments', (assert) -> {

                    var object = new LineSegments();
                    assert.ok(
                        object.isLineSegments,
                        'LineSegments.isLineSegments should be true'
                    );

                });

                QUnit.todo('computeLineDistances', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}