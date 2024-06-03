import qunit.QUnit;
import three.math.Box3;
import three.math.Vector3;
import three.math.Sphere;
import three.math.Plane;
import three.math.Matrix4;
import three.utils.MathConstants;

@:jsRequire("qunit")
class SphereTests {
    public function new() {
        QUnit.module("Maths", () -> {
            QUnit.module("Sphere", () -> {
                QUnit.test("Instancing", (assert) -> {
                    var a = new Sphere();
                    assert.ok(a.center.equals(MathConstants.zero3), "Passed!");
                    assert.ok(a.radius == -1, "Passed!");

                    a = new Sphere(MathConstants.one3.clone(), 1);
                    assert.ok(a.center.equals(MathConstants.one3), "Passed!");
                    assert.ok(a.radius == 1, "Passed!");
                });

                // ... Continue with the rest of the tests
            });
        });
    }
}