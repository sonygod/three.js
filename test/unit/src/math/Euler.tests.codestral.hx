import three.math.Euler;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.utils.MathConstants;

class EulerTests {
    private var eulerZero:Euler = new Euler(0, 0, 0, "XYZ");
    private var eulerAxyz:Euler = new Euler(1, 0, 0, "XYZ");
    private var eulerAzyx:Euler = new Euler(0, 1, 0, "ZYX");

    public function new() {}

    private function matrixEquals4(a:Matrix4, b:Matrix4, tolerance:Float = 0.0001):Bool {
        if (a.elements.length != b.elements.length) return false;

        for (i in 0...a.elements.length) {
            var delta = a.elements[i] - b.elements[i];
            if (delta > tolerance) return false;
        }

        return true;
    }

    private function quatEquals(a:Quaternion, b:Quaternion, tolerance:Float = 0.0001):Bool {
        var diff = Math.abs(a.x - b.x) + Math.abs(a.y - b.y) + Math.abs(a.z - b.z) + Math.abs(a.w - b.w);
        return (diff < tolerance);
    }

    public function testInstancing() {
        var a = new Euler();
        trace(a.equals(eulerZero) ? "Passed!" : "Failed!");
        trace(a.equals(eulerAxyz) ? "Failed!" : "Passed!");
        trace(a.equals(eulerAzyx) ? "Failed!" : "Passed!");
    }

    public function testDEFAULT_ORDER() {
        trace(Euler.DEFAULT_ORDER == "XYZ" ? "Passed!" : "Failed!");
    }

    public function testX() {
        var a = new Euler();
        trace(a.x == 0 ? "Passed!" : "Failed!");

        a = new Euler(1, 2, 3);
        trace(a.x == 1 ? "Passed!" : "Failed!");

        a = new Euler(4, 5, 6, "XYZ");
        trace(a.x == 4 ? "Passed!" : "Failed!");

        a = new Euler(7, 8, 9, "XYZ");
        a.x = 10;
        trace(a.x == 10 ? "Passed!" : "Failed!");

        a = new Euler(11, 12, 13, "XYZ");
        var b = false;
        a._onChange(function() { b = true; });
        a.x = 14;
        trace(b ? "Passed!" : "Failed!");
        trace(a.x == 14 ? "Passed!" : "Failed!");
    }

    // Similar functions for testY and testZ

    public function testOrder() {
        var a = new Euler();
        trace(a.order == Euler.DEFAULT_ORDER ? "Passed!" : "Failed!");

        a = new Euler(1, 2, 3);
        trace(a.order == Euler.DEFAULT_ORDER ? "Passed!" : "Failed!");

        a = new Euler(4, 5, 6, "YZX");
        trace(a.order == "YZX" ? "Passed!" : "Failed!");

        a = new Euler(7, 8, 9, "YZX");
        a.order = "ZXY";
        trace(a.order == "ZXY" ? "Passed!" : "Failed!");

        a = new Euler(11, 12, 13, "YZX");
        var b = false;
        a._onChange(function() { b = true; });
        a.order = "ZXY";
        trace(b ? "Passed!" : "Failed!");
        trace(a.order == "ZXY" ? "Passed!" : "Failed!");
    }

    public function testIsEuler() {
        var a = new Euler();
        trace(a.isEuler ? "Passed!" : "Failed!");
        var b = new Vector3();
        trace(b.isEuler ? "Failed!" : "Passed!");
    }

    public function testCloneCopyEquals() {
        var a = eulerAxyz.clone();
        trace(a.equals(eulerAxyz) ? "Passed!" : "Failed!");
        trace(a.equals(eulerZero) ? "Failed!" : "Passed!");
        trace(a.equals(eulerAzyx) ? "Failed!" : "Passed!");

        a.copy(eulerAzyx);
        trace(a.equals(eulerAzyx) ? "Passed!" : "Failed!");
        trace(a.equals(eulerAxyz) ? "Failed!" : "Passed!");
        trace(a.equals(eulerZero) ? "Failed!" : "Passed!");
    }

    public function testQuaternionSetFromEulerEulerSetFromQuaternion() {
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (v in testValues) {
            var q = new Quaternion().setFromEuler(v);
            var v2 = new Euler().setFromQuaternion(q, v.order);
            var q2 = new Quaternion().setFromEuler(v2);
            trace(quatEquals(q, q2) ? "Passed!" : "Failed!");
        }
    }

    public function testMatrix4MakeRotationFromEulerEulerSetFromRotationMatrix() {
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (v in testValues) {
            var m = new Matrix4().makeRotationFromEuler(v);
            var v2 = new Euler().setFromRotationMatrix(m, v.order);
            var m2 = new Matrix4().makeRotationFromEuler(v2);
            trace(matrixEquals4(m, m2, 0.0001) ? "Passed!" : "Failed!");
        }
    }

    // TODO: testSetFromVector3

