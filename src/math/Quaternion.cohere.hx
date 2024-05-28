package math;

import js.Browser;

class Quaternion {

	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(?x:Float, ?y:Float, ?z:Float, ?w:Float) {
		this.x = x ?? 0.0;
		this.y = y ?? 0.0;
		this.z = z ?? 0.0;
		this.w = w ?? 1.0;
	}

	public static function slerpFlat(dst:FloatArray, dstOffset:Int, src0:FloatArray, srcOffset0:Int, src1:FloatArray, srcOffset1:Int, t:Float):Void {
		var x0 = src0[srcOffset0];
		var y0 = src0[srcOffset0 + 1];
		var z0 = src0[srcOffset0 + 2];
		var w0 = src0[srcOffset0 + 3];

		var x1 = src1[srcOffset1];
		var y1 = src1[srcOffset1 + 1];
		var z1 = src1[srcOffset1 + 2];
		var w1 = src1[srcOffset1 + 3];

		if (t == 0.0) {
			dst[dstOffset] = x0;
			dst[dstOffset + 1] = y0;
			dst[dstOffset + 2] = z0;
			dst[dstOffset + 3] = w0;
			return;
		}

		if (t == 1.0) {
			dst[dstOffset] = x1;
			dst[dstOffset + 1] = y1;
			dst[dstOffset + 2] = z1;
			dst[dstOffset + 3] = w1;
			return;
		}

		if (w0 != w1 || x0 != x1 || y0 != y1 || z0 != z1) {
			var s = 1.0 - t;
			var cos = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1;
			var dir = (cos >= 0) ? 1 : -1;
			var sqrSin = 1.0 - cos * cos;

			// Skip the Slerp for tiny steps to avoid numeric problems:
			if (sqrSin > Browser.machineEpsilon) {
				var sin = Math.sqrt(sqrSin);
				var len = Math.atan2(sin, cos * dir);

				s = Math.sin(s * len) / sin;
				t = Math.sin(t * len) / sin;
			}

			var tDir = t * dir;

			x0 = x0 * s + x1 * tDir;
			y0 = y0 * s + y1 * tDir;
			z0 = z0 * s + z1 * tDir;
			w0 = w0 * s + w1 * tDir;

			// Normalize in case we just did a lerp:
			if (s == 1.0 - t) {
				var f = 1.0 / Math.sqrt(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0);

				x0 *= f;
				y0 *= f;
				z0 *= f;
				w0 *= f;
			}
		}

		dst[dstOffset] = x0;
		dst[dstOffset + 1] = y0;
		dst[dstOffset + 2] = z0;
		dst[dstOffset + 3] = w0;
	}

	public static function multiplyQuaternionsFlat(dst:FloatArray, dstOffset:Int, src0:FloatArray, srcOffset0:Int, src1:FloatArray, srcOffset1:Int):FloatArray {
		var x0 = src0[srcOffset0];
		var y0 = src0[srcOffset0 + 1];
		var z0 = src0[srcOffset0 + 2];
		var w0 = src0[srcOffset0 + 3];

		var x1 = src1[srcOffset1];
		var y1 = src1[srcOffset1 + 1];
		var z1 = src1[srcOffset1 + 2];
		var w1 = src1[srcOffset1 + 3];

		dst[dstOffset] = x0 * w1 + w0 * x1 + y0 * z1 - z0 * y1;
		dst[dstOffset + 1] = y0 * w1 + w0 * y1 + z0 * x1 - x0 * z1;
		dst[dstOffset + 2] = z0 * w1 + w0 * z1 + x0 * y1 - y0 * x1;
		dst[dstOffset + 3] = w0 * w1 - x0 * x1 - y0 * y1 - z0 * z1;

		return dst;
	}

	public function clone():Quaternion {
		return new Quaternion(this.x, this.y, this.z, this.w);
	}

	public function copy(quaternion:Quaternion):Quaternion {
		this.x = quaternion.x;
		this.y = quaternion.y;
		this.z = quaternion.z;
		this.w = quaternion.w;

		return this;
	}

