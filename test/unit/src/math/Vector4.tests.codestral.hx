import three.math.Vector4;
import three.math.Matrix4;
import three.core.BufferAttribute;

class Vector4Tests {
    public function new() {
        instancing();
        isVector4();
        set();
        setX();
        setY();
        setZ();
        setW();
        copy();
        add();
        addVectors();
        addScaledVector();
        sub();
        subVectors();
        applyMatrix4();
        clone();
        negate();
        dot();
        manhattanLength();
        normalize();
        setLength();
        equals();
        fromArray();
        toArray();
        fromBufferAttribute();
        setComponent();
        getComponent();
        setScalar();
        addScalar();
        subScalar();
        multiplyScalar();
        divideScalar();
        min();
        max();
        clamp();
        clampScalar();
        lengthSq();
        length();
        iterable();
    }

    private function instancing():Void {
        var a = new Vector4();
        trace(a.x == 0, 'Passed!');
        trace(a.y == 0, 'Passed!');
        trace(a.z == 0, 'Passed!');
        trace(a.w == 1, 'Passed!');

        a = new Vector4(x, y, z, w);
        trace(a.x == x, 'Passed!');
        trace(a.y == y, 'Passed!');
        trace(a.z == z, 'Passed!');
        trace(a.w == w, 'Passed!');
    }

    private function isVector4():Void {
        var object = new Vector4();
        trace(object.isVector4, 'Vector4.isVector4 should be true');
    }

    private function set():Void {
        var a = new Vector4();
        trace(a.x == 0, 'Passed!');
        trace(a.y == 0, 'Passed!');
        trace(a.z == 0, 'Passed!');
        trace(a.w == 1, 'Passed!');

        a.set(x, y, z, w);
        trace(a.x == x, 'Passed!');
        trace(a.y == y, 'Passed!');
        trace(a.z == z, 'Passed!');
        trace(a.w == w, 'Passed!');
    }

    private function setX():Void {
        var a = new Vector4();
        trace(a.x == 0, 'Passed!');

        a.setX(x);
        trace(a.x == x, 'Passed!');
    }

    private function setY():Void {
        var a = new Vector4();
        trace(a.y == 0, 'Passed!');

        a.setY(y);
        trace(a.y == y, 'Passed!');
    }

    private function setZ():Void {
        var a = new Vector4();
        trace(a.z == 0, 'Passed!');

        a.setZ(z);
        trace(a.z == z, 'Passed!');
    }

    private function setW():Void {
        var a = new Vector4();
        trace(a.w == 1, 'Passed!');

        a.setW(w);
        trace(a.w == w, 'Passed!');
    }

    private function copy():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4().copy(a);
        trace(b.x == x, 'Passed!');
        trace(b.y == y, 'Passed!');
        trace(b.z == z, 'Passed!');
        trace(b.w == w, 'Passed!');

