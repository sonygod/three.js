import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Spherical;
import three.math.Quaternion;
import three.math.Euler;
import three.math.Cylindrical;
import three.core.BufferAttribute;
import three.cameras.PerspectiveCamera;
import js.QUnit;

class Vector3Tests {
    public function new() {
        QUnit.module("Maths", () -> {
            QUnit.module("Vector3", () -> {
                QUnit.test("Instancing", (assert) -> {
                    var a:Vector3 = new Vector3();
                    assert.ok(a.x == 0, 'Passed!');
                    assert.ok(a.y == 0, 'Passed!');
                    assert.ok(a.z == 0, 'Passed!');

                    a = new Vector3(x, y, z);
                    assert.ok(a.x === x, 'Passed!');
                    assert.ok(a.y === y, 'Passed!');
                    assert.ok(a.z === z, 'Passed!');
                });

                // Continue converting the remaining tests in a similar manner...

                // ...
            });
        });
    }
}