    public function testReorder() {
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (v in testValues) {
            var q = new Quaternion().setFromEuler(v);
            v.reorder("YZX");
            var q2 = new Quaternion().setFromEuler(v);
            trace(quatEquals(q, q2) ? "Passed!" : "Failed!");

            v.reorder("ZXY");
            var q3 = new Quaternion().setFromEuler(v);
            trace(quatEquals(q, q3) ? "Passed!" : "Failed!");
        }
    }

    public function testSetGetPropertiesCheckCallbacks() {
        var a = new Euler();
        a._onChange(function() { trace("set: onChange called"); });

        a.x = 1;
        a.y = 2;
        a.z = 3;
        a.order = "ZYX";

        trace(a.x == 1 ? "get: check x" : "Failed!");
        trace(a.y == 2 ? "get: check y" : "Failed!");
        trace(a.z == 3 ? "get: check z" : "Failed!");
        trace(a.order == "ZYX" ? "get: check order" : "Failed!");
    }

    public function testCloneCopyCheckCallbacks() {
        var a = new Euler(1, 2, 3, "ZXY");
        var b = new Euler(4, 5, 6, "XZY");

        var cbSucceed = function() { trace("onChange called"); };
        var cbFail = function() { trace("Failed!"); };

        a._onChange(cbFail);
        b._onChange(cbFail);

        a = b.clone();
        trace(a.equals(b) ? "clone: check if a equals b" : "Failed!");

        a = new Euler(1, 2, 3, "ZXY");
        a._onChange(cbSucceed);
        a.copy(b);
        trace(a.equals(b) ? "copy: check if a equals b" : "Failed!");
    }

    public function testToArray() {
        var order = "YXZ";
        var a = new Euler(MathConstants.x, MathConstants.y, MathConstants.z, order);

        var array = a.toArray();
        trace(array[0] == MathConstants.x ? "No array, no offset: check x" : "Failed!");
        trace(array[1] == MathConstants.y ? "No array, no offset: check y" : "Failed!");
        trace(array[2] == MathConstants.z ? "No array, no offset: check z" : "Failed!");
        trace(array[3] == order ? "No array, no offset: check order" : "Failed!");

        array = [];
        a.toArray(array);
        trace(array[0] == MathConstants.x ? "With array, no offset: check x" : "Failed!");
        trace(array[1] == MathConstants.y ? "With array, no offset: check y" : "Failed!");
        trace(array[2] == MathConstants.z ? "With array, no offset: check z" : "Failed!");
        trace(array[3] == order ? "With array, no offset: check order" : "Failed!");

        array = [];
        a.toArray(array, 1);
        trace(array[0] == null ? "With array and offset: check [0]" : "Failed!");
        trace(array[1] == MathConstants.x ? "With array and offset: check x" : "Failed!");
        trace(array[2] == MathConstants.y ? "With array and offset: check y" : "Failed!");
        trace(array[3] == MathConstants.z ? "With array and offset: check z" : "Failed!");
        trace(array[4] == order ? "With array and offset: check order" : "Failed!");
    }

    public function testFromArray() {
        var a = new Euler();
        var array = [MathConstants.x, MathConstants.y, MathConstants.z];
        var cb = function() { trace("onChange called"); };

        a._onChange(cb);

        a.fromArray(array);
        trace(a.x == MathConstants.x ? "No order: check x" : "Failed!");
        trace(a.y == MathConstants.y ? "No order: check y" : "Failed!");
        trace(a.z == MathConstants.z ? "No order: check z" : "Failed!");
        trace(a.order == "XYZ" ? "No order: check order" : "Failed!");

        a = new Euler();
        array = [MathConstants.x, MathConstants.y, MathConstants.z, "ZXY"];
        a._onChange(cb);
        a.fromArray(array);
        trace(a.x == MathConstants.x ? "With order: check x" : "Failed!");
        trace(a.y == MathConstants.y ? "With order: check y" : "Failed!");
        trace(a.z == MathConstants.z ? "With order: check z" : "Failed!");
        trace(a.order == "ZXY" ? "With order: check order" : "Failed!");
    }

    public function test_onChange() {
        var a = new Euler(11, 12, 13, "XYZ");
        a._onChange(function() {});
        trace(a._onChangeCallback != null ? "Passed!" : "Failed!");
    }

    public function test_onChangeCallback() {
        var b = false;
        var a = new Euler(11, 12, 13, "XYZ");
        var f = function() {
            b = true;
            trace(this === a ? "Passed!" : "Failed!");
        };

        a._onChangeCallback = f;
        trace(a._onChangeCallback === f ? "Passed!" : "Failed!");

        a._onChangeCallback();
        trace(b ? "Passed!" : "Failed!");
    }

    public function testIterable() {
        var e = new Euler(0.5, 0.75, 1, "YZX");
        var array = Type.createEmptyInstance(Array<Dynamic>, [0.5, 0.75, 1, "YZX"]);
        trace(array[0] == 0.5 ? "Euler is iterable." : "Failed!");
        trace(array[1] == 0.75 ? "Euler is iterable." : "Failed!");
        trace(array[2] == 1 ? "Euler is iterable." : "Failed!");
        trace(array[3] == "YZX" ? "Euler is iterable." : "Failed!");
    }
}