        a.x = 0;
        a.y = -1;
        a.z = -2;
        a.w = -3;
        trace(b.x == x, 'Passed!');
        trace(b.y == y, 'Passed!');
        trace(b.z == z, 'Passed!');
        trace(b.w == w, 'Passed!');
    }

    private function add():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.add(b);
        trace(a.x == 0, 'Passed!');
        trace(a.y == 0, 'Passed!');
        trace(a.z == 0, 'Passed!');
        trace(a.w == 0, 'Passed!');
    }

    private function addVectors():Void {
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4().addVectors(b, b);

        trace(c.x == -2 * x, 'Passed!');
        trace(c.y == -2 * y, 'Passed!');
        trace(c.z == -2 * z, 'Passed!');
        trace(c.w == -2 * w, 'Passed!');
    }

    private function addScaledVector():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(6, 7, 8, 9);
        var s = 3;

        a.addScaledVector(b, s);
        trace(a.x == x + b.x * s, 'Check x');
        trace(a.y == y + b.y * s, 'Check y');
        trace(a.z == z + b.z * s, 'Check z');
        trace(a.w == w + b.w * s, 'Check w');
    }

    private function sub():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.sub(b);
        trace(a.x == 2 * x, 'Passed!');
        trace(a.y == 2 * y, 'Passed!');
        trace(a.z == 2 * z, 'Passed!');
        trace(a.w == 2 * w, 'Passed!');
    }

    private function subVectors():Void {
        var a = new Vector4(x, y, z, w);
        var c = new Vector4().subVectors(a, a);
        trace(c.x == 0, 'Passed!');
        trace(c.y == 0, 'Passed!');
        trace(c.z == 0, 'Passed!');
        trace(c.w == 0, 'Passed!');
    }

    private function applyMatrix4():Void {
        var a = new Vector4(x, y, z, w);
        var m = new Matrix4().makeRotationX(Math.PI);
        var expected = new Vector4(2, -3, -4, 5);

        a.applyMatrix4(m);
        trace(Math.abs(a.x - expected.x) <= eps, 'Rotation matrix: check x');
        trace(Math.abs(a.y - expected.y) <= eps, 'Rotation matrix: check y');
        trace(Math.abs(a.z - expected.z) <= eps, 'Rotation matrix: check z');
        trace(Math.abs(a.w - expected.w) <= eps, 'Rotation matrix: check w');

        a.set(x, y, z, w);
        m.makeTranslation(5, 7, 11);
        expected.set(27, 38, 59, 5);

        a.applyMatrix4(m);
        trace(Math.abs(a.x - expected.x) <= eps, 'Translation matrix: check x');
        trace(Math.abs(a.y - expected.y) <= eps, 'Translation matrix: check y');
        trace(Math.abs(a.z - expected.z) <= eps, 'Translation matrix: check z');
        trace(Math.abs(a.w - expected.w) <= eps, 'Translation matrix: check w');

        a.set(x, y, z, w);
        m.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0);
        expected.set(2, 3, 4, 4);

        a.applyMatrix4(m);
        trace(Math.abs(a.x - expected.x) <= eps, 'Custom matrix: check x');
        trace(Math.abs(a.y - expected.y) <= eps, 'Custom matrix: check y');
        trace(Math.abs(a.z - expected.z) <= eps, 'Custom matrix: check z');
        trace(Math.abs(a.w - expected.w) <= eps, 'Custom matrix: check w');

        a.set(x, y, z, w);
        m.set(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53);
        expected.set(68, 224, 442, 664);

        a.applyMatrix4(m);
        trace(Math.abs(a.x - expected.x) <= eps, 'Bogus matrix: check x');
        trace(Math.abs(a.y - expected.y) <= eps, 'Bogus matrix: check y');
        trace(Math.abs(a.z - expected.z) <= eps, 'Bogus matrix: check z');
        trace(Math.abs(a.w - expected.w) <= eps, 'Bogus matrix: check w');
    }

    private function clone():Void {
        var a = new Vector4(x, y, z, w);
        var b = a.clone();
        trace(b.x == x, 'Passed!');
        trace(b.y == y, 'Passed!');
        trace(b.z == z, 'Passed!');
        trace(b.w == w, 'Passed!');
    }

    private function negate():Void {
        var a = new Vector4(x, y, z, w);

        a.negate();
        trace(a.x == -x, 'Passed!');
        trace(a.y == -y, 'Passed!');
        trace(a.z == -z, 'Passed!');
        trace(a.w == -w, 'Passed!');
    }

    private function dot():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4(0, 0, 0, 0);

        var result = a.dot(b);
        trace(result == -(x * x + y * y + z * z + w * w), 'Passed!');

        result = a.dot(c);
        trace(result == 0, 'Passed!');
    }

    private function manhattanLength():Void {
        var a = new Vector4(x, 0, 0, 0);
        var b = new Vector4(0, -y, 0, 0);
        var c = new Vector4(0, 0, z, 0);
        var d = new Vector4(0, 0, 0, w);
        var e = new Vector4(0, 0, 0, 0);

        trace(a.manhattanLength() == x, 'Positive x');
        trace(b.manhattanLength() == y, 'Negative y');
        trace(c.manhattanLength() == z, 'Positive z');
        trace(d.manhattanLength() == w, 'Positive w');
        trace(e.manhattanLength() == 0, 'Empty initialization');

        a.set(x, y, z, w);
        trace(a.manhattanLength() == Math.abs(x) + Math.abs(y) + Math.abs(z) + Math.abs(w), 'All components');
    }

    private function normalize():Void {
        var a = new Vector4(x, 0, 0, 0);
        var b = new Vector4(0, -y, 0, 0);
        var c = new Vector4(0, 0, z, 0);
        var d = new Vector4(0, 0, 0, -w);

        a.normalize();
        trace(a.length() == 1, 'Passed!');
        trace(a.x == 1, 'Passed!');

        b.normalize();
        trace(b.length() == 1, 'Passed!');
        trace(b.y == -1, 'Passed!');

        c.normalize();
        trace(c.length() == 1, 'Passed!');
        trace(c.z == 1, 'Passed!');

        d.normalize();
        trace(d.length() == 1, 'Passed!');
        trace(d.w == -1, 'Passed!');
    }

    private function setLength():Void {
        var a = new Vector4(x, 0, 0, 0);

        trace(a.length() == x, 'Passed!');
        a.setLength(y);
        trace(a.length() == y, 'Passed!');

        a = new Vector4(0, 0, 0, 0);
        trace(a.length() == 0, 'Passed!');
        a.setLength(y);
        trace(a.length() == 0, 'Passed!');
    }

    private function equals():Void {
        var a = new Vector4(x, 0, z, 0);
        var b = new Vector4(0, -y, 0, -w);

        trace(a.x != b.x, 'Passed!');
        trace(a.y != b.y, 'Passed!');
        trace(a.z != b.z, 'Passed!');
        trace(a.w != b.w, 'Passed!');

        trace(!a.equals(b), 'Passed!');
        trace(!b.equals(a), 'Passed!');

        a.copy(b);
        trace(a.x == b.x, 'Passed!');
        trace(a.y == b.y, 'Passed!');
        trace(a.z == b.z, 'Passed!');
        trace(a.w == b.w, 'Passed!');

        trace(a.equals(b), 'Passed!');
        trace(b.equals(a), 'Passed!');
    }

    private function fromArray():Void {
        var a = new Vector4();
        var array = [1, 2, 3, 4, 5, 6, 7, 8];

        a.fromArray(array);
        trace(a.x == 1, 'No offset: check x');
        trace(a.y == 2, 'No offset: check y');
        trace(a.z == 3, 'No offset: check z');
        trace(a.w == 4, 'No offset: check w');

        a.fromArray(array, 4);
        trace(a.x == 5, 'With offset: check x');
        trace(a.y == 6, 'With offset: check y');
        trace(a.z == 7, 'With offset: check z');
        trace(a.w == 8, 'With offset: check w');
    }

    private function toArray():Void {
        var a = new Vector4(x, y, z, w);

        var array = a.toArray();
        trace(array[0] == x, 'No array, no offset: check x');
        trace(array[1] == y, 'No array, no offset: check y');
        trace(array[2] == z, 'No array, no offset: check z');
        trace(array[3] == w, 'No array, no offset: check w');

        array = [];
        a.toArray(array);
        trace(array[0] == x, 'With array, no offset: check x');
        trace(array[1] == y, 'With array, no offset: check y');
        trace(array[2] == z, 'With array, no offset: check z');
        trace(array[3] == w, 'With array, no offset: check w');

        array = [];
        a.toArray(array, 1);
        trace(array[0] == null, 'With array and offset: check [0]');
        trace(array[1] == x, 'With array and offset: check x');
        trace(array[2] == y, 'With array and offset: check y');
        trace(array[3] == z, 'With array and offset: check z');
        trace(array[4] == w, 'With array and offset: check w');
    }

    private function fromBufferAttribute():Void {
        var a = new Vector4();
        var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6, 7, 8]), 4);

        a.fromBufferAttribute(attr, 0);
        trace(a.x == 1, 'Offset 0: check x');
        trace(a.y == 2, 'Offset 0: check y');
        trace(a.z == 3, 'Offset 0: check z');
        trace(a.w == 4, 'Offset 0: check w');

        a.fromBufferAttribute(attr, 1);
        trace(a.x == 5, 'Offset 1: check x');
        trace(a.y == 6, 'Offset 1: check y');
        trace(a.z == 7, 'Offset 1: check z');
        trace(a.w == 8, 'Offset 1: check w');
    }

    private function setComponent():Void {
        var a = new Vector4();
        trace(a.x == 0, 'Passed!');
        trace(a.y == 0, 'Passed!');
        trace(a.z == 0, 'Passed!');
        trace(a.w == 1, 'Passed!');

        a.setComponent(0, 1);
        a.setComponent(1, 2);
        a.setComponent(2, 3);
        a.setComponent(3, 4);
        trace(a.getComponent(0) == 1, 'Passed!');
        trace(a.getComponent(1) == 2, 'Passed!');
        trace(a.getComponent(2) == 3, 'Passed!');
        trace(a.getComponent(3) == 4, 'Passed!');
    }

    private function getComponent():Void {
        var a = new Vector4();
        trace(a.x == 0, 'Passed!');
        trace(a.y == 0, 'Passed!');
        trace(a.z == 0, 'Passed!');
        trace(a.w == 1, 'Passed!');

        a.setComponent(0, 1);
        a.setComponent(1, 2);
        a.setComponent(2, 3);
        a.setComponent(3, 4);
        trace(a.getComponent(0) == 1, 'Passed!');
        trace(a.getComponent(1) == 2, 'Passed!');
        trace(a.getComponent(2) == 3, 'Passed!');
        trace(a.getComponent(3) == 4, 'Passed!');
    }

    private function setScalar():Void {
        var a = new Vector4();
        var s = 3;

        a.setScalar(s);
        trace(a.x == s, 'setScalar: check x');
        trace(a.y == s, 'setScalar: check y');
        trace(a.z == s, 'setScalar: check z');
        trace(a.w == s, 'setScalar: check w');
    }

    private function addScalar():Void {
        var a = new Vector4();
        var s = 3;

        a.setScalar(s);
        a.addScalar(s);
        trace(a.x == 2 * s, 'addScalar: check x');
        trace(a.y == 2 * s, 'addScalar: check y');
        trace(a.z == 2 * s, 'addScalar: check z');
        trace(a.w == 2 * s, 'addScalar: check w');
    }

    private function subScalar():Void {
        var a = new Vector4();
        var s = 3;

        a.setScalar(2 * s);
        a.subScalar(2 * s);
        trace(a.x == 0, 'subScalar: check x');
        trace(a.y == 0, 'subScalar: check y');
        trace(a.z == 0, 'subScalar: check z');
        trace(a.w == 0, 'subScalar: check w');
    }

    private function multiplyScalar():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.multiplyScalar(-2);
        trace(a.x == x * -2, 'Passed!');
        trace(a.y == y * -2, 'Passed!');
        trace(a.z == z * -2, 'Passed!');
        trace(a.w == w * -2, 'Passed!');

        b.multiplyScalar(-2);
        trace(b.x == 2 * x, 'Passed!');
        trace(b.y == 2 * y, 'Passed!');
        trace(b.z == 2 * z, 'Passed!');
        trace(b.w == 2 * w, 'Passed!');
    }

    private function divideScalar():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.multiplyScalar(-2);
        a.divideScalar(-2);
        trace(a.x == x, 'Passed!');
        trace(a.y == y, 'Passed!');
        trace(a.z == z, 'Passed!');
        trace(a.w == w, 'Passed!');

        b.multiplyScalar(-2);
        b.divideScalar(-2);
        trace(b.x == -x, 'Passed!');
        trace(b.y == -y, 'Passed!');
        trace(b.z == -z, 'Passed!');
        trace(b.w == -w, 'Passed!');
    }

    private function min():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4();

        c.copy(a).min(b);
        trace(c.x == -x, 'Passed!');
        trace(c.y == -y, 'Passed!');
        trace(c.z == -z, 'Passed!');
        trace(c.w == -w, 'Passed!');
    }

    private function max():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4();

        c.copy(a).max(b);
        trace(c.x == x, 'Passed!');
        trace(c.y == y, 'Passed!');
        trace(c.z == z, 'Passed!');
        trace(c.w == w, 'Passed!');
    }

    private function clamp():Void {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4();

        c.set(-2 * x, 2 * y, -2 * z, 2 * w);
        c.clamp(b, a);
        trace(c.x == -x, 'Passed!');
        trace(c.y == y, 'Passed!');
        trace(c.z == -z, 'Passed!');
        trace(c.w == w, 'Passed!');
    }

    private function clampScalar():Void {
        var a = new Vector4(-0.1, 0.01, 0.5, 1.5);
        var clamped = new Vector4(0.1, 0.1, 0.5, 1.0);

        a.clampScalar(0.1, 1.0);
        trace(Math.abs(a.x - clamped.x) <= eps, 'Check x');
        trace(Math.abs(a.y - clamped.y) <= eps, 'Check y');
        trace(Math.abs(a.z - clamped.z) <= eps, 'Check z');
        trace(Math.abs(a.w - clamped.w) <= eps, 'Check w');
    }

    private function lengthSq():Void {
        var a = new Vector4(x, 0, 0, 0);
        var b = new Vector4(0, -y, 0, 0);
        var c = new Vector4(0, 0, z, 0);
        var d = new Vector4(0, 0, 0, w);
        var e = new Vector4(0, 0, 0, 0);

        trace(a.lengthSq() == x * x, 'Passed!');
        trace(b.lengthSq() == y * y, 'Passed!');
        trace(c.lengthSq() == z * z, 'Passed!');
        trace(d.lengthSq() == w * w, 'Passed!');
        trace(e.lengthSq() == 0, 'Passed!');

        a.set(x, y, z, w);
        trace(a.lengthSq() == (x * x + y * y + z * z + w * w), 'Passed!');
    }

    private function length():Void {
        var a = new Vector4(x, 0, 0, 0);
        var b = new Vector4(0, -y, 0, 0);
        var c = new Vector4(0, 0, z, 0);
        var d = new Vector4(0, 0, 0, w);
        var e = new Vector4(0, 0, 0, 0);

        trace(a.length() == x, 'Passed!');
        trace(b.length() == y, 'Passed!');
        trace(c.length() == z, 'Passed!');
        trace(d.length() == w, 'Passed!');
        trace(e.length() == 0, 'Passed!');

        a.set(x, y, z, w);
        trace(a.length() == Math.sqrt(x * x + y * y + z * z + w * w), 'Passed!');
    }

    private function iterable():Void {
        var v = new Vector4(0, 0.3, 0.7, 1);
        var array = [for (i in v) i];
        trace(array[0] == 0, 'Vector4 is iterable.');
        trace(array[1] == 0.3, 'Vector4 is iterable.');
        trace(array[2] == 0.7, 'Vector4 is iterable.');
        trace(array[3] == 1, 'Vector4 is iterable.');
    }
}