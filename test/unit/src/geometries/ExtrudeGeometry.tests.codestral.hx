import qunit.QUnit;
import three.src.geometries.ExtrudeGeometry;
import three.src.core.BufferGeometry;

class ExtrudeGeometryTests {
    public function new() {
        QUnit.module("Geometries", () -> {
            QUnit.module("ExtrudeGeometry", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new ExtrudeGeometry();
                    assert.strictEqual(Std.is(object, BufferGeometry), true, "ExtrudeGeometry extends from BufferGeometry");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new ExtrudeGeometry();
                    assert.ok(object != null, "Can instantiate an ExtrudeGeometry.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new ExtrudeGeometry();
                    assert.ok(object.type == "ExtrudeGeometry", "ExtrudeGeometry.type should be ExtrudeGeometry");
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}