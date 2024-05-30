import Math.Vector2;
import Math.Matrix3;
import js.BufferAttribute;

class Vector2Test {
    static function instancing() {
        var a = new Vector2();
        trace("Instancing: " + (a.x == 0) + ", " + (a.y == 0));

        a = new Vector2(1, 2);
        trace("Instancing: " + (a.x == 1) + ", " + (a.y == 2));
    }

    static function properties() {
        var a = new Vector2(0, 0);
        var width = 100;
        var height = 200;

        trace("Properties: " + (a.width = width) + ", " + (a.height = height));

        a.set(width, height);
        trace("Properties: " + (a.width == width) + ", " + (a.height == height));
    }

    static function isVector2() {
        var object = new Vector2();
        trace("isVector2: " + object.isVector2);
    }

    static function set() {
        var a = new Vector2();
        trace("Set: " + (a.x == 0) + ", " + (a.y == 0));

        a.set(1, 2);
        trace("Set: " + (a.x == 1) + ", " + (a.y == 2));
    }

    static function copy() {
        var a = new Vector2(1, 2);
        var b = new Vector2().copy(a);
        trace("Copy: " + (b.x == 1) + ", " + (b.y == 2));

        a.x = 0;
        a.y = -1;
        trace("Copy: " + (b.x == 1) + ", " + (b.y == 2));
    }

