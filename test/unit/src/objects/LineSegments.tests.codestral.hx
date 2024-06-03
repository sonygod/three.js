import js.Browser;
import js.html.QUnit;
import three.src.core.Object3D;
import three.src.objects.Line;
import three.src.objects.LineSegments;

class LineSegmentsTests {
    public function new() {
        QUnit.module("Objects", () -> {
            QUnit.module("LineSegments", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var lineSegments:LineSegments = new LineSegments();
                    assert.strictEqual(Std.is(lineSegments, Object3D), true, 'LineSegments extends from Object3D');
                    assert.strictEqual(Std.is(lineSegments, Line), true, 'LineSegments extends from Line');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:LineSegments = new LineSegments();
                    assert.ok(object, 'Can instantiate a LineSegments.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object:LineSegments = new LineSegments();
                    assert.ok(
                        object.type == "LineSegments",
                        'LineSegments.type should be LineSegments'
                    );
                });

                // PUBLIC
                QUnit.test("isLineSegments", (assert) -> {
                    var object:LineSegments = new LineSegments();
                    assert.ok(
                        object.isLineSegments,
                        'LineSegments.isLineSegments should be true'
                    );
                });

                // The QUnit.todo function is not directly supported in Haxe, so I omitted the test case for 'computeLineDistances'
            });
        });
    }
}

new LineSegmentsTests();