package ;

import js.lib.Error;
import js.lib.Math;

@:jsRequire("three", "Vector4") extern class Vector4 {
  public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1):Void;
  public var isVector4(default, never):Bool;
  public var x:Float;
  public var y:Float;
  public var z:Float;
  public var w:Float;
  public var width(get, set):Float;
  function get_width():Float;
  function set_width(value:Float):Float;
  public var height(get, set):Float;
  function get_height():Float;
  function set_height(value:Float):Float;
  @:overload(function(x:Float, y:Float, z:Float, ?w:Float):Vector4 {})
  public function set(x:Float, y:Float, z:Float, w:Float = 1):Vector4;
  public function setScalar(scalar:Float):Vector4;
  public function setX(x:Float):Vector4;
  public function setY(y:Float):Vector4;
  public function setZ(z:Float):Vector4;
  public function setW(w:Float):Vector4;
  public function setComponent(index:Int, value:Float):Vector4;
  public function getComponent(index:Int):Float;
  public function clone():Vector4;
  @:overload(function(v:Vector4):Vector4 {})
  public function copy(v:Dynamic):Vector4;
  public function add(v:Vector4):Vector4;
  public function addScalar(s:Float):Vector4;
  public function addVectors(a:Vector4, b:Vector4):Vector4;
  public function addScaledVector(v:Vector4, s:Float):Vector4;
  public function sub(v:Vector4):Vector4;
  public function subScalar(s:Float):Vector4;
  public function subVectors(a:Vector4, b:Vector4):Vector4;
  public function multiply(v:Vector4):Vector4;
  public function multiplyScalar(scalar:Float):Vector4;
  public function applyMatrix4(m:Matrix4):Vector4;
  public function divideScalar(scalar:Float):Vector4;
  public function setAxisAngleFromQuaternion(q:Quaternion):Vector4;
  public function setAxisAngleFromRotationMatrix(m:Matrix4):Vector4;
  public function min(v:Vector4):Vector4;
  public function max(v:Vector4):Vector4;
  public function clamp(min:Vector4, max:Vector4):Vector4;
  public function clampScalar(minVal:Float, maxVal:Float):Vector4;
  public function clampLength(min:Float, max:Float):Vector4;
  public function floor():Vector4;
  public function ceil():Vector4;
  public function round():Vector4;
  public function roundToZero():Vector4;
  public function negate():Vector4;
  public function dot(v:Vector4):Float;
  public function lengthSq():Float;
  public function length():Float;
  public function manhattanLength():Float;
  public function normalize():Vector4;
  public function setLength(length:Float):Vector4;
  public function lerp(v:Vector4, alpha:Float):Vector4;
  public function lerpVectors(v1:Vector4, v2:Vector4, alpha:Float):Vector4;
  public function equals(v:Vector4):Bool;
  @:overload(function(array:Array<Float>, offset:Int = 0):Vector4 {})
  public function fromArray(array:Dynamic, offset:Int = 0):Vector4;
  @:overload(function(array:Array<Float>, offset:Int = 0):Array<Float> {})
  public function toArray(array:Dynamic = null, offset:Int = 0):Array<Float>;
  public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Vector4;
  public function random():Vector4;
  public function iterator():Iterator<Float>;
  static public var prototype(default, never):Vector4;
}