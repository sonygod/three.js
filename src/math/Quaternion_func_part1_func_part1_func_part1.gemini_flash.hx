package ;

import haxe.extern.EitherType;
// import * as MathUtils from './MathUtils.js';
import { MathUtils } from "./MathUtils";

@:jsRequire("three") @:expose
extern class Quaternion {
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1):Void;

	public static slerpFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int, t:Float):Void;
	public static multiplyQuaternionsFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int):Array<Float>;

	public var x(get, set):Float;
	public function get_x():Float;
	public function set_x(value:Float):Float;

	public var y(get, set):Float;
	public function get_y():Float;
	public function set_y(value:Float):Float;

	public var z(get, set):Float;
	public function get_z():Float;
	public function set_z(value:Float):Float;

	public var w(get, set):Float;
	public function get_w():Float;
	public function set_w(value:Float):Float;

	public function set(x:Float, y:Float, z:Float, w:Float):Quaternion;
	public function clone():Quaternion;
	public function copy(quaternion:Quaternion):Quaternion;
	public function setFromEuler(euler:Euler, update:Bool):Quaternion;
	public function setFromAxisAngle(axis:Vector3, angle:Float):Quaternion;
	public function setFromRotationMatrix(m:Matrix4):Quaternion;
	public function setFromUnitVectors(vFrom:Vector3, vTo:Vector3):Quaternion;
	public function angleTo(q:Quaternion):Float;
	public function rotateTowards(q:Quaternion, step:Float):Quaternion;
	public function identity():Quaternion;
	public function invert():Quaternion;
	public function conjugate():Quaternion;
	public function dot(v:Quaternion):Float;
	public function lengthSq():Float;
	public function length():Float;
	public function normalize():Quaternion;
	public function multiply(q:Quaternion):Quaternion;
	public function premultiply(q:Quaternion):Quaternion;
	public function multiplyQuaternions(a:Quaternion, b:Quaternion):Quaternion;
	public function slerp(qb:Quaternion, t:Float):Quaternion;
	public function slerpQuaternions(qa:Quaternion, qb:Quaternion, t:Float):Quaternion;
	public function random():Quaternion;
	public function equals(quaternion:Quaternion):Bool;
	public function fromArray(array:Array<Float>, offset:Int = 0):Quaternion;
	public function toArray(array:Array<Float> = null, offset:Int = 0):Array<Float>;
	public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Quaternion;
	public function toJSON():Dynamic;
	public function _onChange(callback:Void->Void):Quaternion;
	public function _onChangeCallback():Void;
}