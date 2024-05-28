package three.math;

import three.math.Quaternion;
import three.math.Matrix4;
import three.math.MathUtils;

class Euler {
  public var isEuler:Bool = true;

  public var _x:Float = 0;
  public var _y:Float = 0;
  public var _z:Float = 0;
  public var _order:String = DEFAULT_ORDER;

  private var _onChangeCallback: Void->Void;

  public function new(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?order:String = DEFAULT_ORDER) {
    _x = x;
    _y = y;
    _z = z;
    _order = order;
  }

  public var x(get, set):Float;
  public function get_x():Float {
    return _x;
  }

  public function set_x(value:Float):Float {
    _x = value;
    _onChangeCallback();
    return value;
  }

  public var y(get, set):Float;
  public function get_y():Float {
    return _y;
  }

  public function set_y(value:Float):Float {
    _y = value;
    _onChangeCallback();
    return value;
  }

  public var z(get, set):Float;
  public function get_z():Float {
    return _z;
  }

  public function set_z(value:Float):Float {
    _z = value;
    _onChangeCallback();
    return value;
  }

  public var order(get, set):String;
  public function get_order():String {
    return _order;
  }

  public function set_order(value:String):String {
    _order = value;
    _onChangeCallback();
    return value;
  }

  public function set(x:Float, y:Float, z:Float, ?order:String):Euler {
    _x = x;
    _y = y;
    _z = z;
    _order = order == null ? _order : order;
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

  public function setFromRotationMatrix(m:Matrix4, ?order:String = _order, ?update:Bool = true):Euler {
    var te = m.elements;
    var m11 = te[0];
    var m12 = te[4];
    var m13 = te[8];
    var m21 = te[1];
    var m22 = te[5];
    var m23 = te[9];
    var m31 = te[2];
    var m32 = te[6];
    var m33 = te[10];

    switch (order) {
      case 'XYZ':
        _y = Math.asin(Math.clamp(m13, -1, 1));
        if (Math.abs(m13) < 0.9999999) {
          _x = Math.atan2(-m23, m33);
          _z = Math.atan2(-m12, m11);
        } else {
          _x = Math.atan2(m32, m22);
          _z = 0;
        }
        break;
      case 'YXZ':
        _x = Math.asin(-Math.clamp(m23, -1, 1));
        if (Math.abs(m23) < 0.9999999) {
          _y = Math.atan2(m13, m33);
          _z = Math.atan2(m21, m22);
        } else {
          _y = Math.atan2(-m31, m11);
          _z = 0;
        }
        break;
      case 'ZXY':
        _x = Math.asin(Math.clamp(m32, -1, 1));
        if (Math.abs(m32) < 0.9999999) {
          _y = Math.atan2(-m31, m33);
          _z = Math.atan2(-m12, m22);
        } else {
          _y = 0;
          _z = Math.atan2(m21, m11);
        }
        break;
      case 'ZYX':
        _y = Math.asin(-Math.clamp(m31, -1, 1));
        if (Math.abs(m31) < 0.9999999) {
          _x = Math.atan2(m32, m33);
          _z = Math.atan2(m21, m11);
        } else {
          _x = 0;
          _z = Math.atan2(-m12, m22);
        }
        break;
      case 'YZX':
        _z = Math.asin(Math.clamp(m21, -1, 1));
        if (Math.abs(m21) < 0.9999999) {
          _x = Math.atan2(-m23, m22);
          _y = Math.atan2(-m31, m11);
        } else {
          _x = 0;
          _y = Math.atan2(m13, m33);
        }
        break;
      case 'XZY':
        _z = Math.asin(-Math.clamp(m12, -1, 1));
        if (Math.abs(m12) < 0.9999999) {
          _x = Math.atan2(m32, m22);
          _y = Math.atan2(m13, m11);
        } else {
          _x = Math.atan2(-m23, m33);
          _y = 0;
        }
        break;
      default:
        trace('THREE.Euler: .setFromRotationMatrix() encountered an unknown order: $order');
    }

    _order = order;
    if (update) _onChangeCallback();
    return this;
  }

  public function setFromQuaternion(q:Quaternion, ?order:String = _order, ?update:Bool = true):Euler {
    _matrix.makeRotationFromQuaternion(q);
    return setFromRotationMatrix(_matrix, order, update);
  }

  public function setFromVector3(v:Vector3, ?order:String = _order):Euler {
    return set(v.x, v.y, v.z, order);
  }

  public function reorder(newOrder:String):Euler {
    _quaternion.setFromEuler(this);
    return setFromQuaternion(_quaternion, newOrder);
  }

  public function equals(euler:Euler):Bool {
    return euler._x == _x && euler._y == _y && euler._z == _z && euler._order == _order;
  }

  public function fromArray(array:Array<Float>):Euler {
    _x = array[0];
    _y = array[1];
    _z = array[2];
    if (array[3] != null) _order = array[3];
    _onChangeCallback();
    return this;
  }

  public function toArray(?array:Array<Float> = null, ?offset:Int = 0):Array<Float> {
    if (array == null) array = [];
    array[offset] = _x;
    array[offset + 1] = _y;
    array[offset + 2] = _z;
    array[offset + 3] = _order;
    return array;
  }

  public function _onChange(callback:Void->Void):Euler {
    _onChangeCallback = callback;
    return this;
  }

  public function _onChangeCallback():Void {}

  public iterator():Iterator<Euler> {
    var iterator = new Iterator<Euler>(this);
    iterator.yield(_x);
    iterator.yield(_y);
    iterator.yield(_z);
    iterator.yield(_order);
    return iterator;
  }

  public static var DEFAULT_ORDER:String = 'XYZ';
}

// Initialize static variables
var _matrix:Matrix4 = new Matrix4();
var _quaternion:Quaternion = new Quaternion();