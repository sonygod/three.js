import qunit.QUnit;
import three.extras.curves.ArcCurve;
import three.extras.curves.EllipseCurve;

QUnit.module("Extras", () -> {
    QUnit.module("Curves", () -> {
        QUnit.module("ArcCurve", () -> {
            QUnit.test("Extending", (assert) -> {
                var object:ArcCurve = new ArcCurve();
                assert.strictEqual(Std.is(object, EllipseCurve), true, "ArcCurve extends from EllipseCurve");
            });

            QUnit.test("Instancing", (assert) -> {
                var object:ArcCurve = new ArcCurve();
                assert.ok(object, "Can instantiate an ArcCurve.");
            });

            QUnit.test("type", (assert) -> {
                var object:ArcCurve = new ArcCurve();
                assert.ok(object.type == "ArcCurve", "ArcCurve.type should be ArcCurve");
            });

            QUnit.test("isArcCurve", (assert) -> {
                var object:ArcCurve = new ArcCurve();
                assert.ok(object.isArcCurve, "ArcCurve.isArcCurve should be true");
            });
        });
    });
});