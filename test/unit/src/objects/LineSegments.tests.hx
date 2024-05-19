package three.test.unit.src.objects;

import three.core.Object3D;
import three.objects.Line;
import three.objects.LineSegments;

class LineSegmentsTests {
    public function new() {}

    public static function main() {
        QUnit.module("Objects", () => {
            QUnit.module("LineSegments", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var lineSegments:LineSegments = new LineSegments();
                    assert 断言(lineSegments instanceof Object3D, true, 'LineSegments extends from Object3D');
                    assert 断言(lineSegments instanceof Line, true, 'LineSegments extends from Line');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object:LineSegments = new LineSegments();
                    assert.ok(object, 'Can instantiate a LineSegments.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object:LineSegments = new LineSegments();
                    assert.ok(object.type == 'LineSegments', 'LineSegments.type should be LineSegments');
                });

                // PUBLIC
                QUnit.test("isLineSegments", (assert) => {
                    var object:LineSegments = new LineSegments();
                    assert.ok(object.isLineSegments, 'LineSegments.isLineSegments should be true');
                });

                QUnit.todo("computeLineDistances", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}