	public function setFromEuler(euler:Euler, update:Bool = true):Quaternion {
		var x = euler.x;
		var y = euler.y;
		var z = euler.z;
		var order = euler.order;

		// http://www.mathworks.com/matlabcentral/fileexchange/
		// 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
		//	content/SpinCalc.m

		var cos = Math.cos;
		var sin = Math.sin;

		var c1 = cos(x / 2.0);
		var c2 = cos(y / 2.0);
		var c3 = cos(z / 2.0);

		var s1 = sin(x / 2.0);
		var s2 = sin(y / 2.0);
		var s3 = sin(z / 2.0);

		var _x:Float;
		var _y:Float;
		var _z:Float;
		var _w:Float;

		switch (order) {
			case EulerOrder.XYZ:
				_x = s1 * c2 * c3 + c1 * s2 * s3;
				_y = c1 * s2 * c3 - s1 * c2 * s3;
				_z = c1 * c2 * s3 + s1 * s2 * c3;
				_w = c1 * c2 * c3 - s1 * s2 * s3;
				break;

			case EulerOrder.YXZ:
				_x = s1 * c2 * c3 + c1 * s2 * s3;
				_y = c1 * s2 * c3 - s1 * c2 * s3;
				_z = c1 * c2 * s3 - s1 * s2 * c3;
				_w = c1 * c2 * c3 + s1 * s2 * s3;
				break;

			case EulerOrder.ZXY:
				_x = s1 * c2 * c3 - c1 * s2 * s3;
				_y = c1 * s2 * c3 + s1 * c2 * s3;
				_z = c1 * c2 * s3 + s1 * s2 * c3;
				_w = c1 * c2 * c3 - s1 * s2 * s3;
				break;

			case EulerOrder.ZYX:
				_x = s1 * c2 * c3 - c1 * s2 * s3;
				_y = c1 * s2 * c3 + s1 * c2 * s3;
				_z = c1 * c2 * s3 - s1 * s2 * c3;
				_w = c1 * c2 * c3 + s1 * s2 * s3;
				break;

			case EulerOrder.YZX:
				_x = s1 * c2 * c3 + c1 * s2 * s3;
				_y = c1 * s2 * c3 + s1 * c2 * s3;
				_z = c1 * c2 * s3 - s1 * s2 * c3;
				_w = c1 * c2 * c3 - s1 * s2 * s3;
				break;

			case EulerOrder.XZY:
				_x = s1 * c2 * c3 - c1 * s2 * s3;
				_y = c1 * s2 * c3 - s1 * c2 * s3;
				_z = c1 * c2 * s3 + s1 * s2 * c3;
				_w = c1 * c2 * c3 + s1 * s2 * s3;
				break;

			default:
				throw "Quaternion_.setFromEuler: .setFromEuler() encountered an unknown order: " + order;
		}

		this.x = _x;
		this.y = _y;
		this.z = _z;
		this.w = _w;

		if (update == true) this._onChangeCallback();

		return this;
	}

	public function setFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
		// http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm

		// assumes axis is normalized

		var halfAngle = angle / 2.0;
		var s = Math.sin(halfAngle);

		this.x = axis.x * s;
		this.y = axis.y * s;
		this.z = axis.z * s;
		this.w = Math.cos(halfAngle);

		this._onChangeCallback();

