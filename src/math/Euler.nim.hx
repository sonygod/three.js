import Quaternion.Quaternion;
import Matrix4.Matrix4;
import MathUtils.clamp;

class Euler {
    public var isEuler:Bool = true;
    private var _x:Float;
    private var _y:Float;
    private var _z:Float;
    private var _order:String;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, order:String = Euler.DEFAULT_ORDER) {
        this._x = x;
        this._y = y;
        this._z = z;
        this._order = order;
    }

    public function get x():Float {
        return this._x;
    }

    public function set x(value:Float) {
        this._x = value;
        this._onChangeCallback();
    }

    public function get y():Float {
        return this._y;
    }

    public function set y(value:Float) {
        this._y = value;
        this._onChangeCallback();
    }

    public function get z():Float {
        return this._z;
    }

    public function set z(value:Float) {
        this._z = value;
        this._onChangeCallback();
    }

    public function get order():String {
        return this._order;
    }

    public function set order(value:String) {
        this._order = value;
        this._onChangeCallback();
    }

    public function set(x:Float, y:Float, z:Float, order:String = this._order):Euler {
        this._x = x;
        this._y = y;
        this._z = z;
        this._order = order;
        this._onChangeCallback();
        return this;
    }

    public function clone():Euler {
        return new Euler(this._x, this._y, this._z, this._order);
    }

    public function copy(euler:Euler):Euler {
        this._x = euler._x;
        this._y = euler._y;
        this._z = euler._z;
        this._order = euler._order;
        this._onChangeCallback();
        return this;
    }

    public function setFromRotationMatrix(m:Matrix4, order:String = this._order, update:Bool = true):Euler {
        // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
        var te = m.elements;
        var m11 = te[0], m12 = te[4], m13 = te[8];
        var m21 = te[1], m22 = te[5], m23 = te[9];
        var m31 = te[2], m32 = te[6], m33 = te[10];

        switch (order) {
            case 'XYZ':
                this._y = Math.asin(clamp(m13, -1, 1));
                if (Math.abs(m13) < 0.9999999) {
                    this._x = Math.atan2(-m23, m33);
                    this._z = Math.atan2(-m12, m11);
                } else {
                    this._x = Math.atan2(m32, m22);
                    this._z = 0;
                }
                break;
            case 'YXZ':
                this._x = Math.asin(-clamp(m23, -1, 1));
                if (Math.abs(m23) < 0.9999999) {
                    this._y = Math.atan2(m13, m33);
                    this._z = Math.atan2(m21, m22);
                } else {
                    this._y = Math.atan2(-m31, m11);
                    this._z = 0;
                }
                break;
            case 'ZXY':
                this._x = Math.asin(clamp(m32, -1, 1));
                if (Math.abs(m32) < 0.9999999) {
                    this._y = Math.atan2(-m31, m33);
                    this._z = Math.atan2(-m12, m22);
                } else {
                    this._y = 0;
                    this._z = Math.atan2(m21, m11);
                }
                break;
            case 'ZYX':
                this._y = Math.asin(-clamp(m31, -1, 1));
                if (Math.abs(m31) < 0.9999999) {
                    this._x = Math.atan2(m32, m33);
                    this._z = Math.atan2(m21, m11);
                } else {
                    this._x = 0;
                    this._z = Math.atan2(-m12, m22);
                }
                break;
            case 'YZX':
                this._z = Math.asin(clamp(m21, -1, 1));
                if (Math.abs(m21) < 0.9999999) {
                    this._x = Math.atan2(-m23, m22);
                    this._y = Math.atan2(-m31, m11);
                } else {
                    this._x = 0;
                    this._y = Math.atan2(m13, m33);
                }
                break;
            case 'XZY':
                this._z = Math.asin(-clamp(m12, -1, 1));
                if (Math.abs(m12) < 0.9999999) {
                    this._x = Math.atan2(m32, m22);
                    this._y = Math.atan2(m13, m11);
                } else {
                    this._x = Math.atan2(-m23, m33);
                    this._y = 0;
                }
                break;
            default:
                trace('THREE.Euler: .setFromRotationMatrix() encountered an unknown order: ' + order);
        }

        this._order = order;
        if (update === true) this._onChangeCallback();
        return this;
    }

    public function setFromQuaternion(q:Quaternion, order:String, update:Bool):Euler {
        var matrix = new Matrix4();
        matrix.makeRotationFromQuaternion(q);
        return this.setFromRotationMatrix(matrix, order, update);
    }

    public function setFromVector3(v:Vector3, order:String = this._order):Euler {
        return this.set(v.x, v.y, v.z, order);
    }

    public function reorder(newOrder:String):Euler {
        var quaternion = new Quaternion();
        quaternion.setFromEuler(this);
        return this.setFromQuaternion(quaternion, newOrder);
    }

    public function equals(euler:Euler):Bool {
        return (euler._x === this._x) && (euler._y === this._y) && (euler._z === this._z) && (euler._order === this._order);
    }

    public function fromArray(array:Array<Float>):Euler {
        this._x = array[0];
        this._y = array[1];
        this._z = array[2];
        if (array[3] !== undefined) this._order = array[3];
        this._onChangeCallback();
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = this._x;
        array[offset + 1] = this._y;
        array[offset + 2] = this._z;
        array[offset + 3] = this._order;
        return array;
    }

    public function _onChange(callback:Void->Void):Euler {
        this._onChangeCallback = callback;
        return this;
    }

    public function _onChangeCallback():Void {}

    public function iterator():Iterator<Float> {
        yield this._x;
        yield this._y;
        yield this._z;
        yield this._order;
    }
}

class Euler {
    public static var DEFAULT_ORDER:String = 'XYZ';
}