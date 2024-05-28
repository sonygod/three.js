import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.warnOnce;

class BufferAttribute {

	var isBufferAttribute:Bool;
	var name:String;
	var array:Array<Float>;
	var itemSize:Int;
	var count:Int;
	var normalized:Bool;
	var usage:Int;
	var _updateRange:{offset:Int, count:Int};
	var updateRanges:Array<{start:Int, count:Int}>;
	var gpuType:Int;
	var version:Int;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		this.isBufferAttribute = true;
		this.name = '';
		this.array = array;
		this.itemSize = itemSize;
		this.count = if (array !== undefined) array.length / itemSize else 0;
		this.normalized = normalized;
		this.usage = StaticDrawUsage;
		this._updateRange = {offset: 0, count: - 1};
		this.updateRanges = [];
		this.gpuType = FloatType;
		this.version = 0;
	}

	public function onUploadCallback() {}

	public function set needsUpdate(value:Bool) {
		if (value == true) this.version ++;
	}

	public function get updateRange():{offset:Int, count:Int} {
		warnOnce('THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.'); // @deprecated, r159
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int) {
		this.updateRanges.push({start: start, count: count});
	}

	public function clearUpdateRanges() {
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
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			for (i in 0...this.count) {
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}
		return this;
	}

	public function applyMatrix4(m:Matrix4):BufferAttribute {
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
		return this;
	}

	public function applyNormalMatrix(m:Matrix3):BufferAttribute {
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
		return this;
	}

	public function transformDirection(m:Matrix4):BufferAttribute {
		for (i in 0...this.count) {
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

	public function onUpload(callback:Dynamic->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():{itemSize:Int, type:String, array:Array<Float>, normalized:Bool} {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: Array.from(this.array),
			normalized: this.normalized
		};
		if (this.name !== '') data.name = this.name;
		if (this.usage !== StaticDrawUsage) data.usage = this.usage;
		return data;
	}

}

// 其他类型的 BufferAttribute 类可以类似地转换