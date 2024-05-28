import MathUtils.clamp;

class Euler {
	public var isEuler:Bool = true;
	private var _x:Float;
	private var _y:Float;
	private var _z:Float;
	private var _order:String;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, order:String = Euler.DEFAULT_ORDER) {
		this._x = x;
		this._y = y;
		this._z = z;
		this._order = order;
	}

	public function get x():Float {
		return _x;
	}

	public function set x(value:Float) {
		_x = value;
		_onChangeCallback();
	}

	public function get y():Float {
		return _y;
	}

	public function set y(value:Float) {
		_y = value;
		_onChangeCallback();
	}

	public function get z():Float {
		return _z;
	}

	public function set z(value:Float) {
		_z = value;
		_onChangeCallback();
	}

	public function get order():String {
		return _order;
	}

	public function set order(value:String) {
		_order = value;
		_onChangeCallback();
	}

	public function set(x:Float, y:Float, z:Float, order:String = _order):Void {
		_x = x;
		_y = y;
		_z = z;
		_order = order;
		_onChangeCallback();
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

	public function setFromRotationMatrix(m:Matrix4, order:String = _order, update:Bool = true):Euler {
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
			case "XYZ":
				_y = Math.asin(clamp(m13, -1, 1));

				if (Math.abs(m13) < 0.9999999) {
					_x = Math.atan2(-m23, m33);
					_z = Math.atan2(-m12, m11);
				} else {
					_x = Math.atan2(m32, m22);
					_z = 0;
				}

				break;

			case "YXZ":
				_x = Math.asin(-clamp(m23, -1, 1));

				if (Math.abs(m23) < 0.9999999) {
					_y = Math.atan2(m13, m33);
					_z = Math.atan2(m21, m22);
				} else {
					_y = Math.atan2(-m31, m11);
					_z = 0;
				}

				break;

			case "ZXY":
				_x = Math.asin(clamp(m32, -1, 1));

				if (Math.abs(m32) < 0.9999999) {
					_y = Math.atan2(-m31, m33);
					_z = Math.atan2(-m12, m22);
				} else {
					_y = 0;
					_z = Math.atan2(m21, m11);
				}

				break;

			case "ZYX":
				_y = Math.asin(-clamp(m31, -1, 1));

				if (Math.abs(m31) < 0.9999999) {
					_x = Math.atan2(m32, m33);
					_z = Math.atan2(m21, m11);
				} else {
					_x = 0;
					_z = Math.atan2(-m12, m22);
				}

				break;

			case "YZX":
				_z = Math.asin(clamp(m21, -1, 1));

				if (Math.abs(m21) < 0.9999999) {
					_x = Math.atan2(-m23, m22);
					_y = Math.atan2(-m31, m11);
				} else {
					_x = 0;
					_y = Math.atan2(m13, m33);
				}

				break;

			case "XZY":
				_z = Math.asin(-clamp(m12, -1, 1));

				if (Math.abs(m12) < 0.9999999) {
					_x = Math.atan2(m32, m22);
					_y = Math.atan2(m13, m11);
				} else {
					_x = Math.atan2(-m23, m33);
					_y = 0;
				}

				break;

			default:
				throw "Euler.setFromRotationMatrix: Unknown order: $order";
		}

		_order = order;

		if (update) {
			_onChangeCallback();
		}

		return this;
	}

	public function setFromQuaternion(q:Quaternion, order:String, update:Bool):Euler {
		var matrix = new Matrix4();
		matrix.makeRotationFromQuaternion(q);
		return this.setFromRotationMatrix(matrix, order, update);
	}

	public function setFromVector3(v:Vector3, order:String = _order):Euler {
		return this.set(v.x, v.y, v.z, order);
	}

	public function reorder(newOrder:String):Euler {
		var quaternion = new Quaternion();
		quaternion.setFromEuler(this);
		return this.setFromQuaternion(quaternion, newOrder);
	}

	public function equals(euler:Euler):Bool {
		return (euler._x == _x) && (euler._y == _y) && (euler._z == _z) && (euler._order == _order);
	}

	public function fromArray(array:Array<Float>):Euler {
		_x = array[0];
		_y = array[1];
		_z = array[2];
		if (array.length > 3) {
			_order = array[3];
		}

		_onChangeCallback();
		return this;
	}

	public function toArray(array:Array<Float> = null, offset:Int = 0):Array<Float> {
		if (array == null) {
			array = [];
		}

		array[offset] = _x;
		array[offset + 1] = _y;
		array[offset + 2] = _z;
		array[offset + 3] = _order;

		return array;
	}

	public function _onChange(callback:Void -> Void):Euler {
		_onChangeCallback = callback;
		return this;
	}

	private function _onChangeCallback():Void {}

	public function iterator():Iterator<Float, Void> {
		return new ArrayIterator([_x, _y, _z, _order]);
	}

	public static var DEFAULT_ORDER:String = "XYZ";
}