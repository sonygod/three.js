import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.math.Vector3;

class Matrix4 {

	public var isMatrix4:Bool = true;

	public var elements:Array<Float> = [
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	];

	public function new(n11:Null<Float> = null, n12:Null<Float> = null, n13:Null<Float> = null, n14:Null<Float> = null,
		n21:Null<Float> = null, n22:Null<Float> = null, n23:Null<Float> = null, n24:Null<Float> = null,
		n31:Null<Float> = null, n32:Null<Float> = null, n33:Null<Float> = null, n34:Null<Float> = null,
		n41:Null<Float> = null, n42:Null<Float> = null, n43:Null<Float> = null, n44:Null<Float> = null) {

		if (n11 != null) {
			this.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
		}

	}

	public function set(n11:Float, n12:Float, n13:Float, n14:Float, n21:Float, n22:Float, n23:Float, n24:Float,
		n31:Float, n32:Float, n33:Float, n34:Float, n41:Float, n42:Float, n43:Float, n44:Float):Matrix4 {

		var te = this.elements;

		te[0] = n11; te[4] = n12; te[8] = n13; te[12] = n14;
		te[1] = n21; te[5] = n22; te[9] = n23; te[13] = n24;
		te[2] = n31; te[6] = n32; te[10] = n33; te[14] = n34;
		te[3] = n41; te[7] = n42; te[11] = n43; te[15] = n44;

		return this;

	}

