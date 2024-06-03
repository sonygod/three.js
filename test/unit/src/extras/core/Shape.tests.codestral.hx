import js.Browser.document;
import js.QUnit;
import three.extras.core.Shape;
import three.extras.core.Path;

class ShapeTests {
    public function new() {
        QUnit.module("Extras", () -> {
            QUnit.module("Core", () -> {
                QUnit.module("Shape", () -> {
                    QUnit.test("Extending", (assert) -> {
                        var object = new Shape();
                        assert.strictEqual(Std.is(object, Path), true, "Shape extends from Path");
                    });

                    QUnit.test("Instancing", (assert) -> {
                        var object = new Shape();
                        assert.ok(object, "Can instantiate a Shape.");
                    });

                    QUnit.test("type", (assert) -> {
                        var object = new Shape();
                        assert.ok(object.type == "Shape", "Shape.type should be Shape");
                    });

                    QUnit.todo("uuid", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("holes", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("getPointsHoles", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("extractPoints", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("copy", (assert) -> {
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
        });
    }
}

new ShapeTests();