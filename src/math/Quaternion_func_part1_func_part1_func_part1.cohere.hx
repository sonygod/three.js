import MathUtils from './MathUtils';

class Quaternion {
	public isQuaternion:Bool;
	private _x:Float;
	private _y:Float;
	private _z:Float;
	private _w:Float;
	public _onChangeCallback:Void->Void;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.isQuaternion = true;
		this._x = x;
		this._y = y;
		this._z = z;
		this._w = w;
	}

	public static function slerpFlat(dst:Float->Float, dstOffset:Int, src0:Float->Float, srcOffset0:Int, src1:Float->Float, srcOffset1:Int, t:Float):Void {
		var x0 = src0(srcOffset0);
		var y0 = src0(srcOffset0 + 1);
		var z0 = src0(srcOffset0 + 2);
		var w0 = src0(srcOffset0 + 3);

		var x1 = src1(srcOffset1);
		var y1 = src1(srcOffset1 + 1);
		var z1 = src1(srcOffset1 + 2);
		var w1 = src1(srcOffset1 + 3);

		if (t == 0) {
			dst(dstOffset) = x0;
			dst(dstOffset + 1) = y0;
			dst(dstOffset + 2) = z0;
			dst(dstOffset + 3) = w0;
			return;
		}

		if (t == 1) {
			dst(dstOffset) = x1;
			dst(dstOffset + 1) = y1;
			dst(dstOffset + 2) = z1;
			dst(dstOffset + 3) = w1;
			return;
		}

		if (w0 != w1 || x0 != x1 || y0 != y1 || z0 != z1) {
			var s = 1 - t;
			var cos = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1;
			var dir = if (cos >= 0) 1 else -1;
			var sqrSin = 1 - cos * cos;

			// Skip the Slerp for tiny steps to avoid numeric problems:
			if (sqrSin > 0) {
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
			if (s == 1 - t) {
				var f = 1 / Math.sqrt(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0);

				x0 *= f;
				y0 *= f;
				z0 *= f;
				w0 *= f;
			}
		}

		dst(dstOffset) = x0;
		dst(dstOffset + 1) = y0;
		dst(dstOffset + 2) = z0;
		dst(dstOffset + 3) = w0;
	}

	public static function multiplyQuaternionsFlat(dst:Float->Float, dstOffset:Int, src0:Float->Float, srcOffset0:Int, src1:Float->Float, srcOffset1:Int):Float {
		var x0 = src0(srcOffset0);
		var y0 = src0(srcOffset0 + 1);
		var z0 = src0(srcOffset0 + 2);
		var w0 = src0(srcOffset0 + 3);

		var x1 = src1(srcOffset1);
		var y1 = src1(srcOffset1 + 1);
		var z1 = src1(srcOffset1 + 2);
		var w1 = src1(srcOffset1 + 3);

		dst(dstOffset) = x0 * w1 + w0 * x1 + y0 * z1 - z0 * y1;
		dst(dstOffset + 1) = y0 * w1 + w0 * y1 + z0 * x1 - x0 * z1;
		dst(dstOffset + 2) = z0 * w1 + w0 * z1 + x0 * y1 - y0 * x1;
		dst(dstOffset + 3) = w0 * w1 - x0 * x1 - y0 * y1 - z0 * z1;

		return dst;
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

	public function set(x:Float, y:Float, z:Float, w:Float):Void {
		_x = x;
		_y = y;
		_z = z;
		_w = w;

		_onChangeCallback();
	}

	public function clone():Quaternion {
		return new Quaternion(_x, _y, _z, _w);
	}

	public function copy(quaternion:Quaternion):Quaternion {
		_x = quaternion.x;
		_y = quaternion.y;
		_z = quaternion.z;
		_w = quaternion.w;

		_onChangeCallback();

		return this;
	}

	public function setFromEuler(euler:Float, update:Bool = true):Void {
		var x = euler.x;
		var y = euler.y;
		var z = euler.z;
		var order = euler.order;

		// http://www.mathworks.com/matlabcentral/fileexchange/
		// 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
		//	content/SpinCalc.m

		var cos = Math.cos;
		var sin = Math.sin;

		var c1 = cos(x / 2);
		var c2 = cos(y / 2);
		var c3 = cos(z / 2);

		var s1 = sin(x / 2);
		var s2 = sin(y / 2);
		var s3 = sin(z / 2);

		switch (order) {
			case 'XYZ':
				_x = s1 * c2 * c3 + c1 * s2 * s3;
				_y = c1 * s2 * c3 - s1 * c2 * s3;
				_z = c1 * c2 * s3 + s1 * s2 * c3;
				_w = c1 * c2 * c3 - s1 * s2 * s3;
				break;

			case 'YXZ':
				_x = s1 * c2 * c3 + c1 * s2 * s3;
				_y = c1 * s2 * c3 - s1 * c2 * s3;
				_z = c1 * c2 * s3 - s1 * s2 * c3;
				_w = c1 * c2 * c3 + s1 * s2 * s3;
				break;

			case 'ZXY':
				_x = s1 * c2 * c3 - c1 * s2 * s3;
				_y = c1 * s2 * c3 + s1 * c2 * s3;
				_z = c1 * c2 * s3 + s1 * s2 * c3;
				_w = c1 * c2 * c3 - s1 * s2 * s3;
				break;

			case 'ZYX':
				_x = s1 * c2 * c3 - c1 * s2 * s3;
				_y = c1 * s2 * c3 + s1 * c2 * s3;
				_z = c1 * c2 * s3 - s1 * s2 * c3;
				_w = c1 * c2 * c3 + s1 * s2 * s3;
				break;

			case 'YZX':
				_x = s1 * c2 * c3 + c1 * s2 * s3;
				_y = c1 * s2 * c3 + s1 * c2 * s3;
				_z = c1 * c2 * s3 - s1 * s2 * c3;
				_w = c1 * c2 * c3 - s1 * s2 * s3;
				break;

			case 'XZY':
				_x = s1 * c2 * c3 - c1 * s2 * s3;
				_y = c1 * s2 * c3 - s1 * c2 * s3;
				_z = c1 * c2 * s3 + s1 * s2 * c3;
				_w = c1 * c2 * c3 + s1 * s2 * s3;
				break;

			default:
				throw "Quaternion.setFromEuler: unknown order: $order";
		}

		if (update) {
			_onChangeCallback();
		}
	}

	public function setFromAxisAngle(axis:Float, angle:Float):Void {
		// http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm

		// assumes axis is normalized

		var halfAngle = angle / 2;
		var s = Math.sin(halfAngle);

		_x = axis.x * s;
		_y = axis.y * s;
		_z = axis.z * s;
		_w = Math.cos(halfAngle);

		_onChangeCallback();
	}

	public function setFromRotationMatrix(m:Float):Void {
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

		if (trace > 0) {
			var s = 0.5 / Math.sqrt(trace + 1.0);

			_w = 0.25 / s;
			_x = (m32 - m23) * s;
			_y = (m13 - m31) * s;
			_z = (m21 - m12) * s;
		} else if (m11 > m22 && m11 > m33) {
			var s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);

			_w = (m32 - m23) / s;
			_x = 0.25 * s;
			_y = (m12 + m21) / s;
			_z = (m13 + m31) / s;
		} else if (m22 > m33) {
			var s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);

			_w = (m13 - m31) / s;
			_x = (m12 + m21) / s;
			_y = 0.25 * s;
			_z = (m23 + m32) / s;
		} else {
			var s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);

			_w = (m21 - m12) / s;
			_x = (m13 + m31) / s;
			_y = (m23 + m32) / s;
			_z = 0.25 * s;
		}

		_onChangeCallback();
	}

	public function setFromUnitVectors(vFrom:Float, vTo:Float):Void {
		// assumes direction vectors vFrom and vTo are normalized

		var r = vFrom.dot(vTo) + 1;

		if (r < 0) {
			// vFrom and vTo point in opposite directions

			r = 0;

			if (Math.abs(vFrom.x) > Math.abs(vFrom.z)) {
				_x = -vFrom.y;
				_y = vFrom.x;
				_z = 0;
				_w = r;
			} else {
				_x = 0;
				_y = -vFrom.z;
				_z = vFrom.y;
				_w = r;
			}
		} else {
			// crossVectors(vFrom, vTo); // inlined to avoid cyclic dependency on Vector3

			_x = vFrom.y * vTo.z - vFrom.z * vTo.y;
			_y = vFrom.z * vTo.x - vFrom.x * vTo.z;
			_z = vFrom.x * vTo.y - vFrom.y * vTo.x;
			_w = r;
		}

		return this.normalize();
	}

	public function angleTo(q:Float):Float {
		return 2 * Math.acos(Math.abs(MathUtils.clamp(this.dot(q), -1, 1)));
	}

	public function rotateTowards(q:Float, step:Float):Float {
		var angle = this.angleTo(q);

		if (angle == 0) return this;

		var t = Math.min(1, step / angle);

		this.slerp(q, t);

		return this;
	}

	public function identity():Float {
		return this.set(0, 0, 0, 1);
	}

	public function invert():Float {
		// quaternion is assumed to have unit length

		return this.conjugate();
	}

	public function conjugate():Float {
		_x *= -1;
		_y *= -1;
		_z *= -1;

		_onChangeCallback();
	}

	public function dot(v:Float):Float {
		return _x * v._x + _y * v._y + _z * v._z + _w * v._w;
	}

	public function lengthSq():Float {
		return _x * _x + _y * _y + _z * _z + _w * _w;
	}

	public function length():Float {
		return Math.sqrt(_x * _x + _y * _y + _z * _z + _w * _w);
	}

	public function normalize():Float {
		var l = this.length();

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
	}

	public function multiply(q:Float):Float {
		return this.multiplyQuaternions(this, q);
	}

	public function premultiply(
	public function premultiply(q:Float):Float {
		return this.multiplyQuaternions(q, this);
	}

	public function multiplyQuaternions(a:Float, b:Float):Float {
		// from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

		var qax = a._x;
		var qay = a._y;
		var qaz = a._z;
		var qaw = a._w;
		var qbx = b._x;
		var qby = b._y;
		var qbz = b._z;
		var qbw = b._w;

		_x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
		_y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
		_z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
		_w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;

		_onChangeCallback();
	}

	public function slerp(qb:Float, t:Float):Float {
		if (t == 0) return this;
		if (t == 1) return this.copy(qb);

		var x = _x;
		var y = _y;
		var z = _z;
		var w = _w;

		// http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/

		var cosHalfTheta = w * qb._w + x * qb._x + y * qb._y + z * qb._z;

		if (cosHalfTheta < 0) {
			_w = -qb._w;
			_x = -qb._x;
			_y = -qb._y;
			_z = -qb._z;

			cosHalfTheta = -cosHalfTheta;
		} else {
			this.copy(qb);
		}

		if (cosHalfTheta >= 1.0) {
			_w = w;
			_x = x;
			_y = y;
			_z = z;

			return this;
		}

		var sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta;

		if (sqrSinHalfTheta <= 0) {
			var s = 1 - t;
			_w = s * w + t * _w;
			_x = s * x + t * _x;
			_y = s * y + t * _y;
			_z = s * z + t * _z;

			this.normalize(); // normalize calls _onChangeCallback()

			return this;
		}

		var sinHalfTheta = Math.sqrt(sqrSinHalfTheta);
		var halfTheta = Math.atan2(sinHalfTheta, cosHalfTheta);
		var ratioA = Math.sin((1 - t) * halfTheta) / sinHalfTheta;
		var ratioB = Math.sin(t * halfTheta) / sinHalfTheta;

		_w = w * ratioA + _w * ratioB;
		_x = x * ratioA + _x * ratioB;
		_y = y * ratioA + _y * ratioB;
		_z = z * ratioA + _z * ratioB;

		_onChangeCallback();
	}

	public function slerpQuaternions(qa:Float, qb:Float, t:Float):Float {
		return this.copy(qa).slerp(qb, t);
	}

	public function random():Float {
		// sets this quaternion to a uniform random unit quaternnion

		// <NAME>
		// Uniform random rotations
		// D. Kirk, editor, Graphics Gems III, pages 124-132. Academic Press, New York, 1992.

		var theta1 = 2 * Math.PI * Math.random();
		var theta2 = 2 * Math.PI * Math.random();

		var x0 = Math.random();
		var r1 = Math.sqrt(1 - x0);
		var r2 = Math.sqrt(x0);

		return this.set(
			r1 * Math.sin(theta1),
			r1 * Math.cos(theta1),
			r2 * Math.sin(theta2),
			r2 * Math.cos(theta2)
		);
	}

	public function equals(quaternion:Float):Bool {
		return (_x == quaternion._x) && (_y == quaternion._y) && (_z == quaternion._z) && (_w == quaternion._w);
	}

	public function fromArray(array:Float, offset:Int = 0):Float {
		_x = array[offset];
		_y = array[offset + 1];
		_z = array[offset + 2];
		_w = array[offset + 3];

		_onChangeCallback();
	}

	public function toArray(array:Float = [], offset:Int = 0):Float {
		array[offset] = _x;
		array[offset + 1] = _y;
		array[offset + 2] = _z;
		array[offset + 3] = _w;

		return array;
	}

	public function fromBufferAttribute(attribute:Float, index:Int):Float {
		_x = attribute.getX(index);
		_y = attribute.getY(index);
		_z = attribute.getZ(index);
		_w = attribute.getW(index);

		_onChangeCallback();
	}

	public function toJSON():Float {
		return this.toArray();
	}

	public function _onChange(callback:Void->Void):Float {
		_onChangeCallback = callback;
	}

	public function _onChangeCallback():Void {
	}

	public function iterator():Float {
		yield _x;
		yield _y;
		yield _z;
		yield _w;
	}
}

export { Quaternion };