    static function add() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);

        a.add(b);
        trace("Add: " + (a.x == 0) + ", " + (a.y == 0));

        var c = new Vector2().addVectors(b, b);
        trace("Add: " + (c.x == -2) + ", " + (c.y == -4));
    }

    static function addScaledVector() {
        var a = new Vector2(1, 2);
        var b = new Vector2(2, 3);
        var s = 3;

        a.addScaledVector(b, s);
        trace("AddScaledVector: " + (a.x == 7) + ", " + (a.y == 9));
    }

    static function sub() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);

        a.sub(b);
        trace("Sub: " + (a.x == 2) + ", " + (a.y == 4));

        var c = new Vector2().subVectors(a, a);
        trace("Sub: " + (c.x == 0) + ", " + (c.y == 0));
    }

    static function applyMatrix3() {
        var a = new Vector2(1, 2);
        var m = new Matrix3().set(2, 3, 5, 7, 11, 13, 17, 19, 23);

        a.applyMatrix3(m);
        trace("ApplyMatrix3: " + (a.x == 18) + ", " + (a.y == 60));
    }

    static function negate() {
        var a = new Vector2(1, 2);

        a.negate();
        trace("Negate: " + (a.x == -1) + ", " + (a.y == -2));
    }

    static function dot() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);
        var c = new Vector2();

        var result = a.dot(b);
        trace("Dot: " + (result == -5));

        result = a.dot(c);
        trace("Dot: " + (result == 0));
    }

    static function cross() {
        var a = new Vector2(1, 2);
        var b = new Vector2(2, -1);
        var answer = -6;
        var crossed = a.cross(b);

        trace("Cross: " + (Math.abs(answer - crossed) <= 0.000001));
    }

    static function normalize() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);

        a.normalize();
        trace("Normalize: " + (a.length() == 1) + ", " + (a.x == 1));

        b.normalize();
        trace("Normalize: " + (b.length() == 1) + ", " + (b.y == -1));
    }

    static function angleTo() {
        var a = new Vector2(-0.18851655680720186, 0.9820700116639124);
        var b = new Vector2(0.18851655680720186, -0.9820700116639124);

        trace("AngleTo: " + (a.angleTo(a) == 0) + ", " + (a.angleTo(b) == Math.PI));

        var x = new Vector2(1, 0);
        var y = new Vector2(0, 1);

        trace("AngleTo: " + (x.angleTo(y) == Math.PI / 2) + ", " + (y.angleTo(x) == Math.PI / 2));

        trace("AngleTo: " + (Math.abs(x.angleTo(new Vector2(1, 1)) - (Math.PI / 4)) < 0.000001));
    }

    static function setLength() {
        var a = new Vector2(1, 0);

        trace("SetLength: " + (a.length() == 1));
        a.setLength(2);
        trace("SetLength: " + (a.length() == 2));

        a = new Vector2(0, 0);
        trace("SetLength: " + (a.length() == 0));
        a.setLength(2);
        trace("SetLength: " + (a.length() == 0));
        a.setLength();
        trace("SetLength: " + (isNaN(a.length())));
    }

    static function equals() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);

        trace("Equals: " + (a.x != b.x) + ", " + (a.y != b.y));

        trace("Equals: " + (!a.equals(b)) + ", " + (!b.equals(a)));

        a.copy(b);
        trace("Equals: " + (a.x == b.x) + ", " + (a.y == b.y));

        trace("Equals: " + a.equals(b) + ", " + b.equals(a));
    }

    static function fromArray() {
        var a = new Vector2();
        var array = [1, 2, 3, 4];

        a.fromArray(array);
        trace("FromArray: " + (a.x == 1) + ", " + (a.y == 2));

        a.fromArray(array, 2);
        trace("FromArray: " + (a.x == 3) + ", " + (a.y == 4));
    }

    static function toArray() {
        var a = new Vector2(1, 2);

        var array = a.toArray();
        trace("ToArray: " + (array[0] == 1) + ", " + (array[1] == 2));

        array = [];
        a.toArray(array);
        trace("ToArray: " + (array[0] == 1) + ", " + (array[1] == 2));

        array = [];
        a.toArray(array, 1);
        trace("ToArray: " + (array[0] == null) + ", " + (array[1] == 1) + ", " + (array[2] == 2));
    }

    static function fromBufferAttribute() {
        var a = new Vector2();
        var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4]), 2);

        a.fromBufferAttribute(attr, 0);
        trace("FromBufferAttribute: " + (a.x == 1) + ", " + (a.y == 2));

        a.fromBufferAttribute(attr, 1);
        trace("FromBufferAttribute: " + (a.x == 3) + ", " + (a.y == 4));
    }

    static function setXSetY() {
        var a = new Vector2();
        trace("SetXSetY: " + (a.x == 0) + ", " + (a.y == 0));

        a.setX(1);
        a.setY(2);
        trace("SetXSetY: " + (a.x == 1) + ", " + (a.y == 2));
    }

    static function setComponentGetComponent() {
        var a = new Vector2();
        trace("SetComponentGetComponent: " + (a.x == 0) + ", " + (a.y == 0));

        a.setComponent(0, 1);
        a.setComponent(1, 2);
        trace("SetComponentGetComponent: " + (a.getComponent(0) == 1) + ", " + (a.getComponent(1) == 2));
    }

    static function multiplyDivide() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);

        a.multiplyScalar(-2);
        trace("MultiplyDivide: " + (a.x == -2) + ", " + (a.y == -4));

        b.multiplyScalar(-2);
        trace("MultiplyDivide: " + (b.x == 2) + ", " + (b.y == 4));

        a.divideScalar(-2);
        trace("MultiplyDivide: " + (a.x == 1) + ", " + (a.y == 2));

        b.divideScalar(-2);
        trace("MultiplyDivide: " + (b.x == -1) + ", " + (b.y == -2));
    }

    static function minMaxClamp() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);
        var c = new Vector2();

        c.copy(a).min(b);
        trace("MinMaxClamp: " + (c.x == -1) + ", " + (c.y == -2));

        c.copy(a).max(b);
        trace("MinMaxClamp: " + (c.x == 1) + ", " + (c.y == 2));

        c.set(-2, 2);
        c.clamp(b, a);
        trace("MinMaxClamp: " + (c.x == -1) + ", " + (c.y == 2));

        c.set(-2, 2);
        c.clampScalar(-1, 1);
        trace("MinMaxClamp: " + (c.x == -1) + ", " + (c.y == 1));
    }

    static function rounding() {
        trace("Rounding: " + new Vector2(-0.1, 0.1).floor() == new Vector2(-1, 0));
        trace("Rounding: " + new Vector2(-0.5, 0.5).floor() == new Vector2(-1, 0));
        trace("Rounding: " + new Vector2(-0.9, 0.9).floor() == new Vector2(-1, 0));

        trace("Rounding: " + new Vector2(-0.1, 0.1).ceil() == new Vector2(0, 1));
        trace("Rounding: " + new Vector2(-0.5, 0.5).ceil() == new Vector2(0, 1));
        trace("Rounding: " + new Vector2(-0.9, 0.9).ceil() == new Vector2(0, 1));

        trace("Rounding: " + new Vector2(-0.1, 0.1).round() == new Vector2(0, 0));
        trace("Rounding: " + new Vector2(-0.5, 0.5).round() == new Vector2(0, 1));
        trace("Rounding: " + new Vector2(-0.9, 0.9).round() == new Vector2(-1, 1));

        trace("Rounding: " + new Vector2(-0.1, 0.1).roundToZero() == new Vector2(0, 0));
        trace("Rounding: " + new Vector2(-0.5, 0.5).roundToZero() == new Vector2(0, 0));
        trace("Rounding: " + new Vector2(-0.9, 0.9).roundToZero() == new Vector2(0, 0));
        trace("Rounding: " + new Vector2(-1.1, 1.1).roundToZero() == new Vector2(-1, 1));
        trace("Rounding: " + new Vector2(-1.5, 1.5).roundToZero() == new Vector2(-1, 1));
        trace("Rounding: " + new Vector2(-1.9, 1.9).roundToZero() == new Vector2(-1, 1));
    }

    static function lengthLengthSq() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);
        var c = new Vector2();

        trace("LengthLengthSq: " + (a.length() == 1) + ", " + (a.lengthSq() == 1));
        trace("LengthLengthSq: " + (b.length() == 2) + ", " + (b.lengthSq() == 4));
        trace("LengthLengthSq: " + (c.length() == 0) + ", " + (c.lengthSq() == 0));

        a.set(1, 2);
        trace("LengthLengthSq: " + (a.length() == Math.sqrt(5)) + ", " + (a.lengthSq() == 5));
    }

    static function distanceToDistanceToSquared() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);
        var c = new Vector2();

        trace("DistanceToDistanceToSquared: " + (a.distanceTo(c) == 1) + ", " + (a.distanceToSquared(c) == 1));

        trace("DistanceToDistanceToSquared: " + (b.distanceTo(c) == 2) + ", " + (b.distanceToSquared(c) == 4));
    }

    static function lerpClone() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);

        trace("LerpClone: " + a.lerp(a, 0).equals(a.lerp(a, 0.5)));
        trace("LerpClone: " + a.lerp(a, 0).equals(a.lerp(a, 1)));

        trace("LerpClone: " + a.clone().lerp(b, 0).equals(a));

        trace("LerpClone: " + a.clone().lerp(b, 0.5).x == 0.5);
        trace("LerpClone: " + a.clone().lerp(b, 0.5).y == -1);

        trace("LerpClone: " + a.clone().lerp(b, 1).equals(b));
    }

    static function setComponentGetComponentExceptions() {
        var a = new Vector2(0, 0);

        trace("SetComponentGetComponentExceptions: " + (function() { a.setComponent(2, 0); } throws Error));
        trace("SetComponentGetComponentExceptions: " + (function() { a.getComponent(2); } throws Error));
    }

    static function setScalarAddScalarSubScalar() {
        var a = new Vector2(1, 1);
        var s = 3;

        a.setScalar(s);
        trace("SetScalarAddScalarSubScalar: " + (a.x == s) + ", " + (a.y == s));

        a.addScalar(s);
        trace("SetScalarAddScalarSubScalar: " + (a.x == 2 * s) + ", " + (a.y == 2 * s));

        a.subScalar(2 * s);
        trace("SetScalarAddScalarSubScalar: " + (a.x == 0) + ", " + (a.y == 0));
    }

    static function multiplyDivide() {
        var a = new Vector2(1, 2);
        var b = new Vector2(2, 4);
        var c = new Vector2(4, 8
);

a.multiply(b);
trace("MultiplyDivide: " + (a.x == b.x) + ", " + (a.y == b.y));

b.divide(c);
trace("MultiplyDivide: " + (b.x == 0.5) + ", " + (b.y == 0.5));
}

static function iterable() {
var v = new Vector2(0, 1);
var array = [ ...v ];
trace("Iterable: " + (array[0] == 0) + ", " + (array[1] == 1));
}

static public function main() {
instancing();
properties();
isVector2();
set();
copy();
add();
addScaledVector();
sub();
applyMatrix3();
negate();
dot();
cross();
normalize();
angleTo();
setLength();
equals();
fromArray();
toArray();
fromBufferAttribute();
setXSetY();
setComponentGetComponent();
multiplyDivide();
minMaxClamp();
rounding();
lengthLengthSq();
distanceToDistanceToSquared();
lerpClone();
setComponentGetComponentExceptions();
setScalarAddScalarSubScalar();
multiplyDivide();
iterable();
}
}

var x = new Vector2Test();
x.main();