		return this;
	}

	public function setFromRotationMatrix(m:Matrix4):Quaternion {
		// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm

		// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

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

		var trace = m11 + m22 + m33;

		if (trace > 0.0) {
			var s = 0.5 / Math.sqrt(trace + 1.0);

			this.w = 0.25 / s;
			this.x = (m32 - m23) * s;
			this.y = (m13 - m31) * s;
			this.z = (m21 - m12) * s;
		} else if (m11 > m22 && m11 > m33) {
			var s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);

			this.w = (m32 - m23) / s;
			this.x = 0.25 * s;
			this.y = (m12 + m21) / s;
			this.z = (m13 + m31) / s;
		} else if (m22 > m33) {
			var s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);

			this.w = (m13 - m31) / s;
			this.x = (m12 + m21) / s;
			this.y = 0.25 * s;
			this.z = (m23 + m32) / s;
		} else {
			var s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);

			this.w = (m21 - m12) / s;
			this.x = (m13 + m31) / s;
			this.y = (m23 + m32) / s;
			this.z = 0.25 * s;
		}

		this._onChangeCallback();

		return this;
	}

	public function setFromUnitVectors(vFrom:Vector3, vTo:Vector3):Quaternion {
		// assumes direction vectors vFrom and vTo are normalized

		var r = vFrom.dot(vTo) + 1.0;

		if (r < Browser.machineEpsilon) {
			// vFrom and vTo point in opposite directions

			r = 0.0;

			if (Math.abs(vFrom.x) > Math.abs(vFrom.z)) {
				this.x = -vFrom.y;
				this.y = vFrom.x;
				this.z = 0.0;
				this.w = r;
			} else {
				this.x = 0.0;
				this.y = -vFrom.z;
				this.z = vFrom.y;
				this.w = r;
			}
		} else {
			// crossVectors(vFrom, vTo); // inlined to avoid cyclic dependency on Vector3

			this.x = vFrom.y * vTo.z - vFrom.z * vTo.y;
			this.y = vFrom.z * vTo.x - vFrom.x * vTo.z;
			this.z = vFrom.x * vTo.y - vFrom.y * vTo.x;
			this.w = r;
		}

		return this.normalize();
	}

	public function angleTo(q:Quaternion):Float {
		return 2.0 * Math.acos(Math.abs(Math.clamp(this.dot(q), -1.0, 1.0)));
	}

	public function rotateTowards(q:Quaternion, step:Float):Quaternion {
		var angle = this.angleTo(q);

		if (angle == 0.0) return this;

		var t = Math.min(1.0, step / angle);

		this.slerp(q, t);

		return this;
	}

	public function identity():Quaternion {
		return this.set(0.0, 0.0, 0.0, 1.0);
	}

	public function invert():Quaternion {
		// quaternion is assumed to have unit length

		return this.conjugate();
	}

	public function conjugate():Quaternion {
		this.x *= -1.0;
		this.y *= -1.0;
		this.z *= -1.0;

		this._onChangeCallback();

		return this;
	}

	public function dot(v:Quaternion):Float {
		return this.x * v.x + this.y * v.y + this.z * v.z + this.w * v.w;
	}

	public function lengthSq():Float {
		return this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w;
	}

	public function length():Float {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
	}

	public function normalize():Quaternion {
		var l = this.length();

		if (l == 0.0) {
			this.x = 0.0;
			this.y = 0.0;
			this.z = 0.0;
			this.w = 1.0;
		} else {
			l = 1.0 / l;

			this.x *= l;
			this.y *= l;
			this.z *= l;
			this.w *= l;
		}

		this._onChangeCallback();

		return this;
	}

	public function multiply(q:Quaternion):Quaternion {
		return this.multiplyQuaternions(this, q);
	}

	public function premultiply(q:Quaternion):Quaternion {
		return this.multiplyQuaternions(q
	public function premultiply(q:Quaternion):Quaternion {
		return this.multiplyQuaternions(q, this);
	}

	public function multiplyQuaternions(a:Quaternion, b:Quaternion):Quaternion {
		// from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

		var qax = a.x;
		var qay = a.y;
		var qaz = a.z;
		var qaw = a.w;

		var qbx = b.x;
		var qby = b.y;
		var qbz = b.z;
		var qbw = b.w;

		this.x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
		this.y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
		this.z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
		this.w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;

		this._onChangeCallback();

		return this;
	}

	public function slerp(qb:Quaternion, t:Float):Quaternion {
		if (t == 0.0) return this;
		if (t == 1.0) return this.copy(qb);

		var x = this.x;
		var y = this.y;
		var z = this.z;
		var w = this.w;

		// http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/

		var cosHalfTheta = w * qb.w + x * qb.x + y * qb.y + z * qb.z;

		if (cosHalfTheta < 0.0) {
			this.w = -qb.w;
			this.x = -qb.x;
			this.y = -qb.y;
			this.z = -qb.z;

			cosHalfTheta = -cosHalfTheta;
		} else {
			this.copy(qb);
		}

		if (cosHalfTheta >= 1.0) {
			this.w = w;
			this.x = x;
			this.y = y;
			this.z = z;

			return this;
		}

		var sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta;

		if (sqrSinHalfTheta <= Browser.machineEpsilon) {
			var s = 1.0 - t;

			this.w = s * w + t * this.w;
			this.x = s * x + t * this.x;
			this.y = s * y + t * this.y;
			this.z = s * z + t * this.z;

			this.normalize(); // normalize calls _onChangeCallback()

			return this;
		}

		var sinHalfTheta = Math.sqrt(sqrSinHalfTheta);
		var halfTheta = Math.atan2(sinHalfTheta, cosHalfTheta);
		var ratioA = Math.sin((1.0 - t) * halfTheta) / sinHalfTheta;
		var ratioB = Math.sin(t * halfTheta) / sinHalfTheta;

		this.w = w * ratioA + this.w * ratioB;
		this.x = x * ratioA + this.x * ratioB;
		this.y = y * ratioA + this.y * ratioB;
		this.z = z * ratioA + this.z * ratioB;

		this._onChangeCallback();

		return this;
	}

	public function slerpQuaternions(qa:Quaternion, qb:Quaternion, t:Float):Quaternion {
		return this.copy(qa).slerp(qb, t);
	}

	public function random():Quaternion {
		// sets this quaternion to a uniform random unit quaternnion

		// <NAME>
		// Uniform random rotations
		// D. Kirk, editor, Graphics Gems III, pages 124-132. Academic Press, New York, 1992.

		var theta1 = 2.0 * Math.PI * Math.random();
		var theta2 = 2.0 * Math.PI * Math.random();

		var x0 = Math.random();
		var r1 = Math.sqrt(1.0 - x0);
		var r2 = Math.sqrt(x0);

		return this.set(
			r1 * Math.sin(theta1),
			r1 * Math.cos(theta1),
			r2 * Math.sin(theta2),
			r2 * Math.cos(theta2)
		);
	}

	public function equals(quaternion:Quaternion):Bool {
		return (quaternion.x == this.x) && (quaternion.y == this.y) && (quaternion.z == this.z) && (quaternion.w == this.w);
	}

	public function fromArray(array:FloatArray, offset:Int = 0):Quaternion {
		this.x = array[offset];
		this.y = array[offset + 1];
		this.z = array[offset + 2];
		this.w = array[offset + 3];

		this._onChangeCallback();

		return this;
	}

	public function toArray(?array:FloatArray, offset:Int = 0):FloatArray {
		if (array == null) array = [];

		array[offset] = this.x;
		array[offset + 1] = this.y;
		array[offset + 2] = this.z;
		array[offset + 3] = this.w;

		return array;
	}

	public function fromBufferAttribute(attribute:Float32BufferAttribute, index:Int):Quaternion {
		this.x = attribute.getX(index);
		this.y = attribute.getY(index);
		this.z = attribute.getZ(index);
		this.w = attribute.getW(index);

		this._onChangeCallback();

		return this;
	}

	public function toJSON():Array<Float> {
		return [this.x, this.y, this.z, this.w];
	}

	public function _onChange(callback:Void->Void):Quaternion {
		this._onChangeCallback = callback;

		return this;
	}

	public function _onChangeCallback():Void {
	}

	public function iterator():QuaternionIterator {
		return new QuaternionIterator(this);
	}
}

class QuaternionIterator {

	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public var index:Int;

	public function new(quaternion:Quaternion) {
		this.x = quaternion.x;
		this.y = quaternion.y;
		this.z = quaternion.z;
		this.w = quaternion.w;

		this.index = 0;
	}

	public function hasNext():Bool {
		return this.index < 4;
	}

	public function next():Float {
		switch (this.index++) {
			case 0: return this.x;
			case 1: return this.y;
			case 2: return this.z;
			case 3: return this.w;
		}

		throw "QuaternionIterator: Trying to access an out-of-bound value.";
	}
}

enum EulerOrder {
	XYZ,
	YXZ,
	ZXY,
	ZYX,
	YZX,
	XZY
}