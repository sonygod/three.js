import js.Browser;
import js.html.CanvasElement;
import js.html.Document;
import js.html.HtmlElement;
import js.html.Window;
import js.lib.Mathf;
import js.node.Node;
import js.node.NodeJs;
import js.sys.ArrayBuffer;
import js.sys.ArrayBuffers;
import js.sys.Console;
import js.sys.Reflect;
import js.sys.Sys;
import js.utime.UTime;

class Vector4 {
    public var x: Float;
    public var y: Float;
    public var z: Float;
    public var w: Float;
    public function new(?x: Float, ?y: Float, ?z: Float, ?w: Float) {
        this.x = x ?? 0.0;
        this.y = y ?? 0.0;
        this.z = z ?? 0.0;
        this.w = w ?? 1.0;
    }
    public function set(x: Float, y: Float, z: Float, w: Float): Void {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }
    public function setX(x: Float): Void {
        this.x = x;
    }
    public function setY(y: Float): Void {
        this.y = y;
    }
    public function setZ(z: Float): Void {
        this.z = z;
    }
    public function setW(w: Float): Void {
        this.w = w;
    }
    public function add(a: Vector4): Void {
        this.x += a.x;
        this.y += a.y;
        this.z += a.z;
        this.w += a.w;
    }
    public function addScaledVector(a: Vector4, s: Float): Void {
        this.x += a.x * s;
        this.y += a.y * s;
        this.z += a.z * s;
        this.w += a.w * s;
    }
    public function sub(a: Vector4): Void {
        this.x -= a.x;
        this.y -= a.y;
        this.z -= a.z;
        this.w -= a.w;
    }
    public function subVectors(a: Vector4, b: Vector4): Void {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
        this.z = a.z - b.z;
        this.w = a.w - b.w;
    }
    public function applyMatrix4(m: Matrix4): Void {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var w = this.w;
        var e = m.elements;
        this.x = e[0] * x + e[4] * y + e[8] * z + e[12] * w;
        this.y = e[1] * x + e[5] * y + e[9] * z + e[13] * w;
        this.z = e[2] * x + e[6] * y + e[10] * z + e[14] * w;
        this.w = e[3] * x + e[7] * y + e[11] * z + e[15] * w;
    }
    public function negate(): Void {
        this.x = -this.x;
        this.y = -this.y;
        this.z = -this.z;
        this.w = -this.w;
    }
    public function dot(v: Vector4): Float {
        return this.x * v.x + this.y * v.y + this.z * v.z + this.w * v.w;
    }
    public function manhattanLength(): Float {
        return Mathf.abs(this.x) + Mathf.abs(this.y) + Mathf.abs(this.z) + Mathf.abs(this.w);
    }
    public function normalize(): Void {
        var l = this.length();
        if (l == 0.0) {
            return;
        }
        this.x /= l;
        this.y /= l;
        this.z /= l;
        this.w /= l;
    }
    public function setLength(l: Float): Void {
        var length = this.length();
        if (length == 0.0 || l == 0.0) {
            return;
        }
        this.multiplyScalar(l / length);
    }
    public function equals(v: Vector4): Bool {
        return this.x == v.x && this.y == v.y && this.z == v.z && this.w == v.w;
    }
    public function fromArray(array: Array<Float>, ?offset: Int): Void {
        var index = offset ?? 0;
        this.x = array[index];
        this.y = array[index + 1];
        this.z = array[index + 2];
        this.w = array[index + 3];
    }
    public function toArray(?array: Array<Float>, ?offset: Int): Array<Float> {
        array = array ?? [];
        var index = offset ?? 0;
        array[index] = this.x;
        array[index + 1] = this.y;
        array[index + 2] = this.z;
        array[index + 3] = this.w;
        return array;
    }
    public function fromBufferAttribute(attribute: BufferAttribute, index: Int): Void {
        this.x = attribute.getX(index);
        this.y = attribute.getY(index);
        this.z = attribute.getZ(index);
        this.w = attribute.getW(index);
    }
    public function setComponent(index: Int, value: Float): Void {
        switch (index) {
            case 0:
                this.x = value;
                break;
            case 1:
                this.y = value;
                break;
            case 2:
                this.z = value;
                break;
            case 3:
                this.w = value;
                break;
            default:
                throw "index is out of range";
        }
    }
    public function getComponent(index: Int): Float {
        switch (index) {
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            case 3:
                return this.w;
            default:
                throw "index is out of range";
        }
    }
    public function setScalar(scalar: Float): Void {
        this.x = scalar;
        this.y = scalar;
        this.z = scalar;
        this.w = scalar;
    }
    public function addScalar(s: Float): Void {
        this.x += s;
        this.y += s;
        this.z += s;
        this.w += s;
    }
    public function multiplyScalar(s: Float): Void {
        this.x *= s;
        this.y *= s;
        this.z *= s;
        this.w *= s;
    }
    public function divideScalar(s: Float): Void {
        if (s == 0.0) {
            return;
        }
        this.x /= s;
        this.y /= s;
        this.z /= s;
        this.w /= s;
    }
    public function clampScalar(min: Float, max: Float): Void {
        this.x = Mathf.clamp(this.x, min, max);
        this.y = Mathf.clamp(this.y, min, max);
        this.z = Mathf.clamp(this.z, min, max);
        this.w = Mathf.clamp(this.w, min, max);
    }
    public function length(): Float {
        return Mathf.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
    }
    public function lengthSq(): Float {
        return this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w;
    }
    public function lerp(v: Vector4, alpha: Float): Vector4 {
        this.x += (v.x - this.x) * alpha;
        this.y += (v.y - this.y) * alpha;
        this.z += (v.z - this.z) * alpha;
        this.w += (v.w - this.w) * alpha;
        return this;
    }
    public function clone(): Vector4 {
        return new Vector4(this.x, this.y, this.z, this.w);
    }
    public function iterator(): Iterator<Float> {
        return this.toArray().iterator();
    }
}

