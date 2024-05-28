package three.math;

import haxe.ds.ReadOnlyArray;

class Quaternion {
  public var _x:Float = 0;
  public var _y:Float = 0;
  public var _z:Float = 0;
  public var _w:Float = 1;
  public var isQuaternion:Bool = true;
  private var _onChangeCallback:Void->Void = function() {};

  public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
    _x = x;
    _y = y;
    _z = z;
    _w = w;
  }

  public static function slerpFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int, t:Float) {
    // implementation...
  }

  public static function multiplyQuaternionsFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array.Float, srcOffset1:Int) {
    // implementation...
  }

  public function get_x():Float {
    return _x;
  }

  public function set_x(value:Float):Void {
    _x = value;
    _onChangeCallback();
  }

  public function get_y():Float {
    return _y;
  }

  public function set_y(value:Float):Void {
    _y = value;
    _onChangeCallback();
  }

  public function get_z():Float {
    return _z;
  }

  public function set_z(value:Float):Void {
    _z = value;
    _onChangeCallback();
  }

  public function get_w():Float {
    return _w;
  }

  public function set_w(value:Float):Void {
    _w = value;
    _onChangeCallback();
  }

  public function set(x:Float, y:Float, z:Float, w:Float):Quaternion {
    _x = x;
    _y = y;
    _z = z;
    _w = w;
    _onChangeCallback();
    return this;
  }

  public function clone():Quaternion {
    return new Quaternion(_x, _y, _z, _w);
  }

  public function copy(quaternion:Quaternion):Quaternion {
    _x = quaternion._x;
    _y = quaternion._y;
    _z = quaternion._z;
    _w = quaternion._w;
    _onChangeCallback();
    return this;
  }

  public function setFromEuler(euler:Quaternion, update:Bool = true):Quaternion {
    // implementation...
  }

  public function setFromAxisAngle(axis:Quaternion, angle:Float):Quaternion {
    // implementation...
  }

  public function setFromRotationMatrix(m:Array<Float>):Quaternion {
    // implementation...
  }

  public function setFromUnitVectors(vFrom:Quaternion, vTo:Quaternion):Quaternion {
    // implementation...
  }

  public function angleTo(q:Quaternion):Float {
    return 2 * Math.acos(Math.abs(MathUtils.clamp(dot(q), -1, 1)));
  }

  public function rotateTowards(q:Quaternion, step:Float):Quaternion {
    var angle = angleTo(q);
    if (angle == 0) return this;
    var t = Math.min(1, step / angle);
    slerp(q, t);
    return this;
  }

  public function identity():Quaternion {
    return set(0, 0, 0, 1);
  }

  public function invert():Quaternion {
    _x *= -1;
    _y *= -1;
    _z *= -1;
    _onChangeCallback();
    return this;
  }

  public function conjugate():Quaternion {
    _x *= -1;
    _y *= -1;
    _z *= -1;
    _onChangeCallback();
    return this;
  }

  public function dot(v:Quaternion):Float {
    return _x * v._x + _y * v._y + _z * v._z + _w * v._w;
  }

  public function lengthSq():Float {
    return _x * _x + _y * _y + _z * _z + _w * _w;
  }

  public function length():Float {
    return Math.sqrt(lengthSq());
  }

  public function normalize():Quaternion {
    var l = length();
    if (l == 0) {
      _x = 0;
      _y = 0;
      _z = 0;
      _w = 1;
    } else {
      l = 1 / l;
      _x *= l;
      _y *= l;
      _z *= l;
      _w *= l;
    }
    _onChangeCallback();
    return this;
  }

  public function multiply(q:Quaternion):Quaternion {
    return multiplyQuaternions(this, q);
  }

  public function premultiply(q:Quaternion):Quaternion {
    return multiplyQuaternions(q, this);
  }

  public function multiplyQuaternions(a:Quaternion, b:Quaternion):Quaternion {
    // implementation...
  }

  public function slerp(qb:Quaternion, t:Float):Quaternion {
    // implementation...
  }

  public function random():Quaternion {
    // implementation...
  }

  public function equals(quaternion:Quaternion):Bool {
    return _x == quaternion._x && _y == quaternion._y && _z == quaternion._z && _w == quaternion._w;
  }

  public function fromArray(array:ReadOnlyArray<Float>, offset:Int = 0):Quaternion {
    _x = array[offset];
    _y = array[offset + 1];
    _z = array[offset + 2];
    _w = array[offset + 3];
    _onChangeCallback();
    return this;
  }

  public function toArray(array:ReadOnlyArray<Float> = null, offset:Int = 0):ReadOnlyArray<Float> {
    if (array == null) array = new Array<Float>();
    array[offset] = _x;
    array[offset + 1] = _y;
    array[offset + 2] = _z;
    array[offset + 3] = _w;
    return array;
  }

  public function fromBufferAttribute(attribute:Array<Float>, index:Int):Quaternion {
    _x = attribute[index];
    _y = attribute[index + 1];
    _z = attribute[index + 2];
    _w = attribute[index + 3];
    _onChangeCallback();
    return this;
  }

  public function toJSON():ReadOnlyArray<Float> {
    return toArray();
  }

  public function onChange(callback:Void->Void):Quaternion {
    _onChangeCallback = callback;
    return this;
  }

  public function onChangeCallback():Void {
    // no-op
  }

  @:iterator public function iterator():Iterator<Float> {
    return new Iterator<Float>([ _x, _y, _z, _w ]);
  }
}