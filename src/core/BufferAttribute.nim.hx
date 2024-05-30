import Int8Array;
import Uint8Array;
import Uint8ClampedArray;
import Int16Array;
import Uint16Array;
import Int32Array;
import Uint32Array;
import Float32Array;
import Vector3;
import Vector2;
import denormalize;
import normalize;
import StaticDrawUsage;
import FloatType;
import fromHalfFloat;
import toHalfFloat;
import warnOnce;

class BufferAttribute {

	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool = false;
	public var usage:Int = StaticDrawUsage;
	public var _updateRange:UpdateRange = { offset: 0, count: -1 };
	public var updateRanges:Array<UpdateRange> = [];
	public var gpuType:Int = FloatType;
	public var version:Int = 0;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (Std.is(array, Array)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array !== null ? array.length / itemSize : 0;
		this.normalized = normalized;

		this.version = 0;
	}

	public var needsUpdate(get, set):Bool {
		if (set === true) this.version++;
		return this.version;
	}

	public function get updateRange():UpdateRange {
		warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead."); // @deprecated, r159
		return this._updateRange;
	}

	public function setUsage(value:Int):Void {
		this.usage = value;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start, count });
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

	public function applyMatrix3(m:Matrix3):BufferAttribute {
		if (this.itemSize === 2) {
			for (i in 0...this.count) {
				var v2:Vector2 = new Vector2().fromBufferAttribute(this, i);
				v2.applyMatrix3(m);
				this.setXY(i, v2.x, v2.y);
			}
		} else if (this.itemSize === 3) {
			for (i in 0...this.count) {
				var v:Vector3 = new Vector3().fromBufferAttribute(this, i);
				v.applyMatrix3(m);
				this.setXYZ(i, v.x, v.y, v.z);
			}
		}
		return this;
	}

	public function applyMatrix4(m:Matrix4):BufferAttribute {
		for (i in 0...this.count) {
			var v:Vector3 = new Vector3().fromBufferAttribute(this, i);
			v.applyMatrix4(m);
			this.setXYZ(i, v.x, v.y, v.z);
		}
		return this;
	}

	public function applyNormalMatrix(m:Matrix3):BufferAttribute {
		for (i in 0...this.count) {
			var v:Vector3 = new Vector3().fromBufferAttribute(this, i);
			v.applyNormalMatrix(m);
			this.setXYZ(i, v.x, v.y, v.z);
		}
		return this;
	}

	public function transformDirection(m:Matrix4):BufferAttribute {
		for (i in 0...this.count) {
			var v:Vector3 = new Vector3().fromBufferAttribute(this, i);
			v.transformDirection(m);
			this.setXYZ(i, v.x, v.y, v.z);
		}
		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value:Float = this.array[index * this.itemSize + component];
		if (this.normalized) value = denormalize(value, this.array);
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) value = normalize(value, this.array);
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x:Float = this.array[index * this.itemSize];
		if (this.normalized) x = denormalize(x, this.array);
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) x = normalize(x, this.array);
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y:Float = this.array[index * this.itemSize + 1];
		if (this.normalized) y = denormalize(y, this.array);
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) y = normalize(y, this.array);
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z:Float = this.array[index * this.itemSize + 2];
		if (this.normalized) z = denormalize(z, this.array);
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) z = normalize(z, this.array);
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w:Float = this.array[index * this.itemSize + 3];
		if (this.normalized) w = denormalize(w, this.array);
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) w = normalize(w, this.array);
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
			w = normalize(w, this.array);
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
		return new this.constructor(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data:Dynamic = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: Array.from(this.array),
			normalized: this.normalized
		};

		if (this.name !== "") data.name = this.name;
		if (this.usage !== StaticDrawUsage) data.usage = this.usage;

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

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Uint16Array(array), itemSize, normalized);
		this.isFloat16BufferAttribute = true;
	}

	public function getX(index:Int):Float {
		var x:Float = fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) x = denormalize(x, this.array);
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) x = normalize(x, this.array);
		this.array[index * this.itemSize] = toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y:Float = fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) y = denormalize(y, this.array);
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) y = normalize(y, this.array);
		this.array[index * this.itemSize + 1] = toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z:Float = fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) z = denormalize(z, this.array);
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) z = normalize(z, this.array);
		this.array[index * this.itemSize + 2] = toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w:Float = fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) w = denormalize(w, this.array);
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) w = normalize(w, this.array);
		this.array[index * this.itemSize + 3] = toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
		}
		this.array[index + 0] = toHalfFloat(x);
		this.array[index + 1] = toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
		}
		this.array[index + 0] = toHalfFloat(x);
		this.array[index + 1] = toHalfFloat(y);
		this.array[index + 2] = toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
			w = normalize(w, this.array);
		}
		this.array[index + 0] = toHalfFloat(x);
		this.array[index + 1] = toHalfFloat(y);
		this.array[index + 2] = toHalfFloat(z);
		this.array[index + 3] = toHalfFloat(w);
		return this;
	}

}

class Float32BufferAttribute extends BufferAttribute {

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Float32Array(array), itemSize, normalized);
	}

}