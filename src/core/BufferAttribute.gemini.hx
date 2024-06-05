import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {
	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool;
	public var usage:Int;
	public var _updateRange: { offset:Int; count:Int } = { offset: 0, count: -1 };
	public var updateRanges:Array<{ start:Int; count:Int }> = [];
	public var gpuType:Int;
	public var version:Int = 0;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (array != null && !Std.is(array, Array<Float>)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array != null ? array.length / itemSize : 0;
		this.normalized = normalized;
		this.usage = StaticDrawUsage;
		this.gpuType = FloatType;
	}

	public function onUploadCallback():Void {
	}

	public function set needsUpdate(value:Bool) {
		if (value) this.version++;
	}

	public function get updateRange():{ offset:Int; count:Int } {
		WarnOnce.warn("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead."); // @deprecated, r159
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges.length = 0;
	}

	public function copy(source:BufferAttribute):BufferAttribute {
		this.name = source.name;
		this.array = new source.array.constructor(source.array);
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;
		this.usage = source.usage;
		this.gpuType = source.gpuType;
		return this;
	}

	public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
		index1 *= this.itemSize;
		index2 *= attribute.itemSize;
		for (i in 0...this.itemSize) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}
		return this;
	}

	public function copyArray(array:Array<Float>):BufferAttribute {
		this.array.set(array);
		return this;
	}

	public function applyMatrix3(m:three.math.Matrix3):BufferAttribute {
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				var _vector2 = new Vector2();
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			for (i in 0...this.count) {
				var _vector = new Vector3();
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}
		return this;
	}

	public function applyMatrix4(m:three.math.Matrix4):BufferAttribute {
		for (i in 0...this.count) {
			var _vector = new Vector3();
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
		return this;
	}

	public function applyNormalMatrix(m:three.math.Matrix3):BufferAttribute {
		for (i in 0...this.count) {
			var _vector = new Vector3();
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
		return this;
	}

	public function transformDirection(m:three.math.Matrix4):BufferAttribute {
		for (i in 0...this.count) {
			var _vector = new Vector3();
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.itemSize + component];
		if (this.normalized) value = MathUtils.denormalize(value, this.array);
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) value = MathUtils.normalize(value, this.array);
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.array[index * this.itemSize];
		if (this.normalized) x = MathUtils.denormalize(x, this.array);
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) x = MathUtils.normalize(x, this.array);
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y = this.array[index * this.itemSize + 1];
		if (this.normalized) y = MathUtils.denormalize(y, this.array);
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) y = MathUtils.normalize(y, this.array);
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z = this.array[index * this.itemSize + 2];
		if (this.normalized) z = MathUtils.denormalize(z, this.array);
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) z = MathUtils.normalize(z, this.array);
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w = this.array[index * this.itemSize + 3];
		if (this.normalized) w = MathUtils.denormalize(w, this.array);
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) w = MathUtils.normalize(w, this.array);
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		this.array[index + 3] = w;
		return this;
	}

	public function onUpload(callback:Void->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: this.array.copy(),
			normalized: this.normalized
		};
		if (this.name != "") data.name = this.name;
		if (this.usage != StaticDrawUsage) data.usage = this.usage;
		return data;
	}
}

class Int8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Int8Array(array), itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Uint8Array(array), itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Int16Array(array), itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Uint16Array(array), itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Int32Array(array), itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Uint32Array(array), itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public var isFloat16BufferAttribute:Bool = true;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Uint16Array(array), itemSize, normalized);
	}

	public function getX(index:Int):Float {
		var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) x = MathUtils.denormalize(x, this.array);
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) x = MathUtils.normalize(x, this.array);
		this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) y = MathUtils.denormalize(y, this.array);
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) y = MathUtils.normalize(y, this.array);
		this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) z = MathUtils.denormalize(z, this.array);
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) z = MathUtils.normalize(z, this.array);
		this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) w = MathUtils.denormalize(w, this.array);
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) w = MathUtils.normalize(w, this.array);
		this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		this.array[index + 3] = DataUtils.toHalfFloat(w);
		return this;
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Float32Array(array), itemSize, normalized);
	}
}

class BufferGeometry {
	// ... other methods ...

	public function setAttribute(name:String, attribute:BufferAttribute):Void {
		// ... implementation ...
	}

	public function getAttribute(name:String):BufferAttribute {
		// ... implementation ...
	}

	// ... other methods ...
}

// ... other classes ...