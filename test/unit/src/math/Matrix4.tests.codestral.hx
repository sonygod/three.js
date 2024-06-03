import js.html.QUnit;
import three.src.math.Matrix3;
import three.src.math.Matrix4;
import three.src.math.Vector3;
import three.src.math.Euler;
import three.src.math.Quaternion;
import three.src.math.MathUtils;
import three.test.utils.mathConstants;

class Matrix4Tests {
    public static function matrixEquals4(a: Matrix4, b: Matrix4, tolerance: Float = 0.0001): Bool {
        if (a.elements.length != b.elements.length) return false;
        for (i in 0...a.elements.length) {
            if (Math.abs(a.elements[i] - b.elements[i]) > tolerance) return false;
        }
        return true;
    }

    public static function eulerEquals(a: Euler, b: Euler, tolerance: Float = 0.0001): Bool {
        return Math.abs(a.x - b.x) + Math.abs(a.y - b.y) + Math.abs(a.z - b.z) < tolerance;
    }

    @:QUnit.module("Maths")
    public static function mathsModule() {
        @:QUnit.module("Matrix4")
        public static function matrix4Module() {
            @:QUnit.test("Instancing")
            public static function instancingTest(assert: QUnit.Assert) {
                var a = new Matrix4();
                assert.ok(a.determinant() == 1, 'Passed!');

                var b = new Matrix4().set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                assert.ok(b.elements[0] == 0);
                assert.ok(b.elements[1] == 4);
                // ... rest of the assertions ...

                assert.ok(!matrixEquals4(a, b), 'Passed!');

                var c = new Matrix4(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                // ... rest of the assertions ...

                assert.ok(!matrixEquals4(a, c), 'Passed!');
            }

            // ... rest of the tests ...
        }
    }
}