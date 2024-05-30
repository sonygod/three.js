package;

import three.math.Euler;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.utils.math_constants;

class EulerTests {

    static var eulerZero = new Euler(0, 0, 0, 'XYZ');
    static var eulerAxyz = new Euler(1, 0, 0, 'XYZ');
    static var eulerAzyx = new Euler(0, 1, 0, 'ZYX');

    static function matrixEquals4(a:Matrix4, b:Matrix4, tolerance:Float):Bool {

        tolerance = tolerance || 0.0001;
        if (a.elements.length != b.elements.length) {

            return false;

        }

        for (i in 0...a.elements.length) {

            var delta = a.elements[i] - b.elements[i];
            if (delta > tolerance) {

                return false;

            }

        }

        return true;

    }

    static function quatEquals(a:Quaternion, b:Quaternion, tolerance:Float):Bool {

        tolerance = tolerance || 0.0001;
        var diff = Math.abs(a.x - b.x) + Math.abs(a.y - b.y) + Math.abs(a.z - b.z) + Math.abs(a.w - b.w);

        return (diff < tolerance);

    }

    static function main() {

        // INSTANCING
        var a = new Euler();
        trace(a.equals(eulerZero));
        trace(!a.equals(eulerAxyz));
        trace(!a.equals(eulerAzyx));

        // STATIC STUFF
        trace(Euler.DEFAULT_ORDER == 'XYZ');

        // PROPERTIES STUFF
        var b = false;
        a._onChange(function () {

            b = true;

        });
        a.x = 10;
        trace(b);
        trace(a.x == 10);

        // ... 其他测试代码 ...

        // PUBLIC STUFF
        trace(a.isEuler);
        var b = new Vector3();
        trace(!b.isEuler);

        // ... 其他测试代码 ...

        // reorder
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (i in 0...testValues.length) {

            var v = testValues[i];
            var q = new Quaternion().setFromEuler(v);

            v.reorder('YZX');
            var q2 = new Quaternion().setFromEuler(v);
            trace(quatEquals(q, q2));

            v.reorder('ZXY');
            var q3 = new Quaternion().setFromEuler(v);
            trace(quatEquals(q, q3));

        }

        // ... 其他测试代码 ...

        // iterable
        var e = new Euler(0.5, 0.75, 1, 'YZX');
        var array = [for (i in e) i];
        trace(array[0] == 0.5);
        trace(array[1] == 0.75);
        trace(array[2] == 1);
        trace(array[3] == 'YZX');

    }

}