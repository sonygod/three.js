import js.Browser.document;
import js.QUnit;
import js.three.Shape;
import js.three.ShapeGeometry;
import js.three.BufferGeometry;

class ShapeGeometryTests {

    public function new() {
        QUnit.module("Geometries", () -> {
            QUnit.module("ShapeGeometry", (hooks) -> {
                var geometries:Array<ShapeGeometry> = [];

                hooks.beforeEach(function() {
                    var triangleShape = new Shape();
                    triangleShape.moveTo(0, -1);
                    triangleShape.lineTo(1, 1);
                    triangleShape.lineTo(-1, 1);

                    geometries = [new ShapeGeometry(triangleShape)];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new ShapeGeometry();
                    assert.strictEqual(Std.is(object, BufferGeometry), true, "ShapeGeometry extends from BufferGeometry");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new ShapeGeometry();
                    assert.ok(object, "Can instantiate a ShapeGeometry.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new ShapeGeometry();
                    assert.ok(object.type == "ShapeGeometry", "ShapeGeometry.type should be ShapeGeometry");
                });

                // TODO: Uncomment and implement these tests
                // QUnit.todo("parameters", (assert) -> {
                //     assert.ok(false, "everything's gonna be alright");
                // });

                // QUnit.todo("toJSON", (assert) -> {
                //     assert.ok(false, "everything's gonna be alright");
                // });

                // QUnit.todo("fromJSON", (assert) -> {
                //     assert.ok(false, "everything's gonna be alright");
                // });

                // QUnit.todo("Standard geometry tests", (assert) -> {
                //     assert.ok(false, "everything's gonna be alright");
                // });
            });
        });
    }
}

new ShapeGeometryTests();