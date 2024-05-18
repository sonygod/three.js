import Vector3 from "./Vector3";

class Matrix4 {

	public var isMatrix4:Bool;
	public var elements:Array<Float>;

	public function new(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44) {
		this.isMatrix4 = true;
		this.elements = [
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		];
		if (n11 !== undefined) {
			this.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
		}
	}

	public function set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44):Matrix4 {
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

	// ... continue with the rest of the functions

}

var _v1 = new Vector3();
var _m1 = new Matrix4();
var _zero = new Vector3(0, 0, 0);
var _one = new Vector3(1, 1, 1);
var _x = new Vector3();
var _y = new Vector3();
var _z = new Vector3();