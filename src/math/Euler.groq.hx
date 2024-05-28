Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.math;

import three.math.Quaternion;
import three.math.Matrix4;
import three.math.MathUtils;

class Euler {
    public var isEuler:Bool = true;

    private var _x:Float = 0;
    private var _y:Float = 0;
    private var _z:Float = 0;
    private var _order:String = DEFAULT_ORDER;
    private var _onChangeCallback:Void->Void = function() {};

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, order:String = DEFAULT_ORDER) {
        _x = x;
        _y = y;
        _z = z;
        _order = order;
    }

    public var x(get, set):Float;
    private function get_x():Float {
        return _x;
    }
    private function set_x(value:Float):Void {
        _x = value;
        _onChangeCallback();
    }

    public var y(get, set):Float;
    private function get_y():Float {
        return _y;
    }
    private function set_y(value:Float):Void {
        _y = value;
        _onChangeCallback();
    }

    public var z(get, set):Float;
    private function get_z():Float {
        return _z;
    }
    private function set_z(value:Float):Void {
        _z = value;
        _onChangeCallback();
    }

    public var order(get, set):String;
    private function get_order():String {
        return _order;
    }
    private function set_order(value:String):Void {
        _order = value;
        _onChangeCallback();
    }

    public function set(x:Float, y:Float, z:Float, order:String = _order):Euler {
        _x = x;
        _y = y;
        _z = z;
        _order = order;
        _onChangeCallback();
        return this;
    }

    public function clone():Euler {
        return new Euler(_x, _y, _z, _order);
    }

    public function copy(euler:Euler):Euler {
        _x = euler._x;
        _y = euler._y;
        _z = euler._z;
        _order = euler._order;
        _onChangeCallback();
        return this;
    }

    public function setFromRotationMatrix(m:Matrix4, order:String = _order, update:Bool = true):Euler {
        var te:Array<Float> = m.elements;
        var m11:Float = te[0], m12:Float = te[4], m13:Float = te[8];
        var m21:Float = te[1], m22:Float = te[5], m23:Float = te[9];
        var m31:Float = te[2], m32:Float = te[6], m33:Float = te[10];

        switch (order) {
            case 'XYZ':
                _y = Math.asin(clamp(m13, -1, 1));
                if (Math.abs(m13) < 0.9999999) {
                    _x = Math.atan2(-m23, m33);
                    _z = Math.atan2(-m12, m11);
                } else {
                    _x = Math.atan2(m32, m22);
                    _z = 0;
                }
                break;
            case 'YXZ':
                _x = Math.asin(-clamp(m23, -1, 1));
                if (Math.abs(m23) < 0.9999999) {
                    _y = Math.atan2(m13, m33);
                    _z = Math.atan2(m21, m22);
                } else {
                    _y = Math.atan2(-m31, m11);
                    _z = 0;
                }
                break;
            case 'ZXY':
                _x = Math.asin(clamp(m32, -1, 1));
                if (Math.abs(m32) < 0.9999999) {
                    _y = Math.atan2(-m31, m33);
                    _z = Math.atan2(-m12, m22);
                } else {
                    _y = 0;
                    _z = Math.atan2(m21, m11);
                }
                break;
            case 'ZYX':
                _y = Math.asin(-clamp(m31, -1, 1));
                if (Math.abs(m31) < 0.9999999) {
                    _x = Math.atan2(m32, m33);
                    _z = Math.atan2(m21, m11);
                } else {
                    _x = 0;
                    _z = Math.atan2(-m12, m22);
                }
                break;
            case 'YZX':
                _z = Math.asin(clamp(m21, -1, 1));
                if (Math.abs(m21) < 0.9999999) {
                    _x = Math.atan2(-m23, m22);
                    _y = Math.atan2(-m31, m11);
                } else {
                    _x = 0;
                    _y = Math.atan2(m13, m33);
                }
                break;
            case 'XZY':
                _z = Math.asin(-clamp(m12, -1, 1));
                if (Math.abs(m12) < 0.9999999) {
                    _x = Math.atan2(m32, m22);
                    _y = Math.atan2(m13, m11);
                } else {
                    _x = Math.atan2(-m23, m33);
                    _y = 0;
                }
                break;
            default:
                trace('THREE.Euler: .setFromRotationMatrix() encountered an unknown order: ' + order);
        }

        _order = order;
        if (update) _onChangeCallback();
        return this;
    }

    public function setFromQuaternion(q:Quaternion, order:String = _order, update:Bool = true):Euler {
        var _matrix:Matrix4 = Matrix4.fromQuaternion(q);
        return setFromRotationMatrix(_matrix, order, update);
    }

    public function setFromVector3(v:Vector3, order:String = _order):Euler {
        return set(v.x, v.y, v.z, order);
    }

    public function reorder(newOrder:String):Euler {
        var _quaternion:Quaternion = Quaternion.fromEuler(this);
        return setFromQuaternion(_quaternion, newOrder);
    }

    public function equals(euler:Euler):Bool {
        return _x == euler._x && _y == euler._y && _z == euler._z && _order == euler._order;
    }

    public function fromArray(array:Array<Float>):Euler {
        _x = array[0];
        _y = array[1];
        _z = array[2];
        if (array[3] != null) _order = array[3];
        _onChangeCallback();
        return this;
    }

    public function toArray(array:Array<Float> = null, offset:Int = 0):Array<Float> {
        if (array == null) array = new Array<Float>();
        array[offset] = _x;
        array[offset + 1] = _y;
        array[offset + 2] = _z;
        array[offset + 3] = _order;
        return array;
    }

    public function onChange(callback:Void->Void):Euler {
        _onChangeCallback = callback;
        return this;
    }

    public function iterator():Iterator<Float> {
        return new EulerIterator(this);
    }
}

private class EulerIterator implements Iterator<Float> {
    private var euler:Euler;
    private var index:Int = 0;

    public function new(euler:Euler) {
        this.euler = euler;
    }

    public function hasNext():Bool {
        return index < 4;
    }

    public function next():Float {
        switch (index) {
            case 0:
                return euler._x;
            case 1:
                return euler._y;
            case 2:
                return euler._z;
            case 3:
                return euler._order;
            default:
                throw new Error('Iterator out of bounds');
        }
        index++;
        return null;
    }
}

public static var DEFAULT_ORDER:String = 'XYZ';
```
Note that I've used the `three.math` package for the Quaternion and Matrix4 classes, as well as the MathUtils class for the `clamp` function. I've also used the `Vector3` class for the `setFromVector3` method. You may need to adjust the imports and class names to match your specific Haxe setup.