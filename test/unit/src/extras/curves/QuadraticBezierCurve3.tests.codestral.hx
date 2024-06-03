import qunit.QUnit;
import three.extras.curves.QuadraticBezierCurve3;
import three.extras.core.Curve;
import three.math.Vector3;

class QuadraticBezierCurve3Tests {
    private var _curve:QuadraticBezierCurve3;

    public function new() {
        QUnit.module("Extras", () -> {
            QUnit.module("Curves", () -> {
                QUnit.module("QuadraticBezierCurve3", () -> {
                    // Hooks
                    QUnit.before(() -> {
                        _curve = new QuadraticBezierCurve3(
                            new Vector3(-10, 0, 2),
                            new Vector3(20, 15, -5),
                            new Vector3(10, 0, 10)
                        );
                    });

                    // INHERITANCE
                    QUnit.test("Extending", (assert) -> {
                        var object = new QuadraticBezierCurve3();
                        assert.strictEqual(Std.is(object, Curve), true, "QuadraticBezierCurve3 extends from Curve");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) -> {
                        var object = new QuadraticBezierCurve3();
                        assert.ok(object != null, "Can instantiate a QuadraticBezierCurve3.");
                    });

                    // PROPERTIES
                    QUnit.test("type", (assert) -> {
                        var object = new QuadraticBezierCurve3();
                        assert.ok(object.type == "QuadraticBezierCurve3", "QuadraticBezierCurve3.type should be QuadraticBezierCurve3");
                    });

                    // PUBLIC
                    QUnit.test("isQuadraticBezierCurve3", (assert) -> {
                        var object = new QuadraticBezierCurve3();
                        assert.ok(object.isQuadraticBezierCurve3, "QuadraticBezierCurve3.isQuadraticBezierCurve3 should be true");
                    });

                    // TODO: Implement the remaining tests
                });
            });
        });
    }
}