import three.math.Vector3;
import three.core.BufferAttribute;
import three.math.MathUtils;

class InterleavedBufferAttribute {

	public var isInterleavedBufferAttribute:Bool = true;

	public var name:String = "";

	public var data:Dynamic;
	public var itemSize:Int;
	public var offset:Int;
	public var normalized:Bool;

	public function new(interleavedBuffer:Dynamic, itemSize:Int, offset:Int, normalized:Bool = false) {
		this.data = interleavedBuffer;
		this.itemSize = itemSize;
		this.offset = offset;
		this.normalized = normalized;
	}

	public function get count():Int {
		return cast interleavedBuffer.count;
	}

	public function get array():Dynamic {
		return interleavedBuffer.array;
	}

	public function set needsUpdate(value:Bool) {
		interleavedBuffer.needsUpdate = value;
	}

	public function applyMatrix4(m:Dynamic):InterleavedBufferAttribute {
		var _vector = new Vector3();

		for (i in 0...interleavedBuffer.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function applyNormalMatrix(m:Dynamic):InterleavedBufferAttribute {
		var _vector = new Vector3();

		for (i in 0...count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function transformDirection(m:Dynamic):InterleavedBufferAttribute {
		var _vector = new Vector3();

		for (i in 0...count) {
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = array[index * interleavedBuffer.stride + offset + component];
		if (normalized) value = MathUtils.denormalize(value, array);
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):InterleavedBufferAttribute {
		if (normalized) value = MathUtils.normalize(value, array);
		array[index * interleavedBuffer.stride + offset + component] = value;
		return this;
	}

	public function setX(index:Int, x:Float):InterleavedBufferAttribute {
		if (normalized) x = MathUtils.normalize(x, array);
		array[index * interleavedBuffer.stride + offset] = x;
		return this;
	}

	public function setY(index:Int, y:Float):InterleavedBufferAttribute {
		if (normalized) y = MathUtils.normalize(y, array);
		array[index * interleavedBuffer.stride + offset + 1] = y;
		return this;
	}

	public function setZ(index:Int, z:Float):InterleavedBufferAttribute {
		if (normalized) z = MathUtils.normalize(z, array);
		array[index * interleavedBuffer.stride + offset + 2] = z;
		return this;
	}

	public function setW(index:Int, w:Float):InterleavedBufferAttribute {
		if (normalized) w = MathUtils.normalize(w, array);
		array[index * interleavedBuffer.stride + offset + 3] = w;
		return this;
	}

	public function getX(index:Int):Float {
		var x = array[index * interleavedBuffer.stride + offset];
		if (normalized) x = MathUtils.denormalize(x, array);
		return x;
	}

	public function getY(index:Int):Float {
		var y = array[index * interleavedBuffer.stride + offset + 1];
		if (normalized) y = MathUtils.denormalize(y, array);
		return y;
	}

	public function getZ(index:Int):Float {
		var z = array[index * interleavedBuffer.stride + offset + 2];
		if (normalized) z = MathUtils.denormalize(z, array);
		return z;
	}

	public function getW(index:Int):Float {
		var w = array[index * interleavedBuffer.stride + offset + 3];
		if (normalized) w = MathUtils.denormalize(w, array);
		return w;
	}

	public function setXY(index:Int, x:Float, y:Float):InterleavedBufferAttribute {
		index = index * interleavedBuffer.stride + offset;

		if (normalized) {
			x = MathUtils.normalize(x, array);
			y = MathUtils.normalize(y, array);
		}

		array[index + 0] = x;
		array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):InterleavedBufferAttribute {
		index = index * interleavedBuffer.stride + offset;

		if (normalized) {
			x = MathUtils.normalize(x, array);
			y = MathUtils.normalize(y, array);
			z = MathUtils.normalize(z, array);
		}

		array[index + 0] = x;
		array[index + 1] = y;
		array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):InterleavedBufferAttribute {
		index = index * interleavedBuffer.stride + offset;

		if (normalized) {
			x = MathUtils.normalize(x, array);
			y = MathUtils.normalize(y, array);
			z = MathUtils.normalize(z, array);
			w = MathUtils.normalize(w, array);
		}

		array[index + 0] = x;
		array[index + 1] = y;
		array[index + 2] = z;
		array[index + 3] = w;
		return this;
	}

	public function clone(data:Dynamic = null):BufferAttribute {
		if (data == null) {
			var array = new Array<Float>();
			for (i in 0...count) {
				var index = i * interleavedBuffer.stride + offset;
				for (j in 0...itemSize) {
					array.push(array[index + j]);
				}
			}
			return new BufferAttribute(array, itemSize, normalized);
		} else {
			if (data.interleavedBuffers == null) {
				data.interleavedBuffers = new Map<String,Dynamic>();
			}
			if (!data.interleavedBuffers.exists(interleavedBuffer.uuid)) {
				data.interleavedBuffers.set(interleavedBuffer.uuid, interleavedBuffer.clone(data));
			}
			return new InterleavedBufferAttribute(data.interleavedBuffers.get(interleavedBuffer.uuid), itemSize, offset, normalized);
		}
	}

	public function toJSON(data:Dynamic = null):Dynamic {
		if (data == null) {
			var array = new Array<Float>();
			for (i in 0...count) {
				var index = i * interleavedBuffer.stride + offset;
				for (j in 0...itemSize) {
					array.push(array[index + j]);
				}
			}
			return {
				itemSize: itemSize,
				type: array.getType(),
				array: array,
				normalized: normalized
			};
		} else {
			if (data.interleavedBuffers == null) {
				data.interleavedBuffers = new Map<String,Dynamic>();
			}
			if (!data.interleavedBuffers.exists(interleavedBuffer.uuid)) {
				data.interleavedBuffers.set(interleavedBuffer.uuid, interleavedBuffer.toJSON(data));
			}
			return {
				isInterleavedBufferAttribute: true,
				itemSize: itemSize,
				data: interleavedBuffer.uuid,
				offset: offset,
				normalized: normalized
			};
		}
	}

	private inline function get interleavedBuffer():Dynamic {
		return this.data;
	}
}