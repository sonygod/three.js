import three.math.Vector3;
import three.core.BufferAttribute;
import three.math.MathUtils;

class InterleavedBufferAttribute {

	public var isInterleavedBufferAttribute: Bool = true;
	public var name: String = '';
	public var data: InterleavedBuffer;
	public var itemSize: Int;
	public var offset: Int;
	public var normalized: Bool;

	public function new(interleavedBuffer: InterleavedBuffer, itemSize: Int, offset: Int, normalized: Bool = false) {
		this.data = interleavedBuffer;
		this.itemSize = itemSize;
		this.offset = offset;
		this.normalized = normalized;
	}

	public function get count(): Int {
		return this.data.count;
	}

	public function get array(): Array<Float> {
		return this.data.array;
	}

	public var needsUpdate: Bool;

	public function applyMatrix4(m: Matrix4): InterleavedBufferAttribute {
		var vector: Vector3 = new Vector3();
		for (i in 0...this.data.count) {
			vector.fromBufferAttribute(this, i);
			vector.applyMatrix4(m);
			this.setXYZ(i, vector.x, vector.y, vector.z);
		}
		return this;
	}

	public function applyNormalMatrix(m: Matrix3): InterleavedBufferAttribute {
		var vector: Vector3 = new Vector3();
		for (i in 0...this.count) {
			vector.fromBufferAttribute(this, i);
			vector.applyNormalMatrix(m);
			this.setXYZ(i, vector.x, vector.y, vector.z);
		}
		return this;
	}

	public function transformDirection(m: Matrix4): InterleavedBufferAttribute {
		var vector: Vector3 = new Vector3();
		for (i in 0...this.count) {
			vector.fromBufferAttribute(this, i);
			vector.transformDirection(m);
			this.setXYZ(i, vector.x, vector.y, vector.z);
		}
		return this;
	}

	public function getComponent(index: Int, component: Int): Float {
		var value: Float = this.array[index * this.data.stride + this.offset + component];
		if (this.normalized) value = MathUtils.denormalize(value, this.array);
		return value;
	}

	public function setComponent(index: Int, component: Int, value: Float): InterleavedBufferAttribute {
		if (this.normalized) value = MathUtils.normalize(value, this.array);
		this.data.array[index * this.data.stride + this.offset + component] = value;
		return this;
	}

	public function setX(index: Int, x: Float): InterleavedBufferAttribute {
		if (this.normalized) x = MathUtils.normalize(x, this.array);
		this.data.array[index * this.data.stride + this.offset] = x;
		return this;
	}

	public function setY(index: Int, y: Float): InterleavedBufferAttribute {
		if (this.normalized) y = MathUtils.normalize(y, this.array);
		this.data.array[index * this.data.stride + this.offset + 1] = y;
		return this;
	}

	public function setZ(index: Int, z: Float): InterleavedBufferAttribute {
		if (this.normalized) z = MathUtils.normalize(z, this.array);
		this.data.array[index * this.data.stride + this.offset + 2] = z;
		return this;
	}

	public function setW(index: Int, w: Float): InterleavedBufferAttribute {
		if (this.normalized) w = MathUtils.normalize(w, this.array);
		this.data.array[index * this.data.stride + this.offset + 3] = w;
		return this;
	}

	public function getX(index: Int): Float {
		var x: Float = this.data.array[index * this.data.stride + this.offset];
		if (this.normalized) x = MathUtils.denormalize(x, this.array);
		return x;
	}

	public function getY(index: Int): Float {
		var y: Float = this.data.array[index * this.data.stride + this.offset + 1];
		if (this.normalized) y = MathUtils.denormalize(y, this.array);
		return y;
	}

	public function getZ(index: Int): Float {
		var z: Float = this.data.array[index * this.data.stride + this.offset + 2];
		if (this.normalized) z = MathUtils.denormalize(z, this.array);
		return z;
	}

	public function getW(index: Int): Float {
		var w: Float = this.data.array[index * this.data.stride + this.offset + 3];
		if (this.normalized) w = MathUtils.denormalize(w, this.array);
		return w;
	}

	public function setXY(index: Int, x: Float, y: Float): InterleavedBufferAttribute {
		index = index * this.data.stride + this.offset;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.data.array[index + 0] = x;
		this.data.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index: Int, x: Float, y: Float, z: Float): InterleavedBufferAttribute {
		index = index * this.data.stride + this.offset;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.data.array[index + 0] = x;
		this.data.array[index + 1] = y;
		this.data.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index: Int, x: Float, y: Float, z: Float, w: Float): InterleavedBufferAttribute {
		index = index * this.data.stride + this.offset;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.data.array[index + 0] = x;
		this.data.array[index + 1] = y;
		this.data.array[index + 2] = z;
		this.data.array[index + 3] = w;
		return this;
	}

	public function clone(data: Dynamic): InterleavedBufferAttribute {
		if (data == null) {
			trace('THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.');
			var array: Array<Float> = [];
			for (i in 0...this.count) {
				var index: Int = i * this.data.stride + this.offset;
				for (j in 0...this.itemSize) {
					array.push(this.data.array[index + j]);
				}
			}
			return new BufferAttribute(new this.array.constructor(array), this.itemSize, this.normalized);
		} else {
			if (Reflect.hasField(data, "interleavedBuffers") == false) {
				Reflect.setField(data, "interleavedBuffers", {});
			}
			if (Reflect.hasField(data.interleavedBuffers, this.data.uuid) == false) {
				Reflect.setField(data.interleavedBuffers, this.data.uuid, this.data.clone(data));
			}
			return new InterleavedBufferAttribute(Reflect.field(data.interleavedBuffers, this.data.uuid), this.itemSize, this.offset, this.normalized);
		}
	}

	public function toJSON(data: Dynamic): Dynamic {
		if (data == null) {
			trace('THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.');
			var array: Array<Float> = [];
			for (i in 0...this.count) {
				var index: Int = i * this.data.stride + this.offset;
				for (j in 0...this.itemSize) {
					array.push(this.data.array[index + j]);
				}
			}
			return {
				itemSize: this.itemSize,
				type: Reflect.name(this.array.constructor),
				array: array,
				normalized: this.normalized
			};
		} else {
			if (Reflect.hasField(data, "interleavedBuffers") == false) {
				Reflect.setField(data, "interleavedBuffers", {});
			}
			if (Reflect.hasField(data.interleavedBuffers, this.data.uuid) == false) {
				Reflect.setField(data.interleavedBuffers, this.data.uuid, this.data.toJSON(data));
			}
			return {
				isInterleavedBufferAttribute: true,
				itemSize: this.itemSize,
				data: this.data.uuid,
				offset: this.offset,
				normalized: this.normalized
			};
		}
	}

}