	public function identity():Matrix4 {

		this.set(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function clone():Matrix4 {

		return new Matrix4().fromArray(this.elements);

	}

	public function copy(m:Matrix4):Matrix4 {

		var te = this.elements;
		var me = m.elements;

		te[0] = me[0]; te[1] = me[1]; te[2] = me[2]; te[3] = me[3];
		te[4] = me[4]; te[5] = me[5]; te[6] = me[6]; te[7] = me[7];
		te[8] = me[8]; te[9] = me[9]; te[10] = me[10]; te[11] = me[11];
		te[12] = me[12]; te[13] = me[13]; te[14] = me[14]; te[15] = me[15];

		return this;

	}

	public function copyPosition(m:Matrix4):Matrix4 {

		var te = this.elements;
		var me = m.elements;

		te[12] = me[12];
		te[13] = me[13];
		te[14] = me[14];

		return this;

	}

	public function setFromMatrix3(m:Matrix3):Matrix4 {

		var me = m.elements;

		this.set(
			me[0], me[3], me[6], 0,
			me[1], me[4], me[7], 0,
			me[2], me[5], me[8], 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function extractBasis(xAxis:Vector3, yAxis:Vector3, zAxis:Vector3):Matrix4 {

		xAxis.setFromMatrixColumn(this, 0);
		yAxis.setFromMatrixColumn(this, 1);
		zAxis.setFromMatrixColumn(this, 2);

		return this;

	}

	public function makeBasis(xAxis:Vector3, yAxis:Vector3, zAxis:Vector3):Matrix4 {

		this.set(
			xAxis.x, yAxis.x, zAxis.x, 0,
			xAxis.y, yAxis.y, zAxis.y, 0,
			xAxis.z, yAxis.z, zAxis.z, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function extractRotation(m:Matrix4):Matrix4 {

		// this method does not support reflection matrices

		var te = this.elements;
		var me = m.elements;

		var scaleX = 1 / _v1.setFromMatrixColumn(m, 0).length();
		var scaleY = 1 / _v1.setFromMatrixColumn(m, 1).length();
		var scaleZ = 1 / _v1.setFromMatrixColumn(m, 2).length();

		te[0] = me[0] * scaleX;
		te[1] = me[1] * scaleX;
		te[2] = me[2] * scaleX;
		te[3] = 0;

		te[4] = me[4] * scaleY;
		te[5] = me[5] * scaleY;
		te[6] = me[6] * scaleY;
		te[7] = 0;

		te[8] = me[8] * scaleZ;
		te[9] = me[9] * scaleZ;
		te[10] = me[10] * scaleZ;
		te[11] = 0;

		te[12] = 0;
		te[13] = 0;
		te[14] = 0;
		te[15] = 1;

		return this;

	}

	public function makeRotationFromEuler(euler:Euler):Matrix4 {

		var te = this.elements;

		var x = euler.x;
		var y = euler.y;
		var z = euler.z;
		var a = Math.cos(x);
		var b = Math.sin(x);
		var c = Math.cos(y);
		var d = Math.sin(y);
		var e = Math.cos(z);
		var f = Math.sin(z);

		if (euler.order == "XYZ") {

			var ae = a * e;
			var af = a * f;
			var be = b * e;
			var bf = b * f;

			te[0] = c * e;
			te[4] = - c * f;
			te[8] = d;

			te[1] = af + be * d;
			te[5] = ae - bf * d;
			te[9] = - b * c;

			te[2] = bf - ae * d;
			te[6] = be + af * d;
			te[10] = a * c;

		} else if (euler.order == "YXZ") {

			var ce = c * e;
			var cf = c * f;
			var de = d * e;
			var df = d * f;

			te[0] = ce + df * b;
			te[4] = de * b - cf;
			te[8] = a * d;

			te[1] = a * f;
			te[5] = a * e;
			te[9] = - b;

			te[2] = cf * b - de;
			te[6] = df + ce * b;
			te[10] = a * c;

		} else if (euler.order == "ZXY") {

			var ce = c * e;
			var cf = c * f;
			var de = d * e;
			var df = d * f;

			te[0] = ce - df * b;
			te[4] = - a * f;
			te[8] = de + cf * b;

			te[1] = cf + de * b;
			te[5] = a * e;
			te[9] = df - ce * b;

			te[2] = - a * d;
			te[6] = b;
			te[10] = a * c;

		} else if (euler.order == "ZYX") {

			var ae = a * e;
			var af = a * f;
			var be = b * e;
			var bf = b * f;

			te[0] = c * e;
			te[4] = be * d - af;
			te[8] = ae * d + bf;

			te[1] = c * f;
			te[5] = bf * d + ae;
			te[9] = af * d - be;

			te[2] = - d;
			te[6] = b * c;
			te[10] = a * c;

		} else if (euler.order == "YZX") {

			var ac = a * c;
			var ad = a * d;
			var bc = b * c;
			var bd = b * d;

			te[0] = c * e;
			te[4] = bd - ac * f;
			te[8] = bc * f + ad;

			te[1] = f;
			te[5] = a * e;
			te[9] = - b * e;

			te[2] = - d * e;
			te[6] = ad * f + bc;
			te[10] = ac - bd * f;

		} else if (euler.order == "XZY") {

			var ac = a * c;
			var ad = a * d;
			var bc = b * c;
			var bd = b * d;

			te[0] = c * e;
			te[4] = - f;
			te[8] = d * e;

			te[1] = ac * f + bd;
			te[5] = a * e;
			te[9] = ad * f - bc;

			te[2] = bc * f - ad;
			te[6] = b * e;
			te[10] = bd * f + ac;

		}

		// bottom row
		te[3] = 0;
		te[7] = 0;
		te[11] = 0;

		// last column
		te[12] = 0;
		te[13] = 0;
		te[14] = 0;
		te[15] = 1;

		return this;

	}

	public function makeRotationFromQuaternion(q:Quaternion):Matrix4 {

		return this.compose(_zero, q, _one);

	}

	public function lookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix4 {

		var te = this.elements;

		_z.subVectors(eye, target);

		if (_z.lengthSq() == 0) {

			// eye and target are in the same position

			_z.z = 1;

		}

		_z.normalize();
		_x.crossVectors(up, _z);

		if (_x.lengthSq() == 0) {

			// up and z are parallel

			if (Math.abs(up.z) == 1) {

				_z.x += 0.0001;

			} else {

				_z.z += 0.0001;

			}

			_z.normalize();
			_x.crossVectors(up, _z);

		}

		_x.normalize();
		_y.crossVectors(_z, _x);

		te[0] = _x.x; te[4] = _y.x; te[8] = _z.x;
		te[1] = _x.y; te[5] = _y.y; te[9] = _z.y;
		te[2] = _x.z; te[6] = _y.z; te[10] = _z.z;

		return this;

	}

	public function multiply(m:Matrix4):Matrix4 {

		return this.multiplyMatrices(this, m);

	}

	public function premultiply(m:Matrix4):Matrix4 {

		return this.multiplyMatrices(m, this);

	}

	public function multiplyMatrices(a:Matrix4, b:Matrix4):Matrix4 {

		var ae = a.elements;
		var be = b.elements;
		var te = this.elements;

		var a11 = ae[0]; var a12 = ae[4]; var a13 = ae[8]; var a14 = ae[12];
		var a21 = ae[1]; var a22 = ae[5]; var a23 = ae[9]; var a24 = ae[13];
		var a31 = ae[2]; var a32 = ae[6]; var a33 = ae[10]; var a34 = ae[14];
		var a41 = ae[3]; var a42 = ae[7]; var a43 = ae[11]; var a44 = ae[15];

		var b11 = be[0]; var b12 = be[4]; var b13 = be[8]; var b14 = be[12];
		var b21 = be[1]; var b22 = be[5]; var b23 = be[9]; var b24 = be[13];
		var b31 = be[2]; var b32 = be[6]; var b33 = be[10]; var b34 = be[14];
		var b41 = be[3]; var b42 = be[7]; var b43 = be[11]; var b44 = be[15];

		te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

		return this;

	}

	public function multiplyScalar(s:Float):Matrix4 {

		var te = this.elements;

		te[0] *= s; te[4] *= s; te[8] *= s; te[12] *= s;
		te[1] *= s; te[5] *= s; te[9] *= s; te[13] *= s;
		te[2] *= s; te[6] *= s; te[10] *= s; te[14] *= s;
		te[3] *= s; te[7] *= s; te[11] *= s; te[15] *= s;

		return this;

	}

	public function determinant():Float {

		var te = this.elements;

		var n11 = te[0]; var n12 = te[4]; var n13 = te[8]; var n14 = te[12];
		var n21 = te[1]; var n22 = te[5]; var n23 = te[9]; var n24 = te[13];
		var n31 = te[2]; var n32 = te[6]; var n33 = te[10]; var n34 = te[14];
		var n41 = te[3]; var n42 = te[7]; var n43 = te[11]; var n44 = te[15];

		//TODO: make this more efficient
		//( based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm )

		return (
			n41 * (
				+ n14 * n23 * n32
				 - n13 * n24 * n32
				 - n14 * n22 * n33
				 + n12 * n24 * n33
				 + n13 * n22 * n34
				 - n12 * n23 * n34
			) +
			n42 * (
				+ n11 * n23 * n34
				 - n11 * n24 * n33
				 + n14 * n21 * n33
				 - n13 * n21 * n34
				 + n13 * n24 * n31
				 - n14 * n23 * n31
			) +
			n43 * (
				+ n11 * n24 * n32
				 - n11 * n22 * n34
				 - n14 * n21 * n32
				 + n12 * n21 * n34
				 + n14 * n22 * n31
				 - n12 * n24 * n31
			) +
			n44 * (
				- n13 * n22 * n31
				 - n11 * n23 * n32
				 + n11 * n22 * n33
				 + n13 * n21 * n32
				 - n12 * n21 * n33
				 + n12 * n23 * n31
			)

		);

	}

	public function transpose():Matrix4 {

		var te = this.elements;
		var tmp:Float;

		tmp = te[1]; te[1] = te[4]; te[4] = tmp;
		tmp = te[2]; te[2] = te[8]; te[8] = tmp;
		tmp = te[6]; te[6] = te[9]; te[9] = tmp;

		tmp = te[3]; te[3] = te[12]; te[12] = tmp;
		tmp = te[7]; te[7] = te[13]; te[13] = tmp;
		tmp = te[11]; te[11] = te[14]; te[14] = tmp;

		return this;

	}

	public function setPosition(x:Dynamic, y:Dynamic, z:Dynamic):Matrix4 {

		var te = this.elements;

		if (Std.isOfType(x, Vector3)) {

			te[12] = x.x;
			te[13] = x.y;
			te[14] = x.z;

		} else {

			te[12] = x;
			te[13] = y;
			te[14] = z;

		}

		return this;

	}

	public function invert():Matrix4 {

		// based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
		var te = this.elements;

		var n11 = te[0]; var n21 = te[1]; var n31 = te[2]; var n41 = te[3];
		var n12 = te[4]; var n22 = te[5]; var n32 = te[6]; var n42 = te[7];
		var n13 = te[8]; var n23 = te[9]; var n33 = te[10]; var n43 = te[11];
		var n14 = te[12]; var n24 = te[13]; var n34 = te[14]; var n44 = te[15];

		var t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
		var t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
		var t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
		var t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

		var det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;

		if (det == 0) return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

		var detInv = 1 / det;

		te[0] = t11 * detInv;
		te[1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * detInv;
		te[2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * detInv;
		te[3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * detInv;

		te[4] = t12 * detInv;
		te[5] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * detInv;
		te[6] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * detInv;
		te[7] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * detInv;

		te[8] = t13 * detInv;
		te[9] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * detInv;
		te[10] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * detInv;
		te[11] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * detInv;

		te[12] = t14 * detInv;
		te[13] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * detInv;
		te[14] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * detInv;
		te[15] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * detInv;

		return this;

	}

	public function scale(v:Vector3):Matrix4 {

		var te = this.elements;
		var x = v.x;
		var y = v.y;
		var z = v.z;

		te[0] *= x; te[4] *= y; te[8] *= z;
		te[1] *= x; te[5] *= y; te[9] *= z;
		te[2] *= x; te[6] *= y; te[10] *= z;
		te[3] *= x; te[7] *= y; te[11] *= z;

		return this;

	}

	public function getMaxScaleOnAxis():Float {

		var te = this.elements;

		var scaleXSq = te[0] * te[0] + te[1] * te[1] + te[2] * te[2];
		var scaleYSq = te[4] * te[4] + te[5] * te[5] + te[6] * te[6];
		var scaleZSq = te[8] * te[8] + te[9] * te[9] + te[10] * te[10];

		return Math.sqrt(Math.max(scaleXSq, scaleYSq, scaleZSq));

	}

	public function makeTranslation(x:Dynamic, y:Dynamic, z:Dynamic):Matrix4 {

		if (Std.isOfType(x, Vector3)) {

			this.set(
				1, 0, 0, x.x,
				0, 1, 0, x.y,
				0, 0, 1, x.z,
				0, 0, 0, 1
			);

		} else {

			this.set(
				1, 0, 0, x,
				0, 1, 0, y,
				0, 0, 1, z,
				0, 0, 0, 1
			);

		}

		return this;

	}

	public function makeRotationX(theta:Float):Matrix4 {

		var c = Math.cos(theta);
		var s = Math.sin(theta);

		this.set(
			1, 0, 0, 0,
			0, c, - s, 0,
			0, s, c, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function makeRotationY(theta:Float):Matrix4 {

		var c = Math.cos(theta);
		var s = Math.sin(theta);

		this.set(
			c, 0, s, 0,
			0, 1, 0, 0,
			- s, 0, c, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function makeRotationZ(theta:Float):Matrix4 {

		var c = Math.cos(theta);
		var s = Math.sin(theta);

		this.set(
			c, - s, 0, 0,
			s, c, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function makeRotationAxis(axis:Vector3, angle:Float):Matrix4 {

		// Based on http://www.gamedev.net/reference/articles/article1199.asp

		var c = Math.cos(angle);
		var s = Math.sin(angle);
		var t = 1 - c;
		var x = axis.x;
		var y = axis.y;
		var z = axis.z;
		var tx = t * x;
		var ty = t * y;

		this.set(
			tx * x + c, tx * y - s * z, tx * z + s * y, 0,
			tx * y + s * z, ty * y + c, ty * z - s * x, 0,
			tx * z - s * y, ty * z + s * x, t * z * z + c, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function makeScale(x:Float, y:Float, z:Float):Matrix4 {

		this.set(
			x, 0, 0, 0,
			0, y, 0, 0,
			0, 0, z, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function makeShear(xy:Float, xz:Float, y
	public function makeShear(xy:Float, xz:Float, yx:Float, yz:Float, zx:Float, zy:Float):Matrix4 {

		this.set(
			1, yx, zx, 0,
			xy, 1, zy, 0,
			xz, yz, 1, 0,
			0, 0, 0, 1
		);

		return this;

	}

	public function compose(position:Vector3, quaternion:Quaternion, scale:Vector3):Matrix4 {

		var te = this.elements;

		var x = quaternion._x;
		var y = quaternion._y;
		var z = quaternion._z;
		var w = quaternion._w;
		var x2 = x + x;
		var y2 = y + y;
		var z2 = z + z;
		var xx = x * x2;
		var xy = x * y2;
		var xz = x * z2;
		var yy = y * y2;
		var yz = y * z2;
		var zz = z * z2;
		var wx = w * x2;
		var wy = w * y2;
		var wz = w * z2;

		var sx = scale.x;
		var sy = scale.y;
		var sz = scale.z;

		te[0] = (1 - (yy + zz)) * sx;
		te[1] = (xy + wz) * sx;
		te[2] = (xz - wy) * sx;
		te[3] = 0;

		te[4] = (xy - wz) * sy;
		te[5] = (1 - (xx + zz)) * sy;
		te[6] = (yz + wx) * sy;
		te[7] = 0;

		te[8] = (xz + wy) * sz;
		te[9] = (yz - wx) * sz;
		te[10] = (1 - (xx + yy)) * sz;
		te[11] = 0;

		te[12] = position.x;
		te[13] = position.y;
		te[14] = position.z;
		te[15] = 1;

		return this;

	}

	public function decompose(position:Vector3, quaternion:Quaternion, scale:Vector3):Matrix4 {

		var te = this.elements;

		var sx = _v1.set(te[0], te[1], te[2]).length();
		var sy = _v1.set(te[4], te[5], te[6]).length();
		var sz = _v1.set(te[8], te[9], te[10]).length();

		// if determine is negative, we need to invert one scale
		var det = this.determinant();
		if (det < 0) sx = - sx;

		position.x = te[12];
		position.y = te[13];
		position.z = te[14];

		// scale the rotation part
		_m1.copy(this);

		var invSX = 1 / sx;
		var invSY = 1 / sy;
		var invSZ = 1 / sz;

		_m1.elements[0] *= invSX;
		_m1.elements[1] *= invSX;
		_m1.elements[2] *= invSX;

		_m1.elements[4] *= invSY;
		_m1.elements[5] *= invSY;
		_m1.elements[6] *= invSY;

		_m1.elements[8] *= invSZ;
		_m1.elements[9] *= invSZ;
		_m1.elements[10] *= invSZ;

		quaternion.setFromRotationMatrix(_m1);

		scale.x = sx;
		scale.y = sy;
		scale.z = sz;

		return this;

	}

	public function makePerspective(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float, coordinateSystem:WebGLCoordinateSystem = WebGLCoordinateSystem.WebGLCoordinateSystem) {

		var te = this.elements;
		var x = 2 * near / (right - left);
		var y = 2 * near / (top - bottom);

		var a = (right + left) / (right - left);
		var b = (top + bottom) / (top - bottom);

		var c:Float, d:Float;

		if (coordinateSystem == WebGLCoordinateSystem.WebGLCoordinateSystem) {

			c = - (far + near) / (far - near);
			d = (- 2 * far * near) / (far - near);

		} else if (coordinateSystem == WebGLCoordinateSystem.WebGPUCoordinateSystem) {

			c = - far / (far - near);
			d = (- far * near) / (far - near);

		} else {

			throw new Error('THREE.Matrix4.makePerspective(): Invalid coordinate system: ' + coordinateSystem);

		}

		te[0] = x; te[4] = 0; te[8] = a; te[12] = 0;
		te[1] = 0; te[5] = y; te[9] = b; te[13] = 0;
		te[2] = 0; te[6] = 0; te[10] = c; te[14] = d;
		te[3] = 0; te[7] = 0; te[11] = - 1; te[15] = 0;

		return this;

	}

	public function makeOrthographic(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float, coordinateSystem:WebGLCoordinateSystem = WebGLCoordinateSystem.WebGLCoordinateSystem) {

		var te = this.elements;
		var w = 1.0 / (right - left);
		var h = 1.0 / (top - bottom);
		var p = 1.0 / (far - near);

		var x = (right + left) * w;
		var y = (top + bottom) * h;

		var z:Float, zInv:Float;

		if (coordinateSystem == WebGLCoordinateSystem.WebGLCoordinateSystem) {

			z = (far + near) * p;
			zInv = - 2 * p;

		} else if (coordinateSystem == WebGLCoordinateSystem.WebGPUCoordinateSystem) {

			z = near * p;
			zInv = - 1 * p;

		} else {

			throw new Error('THREE.Matrix4.makeOrthographic(): Invalid coordinate system: ' + coordinateSystem);

		}

		te[0] = 2 * w; te[4] = 0; te[8] = 0; te[12] = - x;
		te[1] = 0; te[5] = 2 * h; te[9] = 0; te[13] = - y;
		te[2] = 0; te[6] = 0; te[10] = zInv; te[14] = - z;
		te[3] = 0; te[7] = 0; te[11] = 0; te[15] = 1;

		return this;

	}

	public function equals(matrix:Matrix4):Bool {

		var te = this.elements;
		var me = matrix.elements;

		for (var i = 0; i < 16; i++) {

			if (te[i] != me[i]) return false;

		}

		return true;

	}

	public function fromArray(array:Array<Float>, offset:Int = 0):Matrix4 {

		for (var i = 0; i < 16; i++) {

			this.elements[i] = array[i + offset];

		}

		return this;

	}

	public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {

		var te = this.elements;

		array[offset] = te[0];
		array[offset + 1] = te[1];
		array[offset + 2] = te[2];
		array[offset + 3] = te[3];

		array[offset + 4] = te[4];
		array[offset + 5] = te[5];
		array[offset + 6] = te[6];
		array[offset + 7] = te[7];

		array[offset + 8] = te[8];
		array[offset + 9] = te[9];
		array[offset + 10] = te[10];
		array[offset + 11] = te[11];

		array[offset + 12] = te[12];
		array[offset + 13] = te[13];
		array[offset + 14] = te[14];
		array[offset + 15] = te[15];

		return array;

	}

}

var _v1 = new Vector3();
var _m1 = new Matrix4();
var _zero = new Vector3(0, 0, 0);
var _one = new Vector3(1, 1, 1);
var _x = new Vector3();
var _y = new Vector3();
var _z = new Vector3();

export {Matrix4};