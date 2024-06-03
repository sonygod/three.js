import qunit.QUnit;
import three.math.Plane;
import three.math.Vector3;
import three.math.Line3;
import three.math.Sphere;
import three.math.Box3;
import three.math.Matrix4;
import three.utils.MathConstants;

function comparePlane(a: Plane, b: Plane, threshold: Float = 0.0001): Bool {
    return (a.normal.distanceTo(b.normal) < threshold && Math.abs(a.constant - b.constant) < threshold);
}

class PlaneTest {
    public static function main() {
        QUnit.module("Maths", () -> {
            QUnit.module("Plane", () -> {
                QUnit.test("Instancing", (assert: QUnit.Assert) -> {
                    var a = new Plane();
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 0, 'Passed!');
                    assert.ok(a.normal.z == 0, 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');

                    a = new Plane(MathConstants.one3.clone(), 0);
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 1, 'Passed!');
                    assert.ok(a.normal.z == 1, 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');

                    a = new Plane(MathConstants.one3.clone(), 1);
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 1, 'Passed!');
                    assert.ok(a.normal.z == 1, 'Passed!');
                    assert.ok(a.constant == 1, 'Passed!');
                });

                // ... continue for other tests in the same way
            });
        });

        QUnit.module("Plane");
    }
}