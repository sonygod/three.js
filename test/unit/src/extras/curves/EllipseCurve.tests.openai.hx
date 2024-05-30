package three.js.test.unit.src.extras.curves;

import three.js.extras.curves.EllipseCurve;
import three.js.extras.core.Curve;
import three.js.math.Vector2;

class EllipseCurveTest {
    public function new() {}

    public static function main():Void {
        QUnit.module("Extras", () -> {
            QUnit.module("Curves", () -> {
                QUnit.module("EllipseCurve", (hooks) -> {
                    var curve:EllipseCurve;

                    hooks.before(() -> {
                        curve = new EllipseCurve(
                            0, 0, // ax, aY
                            10, 10, // xRadius, yRadius
                            0, 2 * Math.PI, // aStartAngle, aEndAngle
                            false, // aClockwise
                            0 // aRotation
                        );
                    });

                    // INHERITANCE
                    QUnit.test("Extending", (assert) -> {
                        var object:EllipseCurve = new EllipseCurve();
                        assert.ok(object instanceof Curve, "EllipseCurve extends from Curve");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) -> {
                        var object:EllipseCurve = new EllipseCurve();
                        assert.ok(object, "Can instantiate an EllipseCurve.");
                    });

                    // PROPERTIES
                    QUnit.test("type", (assert) -> {
                        var object:EllipseCurve = new EllipseCurve();
                        assert.ok(object.type == "EllipseCurve", "EllipseCurve.type should be EllipseCurve");
                    });

                    // todo: implement these tests
                    QUnit.todo("aX", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("aY", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // ... (rest of the todo tests)

                    // PUBLIC
                    QUnit.test("isEllipseCurve", (assert) -> {
                        var object:EllipseCurve = new EllipseCurve();
                        assert.ok(object.isEllipseCurve, "EllipseCurve.isEllipseCurve should be true");
                    });

                    // ... (rest of the tests)
                });
            });
        });
    }
}