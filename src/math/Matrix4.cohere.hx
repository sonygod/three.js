package;

import js.Browser;

class Matrix4 {
	public var elements:Array<Float> = [
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0
	];

	public function new(n11:Float, n12:Float, n13:Float, n14:Float, n21:Float, n22:Float, n23:Float, n24:Float, n31:Float, n32:Float, n33:Float, n34:Float, n41:Float, n42:Float, n43:Float, n44:Float) {
		if (n11 != null) {
			this.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
		}
	}

	public function set(n11:Float, n12:Float, n13:Float, n14:Float, n21:Float, n22:Float, n23:Float, n24:Float, n31:Float, n32:Float, n33:Float, n34:Float, n41:Float, n42:Float, n43:Float, n44:Float):Matrix4 {
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

	public function setFromMatrix3(m:Matrix4):Matrix4 {
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
		var scaleX = 1.0 / _v1.setFromMatrixColumn(m, 0).length();
		var scaleY = 1.0 / _v1.setFromMatrixColumn(m, 1).length();
		var scaleZ = 1.0 / _v1.setFromMatrixColumn(m, 2).length();
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

	public function makeRotationFromEuler(euler:Vector3):Matrix4 {
		var te = this.elements;
		var x = euler.x; var y = euler.y; var z = euler.z;
		var a = Math.cos(x); var b = Math.sin(x);
		var c = Math.cos(y); var d = Math.sin(y);
		var e = Math.cos(z); var f = Math.sin(z);
		if (euler.order == "XYZ") {
			var ae = a * e; var af = a * f; var be = b * e; var bf = b * f;
			te[0] = c * e;
			te[4] = -c * f;
			te[8] = d;
			te[1] = af + be * d;
			te[5] = ae - bf * d;
			te[9] = -b * c;
			te[2] = bf - ae * d;
			te[6] = be + af * d;
			te[10] = a * c;
		} else if (euler.order == "YXZ") {
			var ce = c * e; var cf = c * f; var de = d * e; var df = d * f;
			te[0] = ce + df * b;
			te[4] = de * b - cf;
			te[8] = a * d;
			te[1] = a * f;
			te[5] = a * e;
			te[9] = -b;
			te[2] = cf * b - de;
			te[6] = df + ce * b;
			te[10] = a * c;
		} else if (euler.order == "ZXY") {
			var ce = c * e; var cf = c * f; var de = d * e; var df = d * f;
			te[0] = ce - df * b;
			te[4] = -a * f;
			te[8] = de + cf * b;
			te[1] = cf + de * b;
			te[5] = a * e;
			te[9] = df - ce * b;
			te[2] = -a * d;
			te[6] = b;
			te[10] = a * c;
		} else if (euler.order == "ZYX") {
			var ae = a * e; var af = a * f; var be = b * e; var bf = b * f;
			te[0] = c * e;
			te[4] = be * d - af;
			te[8] = ae * d + bf;
			te[1] = c * f;
			te[5] = bf * d + ae;
			te[9] = af * d - be;
			te[2] = -d;
			te[6] = b * c;
			te[10] = a * c;
		} else if (euler.order == "YZX") {
			var ac = a * c; var ad = a * d; var bc = b * c; var bd = b * d;
			te[0] = c * e;
			te[4] = bd - ac * f;
			te[8] = bc * f + ad;
			te[1] = f;
			te[5] = a * e;
			te[9] = -b * e;
			te[2] = -d * e;
			te[6] = ad * f + bc;
			te[10] = ac - bd * f;
		} else if (euler.order == "XZY") {
			var ac = a * c; var ad = a * d; var bc = b * c; var bd = b * d;
			te[0] = c * e;
			te[4] = -f;
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

	public function makeRotationFromQuaternion(q:Vector3):Matrix4 {
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
		te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44