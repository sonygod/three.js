package;

import haxe.extern.Either;
import js.lib.Math;

import * as MathUtils from './MathUtils.js';
import { Quaternion } from './Quaternion.js';

@:jsRequire("three", "Vector3")
extern class Vector3 {
	function new(x:Float = 0, y:Float = 0, z:Float = 0):Void;

	var x:Float;
	var y:Float;
	var z:Float;

	function set(x:Float, y:Float, z:Float):Vector3;
	function setScalar(scalar:Float):Vector3;
	function setX(x:Float):Vector3;
	function setY(y:Float):Vector3;
	function setZ(z:Float):Vector3;
	function setComponent(index:Int, value:Float):Vector3;
	function getComponent(index:Int):Float;
	function clone():Vector3;
	function copy(v:Vector3):Vector3;
	function add(v:Vector3):Vector3;
	function addScalar(s:Float):Vector3;
	function addVectors(a:Vector3, b:Vector3):Vector3;
	function addScaledVector(v:Vector3, s:Float):Vector3;
	function sub(v:Vector3):Vector3;
	function subScalar(s:Float):Vector3;
	function subVectors(a:Vector3, b:Vector3):Vector3;
	function multiply(v:Vector3):Vector3;
	function multiplyScalar(scalar:Float):Vector3;
	function multiplyVectors(a:Vector3, b:Vector3):Vector3;
	function applyEuler(euler:Quaternion):Vector3;
	function applyAxisAngle(axis:Vector3, angle:Float):Vector3;
	function applyMatrix3(m:Matrix3):Vector3;
	function applyNormalMatrix(m:Matrix3):Vector3;
	function applyMatrix4(m:Matrix4):Vector3;
	function applyQuaternion(q:Quaternion):Vector3;
	function project(camera:Camera):Vector3;
	function unproject(camera:Camera):Vector3;
	function transformDirection(m:Matrix4):Vector3;
	function divide(v:Vector3):Vector3;
	function divideScalar(scalar:Float):Vector3;
	function min(v:Vector3):Vector3;
	function max(v:Vector3):Vector3;
	function clamp(min:Vector3, max:Vector3):Vector3;
	function clampScalar(minVal:Float, maxVal:Float):Vector3;
	function clampLength(min:Float, max:Float):Vector3;
	function floor():Vector3;
	function ceil():Vector3;
	function round():Vector3;
	function roundToZero():Vector3;
	function negate():Vector3;
	function dot(v:Vector3):Float;
	function lengthSq():Float;
	function length():Float;
	function manhattanLength():Float;
	function normalize():Vector3;
	function setLength(length:Float):Vector3;
	function lerp(v:Vector3, alpha:Float):Vector3;
	function lerpVectors(v1:Vector3, v2:Vector3, alpha:Float):Vector3;
	function cross(v:Vector3):Vector3;
	function crossVectors(a:Vector3, b:Vector3):Vector3;
	function projectOnVector(v:Vector3):Vector3;
	function projectOnPlane(planeNormal:Vector3):Vector3;
	function reflect(normal:Vector3):Vector3;
	function angleTo(v:Vector3):Float;
	function distanceTo(v:Vector3):Float;
	function distanceToSquared(v:Vector3):Float;
	function manhattanDistanceTo(v:Vector3):Float;
	function setFromSpherical(s:Spherical):Vector3;
	function setFromSphericalCoords(radius:Float, phi:Float, theta:Float):Vector3;
	function setFromCylindrical(c:Cylindrical):Vector3;
	function setFromCylindricalCoords(radius:Float, theta:Float, y:Float):Vector3;
	function setFromMatrixPosition(m:Matrix4):Vector3;
	function setFromMatrixScale(m:Matrix4):Vector3;
	function setFromMatrixColumn(m:Matrix4, index:Int):Vector3;
	function setFromMatrix3Column(m:Matrix3, index:Int):Vector3;
	function setFromEuler(e:Euler):Vector3;
	//function setFromColor(c:Color):Vector3; // requires Color support
	function equals(v:Vector3):Bool;
	function fromArray(array:Array<Float>, offset:Int = 0):Vector3;
	function toArray(array:Array<Float> = null, offset:Int = 0):Array<Float>;
	function fromBufferAttribute(attribute:BufferAttribute, index:Int):Vector3;
	function random():Vector3;
	function randomDirection():Vector3;
}