class Matrix4 {
    public var elements: Array<Float>;
    public function new() {
        this.elements = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];
    }
    public function makeRotationX(theta: Float): Matrix4 {
        var c = Mathf.cos(theta);
        var s = Mathf.sin(theta);
        this.elements[5] = c;
        this.elements[6] = -s;
        this.elements[9] = s;
        this.elements[10] = c;
        return this;
    }
    public function makeTranslation(x: Float, y: Float, z: Float): Matrix4 {
        this.elements[12] = x;
        this.elements[13] = y;
        this.elements[14] = z;
        return this;
    }
}

class BufferAttribute {
    public var itemSize: Int;
    public var array: ArrayBuffer;
    public var count: Int;
    public var normalized: Bool;
    public function new(array: ArrayBuffer, itemSize: Int, ?normalized: Bool) {
        this.array = array;
        this.itemSize = itemSize;
        this.count = array.byteLength / (itemSize * 4);
        this.normalized = normalized ?? false;
    }
    public function getX(index: Int): Float {
        return this.array.getFloat32(index * this.itemSize + 0);
    }
    public function getY(index: Int): Float {
        return this.array.getFloat32(index * this.itemSize + 1);
    }
    public function getZ(index: Int): Float {
        return this.array.getFloat32(index * this.itemSize + 2);
    }
    public function getW(index: Int): Float {
        return this.array.getFloat32(index * this.itemSize + 3);
    }
}

class QUnit {
    public static function module(name: String, callback: Void->Void): Void {
        callback();
    }
    public static function test(name: String, callback: Void->Void): Void {
        callback();
    }
    public static function todo(name: String, callback: Void->Void): Void {
        callback();
    }
}

class MathConstants {
    static public var x: Float = 1.0;
    static public var y: Float = 2.0;
    static public var z: Float = 3.0;
    static public var w: Float = 4.0;
    static public var eps: Float = 0.0001;
}

