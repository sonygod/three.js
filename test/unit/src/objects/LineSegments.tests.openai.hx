package three.js.test.unit.src.objects;

import three.js.core.Object3D;
import three.js.objects.Line;
import three.js.objects.LineSegments;

class LineSegmentsTests {
    public function new() {}

    public static function main() {
        QUnit.module("Objects", () -> {
            QUnit.module("LineSegments", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var lineSegments = new LineSegments();
                    assert.isTrue(lineSegments instanceof Object3D, "LineSegments extends from Object3D");
                    assert.isTrue(lineSegments instanceof Line, "LineSegments extends from Line");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new LineSegments();
                    assert.ok(object, "Can instantiate a LineSegments.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new LineSegments();
                    assert.ok(object.type == "LineSegments", "LineSegments.type should be LineSegments");
                });

                // PUBLIC
                QUnit.test("isLineSegments", (assert) -> {
                    var object = new LineSegments();
                    assert.ok(object.isLineSegments, "LineSegments.isLineSegments should be true");
                });

                QUnit.todo("computeLineDistances", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}