class TestSuite {
    static public function main(): Void {
        QUnit.module("Maths", {
            QUnit.module("Vector4", {
                QUnit.test("Instancing", {
                    var a = new Vector4();
                    Sys.assert(a.x == 0.0);
                    Sys.assert(a.y == 0.0);
                    Sys.assert(a.z == 0.0);
                    Sys.assert(a.w == 1.0);
                    a = new Vector4(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
                    Sys.assert(a.x == MathConstants.x);
                    Sys.assert(a.y == MathConstants.y);
                    Sys.assert(a.z == MathConstants.z);
                    Sys.assert(a.w == MathConstants.w);
                });
                QUnit.test("isVector4", {
                    var object = new Vector4();
                    Sys.assert(object.isVector4);
                });
                QUnit.test("set", {
                    var a = new Vector4();
                    Sys.assert(a.x == 0.0);
                    Sys.assert(a.y == 0.0);
                    Sys.assert(a.z == 0.0);
                    Sys.assert(a.w == 1.0);
                    a.set(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
                    Sys.assert(a.x == MathConstants.x);
                    Sys.assert(a.y == MathConstants.y);
                    Sys.assert(a.z == MathConstants.z);
                    Sys.assert(a.w == MathConstants.w);
                });
                QUnit.test("setX", {
                    var a = new Vector4();
                    Sys.assert(a.x == 0.0);
                    a.setX(MathConstants.x);
                    Sys.assert(a.x == MathConstants.x);
                });
                QUnit.test("setY", {
                    var a = new Vector4();
                    Sys.assert(a.y == 0.0);
                    a.setY(MathConstants.y);
                    Sys.assert(a.y == MathConstants.y);
                });
                QUnit.test("setZ", {
                    var a = new Vector4();
                    Sys.assert(a.z == 0.0);
                    a.setZ(MathConstants.z);
                    Sys.assert(a.z == MathConstants.z);
                });
                QUnit.test("setW", {
                    var a = new Vector4();
                    Sys.assert(a.w == 1.0);
                    a.setW(MathConstants.w);
                    Sys.assert(a.w == MathConstants.w);
                });
                QUnit.test("copy", {
                    var a = new Vector4(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
                    var b = new Vector4();
                    b.copy(a);
                    Sys.assert(b.x == MathConstants.x);
                    Sys.assert(b.y == MathConstants.y);
                    Sys.assert(b.z == MathConstants.z);
                    Sys.assert(b.w == MathConstants.w);
                    a.x = 0.0;
                    a.y = -1.0;
                    a.z = -2.0;
                    a.w = -3.0;
                    Sys.assert(b.x == MathConstants.x);
                    Sys.assert(b.y == MathConstants.y);
                    Sys.assert(b.z == MathConstants.z);
                    Sys.assert(b.w == MathConstants.w);
                });
                QUnit.test("add", {
                    var a = new Vector4(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
                    var b = new Vector4(-MathConstants.x, -MathConstants.y, -MathConstants.z, -MathConstants.w);
                    a.add(b);
                    Sys.assert(a.x == 0.0);
                    Sys.assert(a.y == 0.0);
                    Sys.assert(a.z == 0.0);
                    Sys.assert(a.w == 0.0);
                });
                QUnit.test("addVectors", {
                    var b = new Vector4(-MathConstants.x, -MathConstants.y, -MathConstants.z, -MathConstants.w);
                    var c = new Vector4();
                    c.addVectors(b, b);
                    Sys.assert(c.x == -2.0 * MathConstants.x);
                    Sys.assert(c.y == -2.0 * MathConstants.y);
                    Sys.assert(c.z == -2.0 * MathConstants.z);
                    Sys.assert(c.w == -2.0 * MathConstants.w);
                });
                QUnit.test("sub", {
                    var a = new Vector4(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
                    var b = new Vector4(-MathConstants.x, -MathConstants.y, -MathConstants.z, -MathConstants.w);
                    a.sub(b);
                    Sys.assert(a.x == 2.0 * MathConstants.x);
                    Sys.assert(a.y == 2.0 * MathConstants.y);
                    Sys.assert(a.z == 2.0 * MathConstants.z);
                    Sys.assert(a.w == 2.0 * MathConstants.w);
                });
                QUnit.test("applyMatrix4", {
                    var a = new Vector4(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
                    var m = new Matrix4();
                    m.makeRotationX(Mathf.PI);
                    var expected = new Vector4(2.0, -3.0, -4.0