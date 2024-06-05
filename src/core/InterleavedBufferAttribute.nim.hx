import Vector3.Vector3;
import BufferAttribute.BufferAttribute;
import MathUtils.denormalize;
import MathUtils.normalize;

class InterleavedBufferAttribute {

	public var isInterleavedBufferAttribute:Bool = true;
	public var name:String = "";
	public var data:InterleavedBuffer;
	public var itemSize:Int;
	public var offset:Int;
	public var normalized:Bool;

	public function new(interleavedBuffer:InterleavedBuffer, itemSize:Int, offset:Int, normalized:Bool = false) {
		this.data = interleavedBuffer;
		this.itemSize = itemSize;
		this.offset = offset;
		this.normalized = normalized;
	}

	public function get count():Int {
		return this.data.count;
	}

	public function get array():Array<Float> {
		return this.data.array;
	}

	public function set needsUpdate(value:Bool) {
		this.data.needsUpdate = value;
	}

	public function applyMatrix4(m:Matrix4) {
		for (i in 0...this.data.count) {
			var vector = Vector3.fromBufferAttribute(this, i);
			vector.applyMatrix4(m);
			this.setXYZ(i, vector.x, vector.y, vector.z);
		}
		return this;
	}

	public function applyNormalMatrix(m:Matrix3) {
		for (i in 0...this.count) {
			var vector = Vector3.fromBufferAttribute(this, i);
			vector.applyNormalMatrix(m);
			this.setXYZ(i, vector.x, vector.y, vector.z);
		}
		return this;
	}

	public function transformDirection(m:Matrix3) {
		for (i in 0...this.count) {
			var vector = Vector3.fromBufferAttribute(this, i);
			vector.transformDirection(m);
			this.setXYZ(i, vector.x, vector.y, vector.z);
		}
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.data.stride + this.offset + component];
		if (this.normalized) value = denormalize(value, this.array);
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float) {
		if (this.normalized) value = normalize(value, this.array);
		this.data.array[index * this.data.stride + this.offset + component] = value;
		return this;
	}

	public function setX(index:Int, x:Float) {
		if (this.normalized) x = normalize(x, this.array);
		this.data.array[index * this.data.stride + this.offset] = x;
		return this;
	}

	public function setY(index:Int, y:Float) {
		if (this.normalized) y = normalize(y, this.array);
		this.data.array[index * this.data.stride + this.offset + 1] = y;
		return this;
	}

	public function setZ(index:Int, z:Float) {
		if (this.normalized) z = normalize(z, this.array);
		this.data.array[index * this.data.stride + this.offset + 2] = z;
		return this;
	}

	public function setW(index:Int, w:Float) {
		if (this.normalized) w = normalize(w, this.array);
		this.data.array[index * this.data.stride + this.offset + 3] = w;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.data.array[index * this.data.stride + this.offset];
		if (this.normalized) x = denormalize(x, this.array);
		return x;
	}

	public function getY(index:Int):Float {
		var y = this.data.array[index * this.data.stride + this.offset + 1];
		if (this.normalized) y = denormalize(y, this.array);
		return y;
	}

	public function getZ(index:Int):Float {
		var z = this.data.array[index * this.data.stride + this.offset + 2];
		if (this.normalized) z = denormalize(z, this.array);
		return z;
	}

	public function getW(index:Int):Float {
		var w = this.data.array[index * this.data.stride + this.offset + 3];
		if (this.normalized) w = denormalize(w, this.array);
		return w;
	}

	public function setXY(index:Int, x:Float, y:Float) {
		index = index * this.data.stride + this.offset;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
		}
		this.data.array[index + 0] = x;
		this.data.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float) {
		index = index * this.data.stride + this.offset;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
		}
		this.data.array[index + 0] = x;
		this.data.array[index + 1] = y;
		this.data.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float) {
		index = index * this.data.stride + this.offset;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
			w = normalize(w, this.array);
		}
		this.data.array[index + 0] = x;
		this.data.array[index + 1] = y;
		this.data.array[index + 2] = z;
		this.data.array[index + 3] = w;
		return this;
	}

	public function clone(data:Dynamic):BufferAttribute {
		if (data == null) {
			trace("THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");
			var array = [];
			for (i in 0...this.count) {
				var index = i * this.data.stride + this.offset;
				for (j in 0...this.itemSize) {
					array.push(this.data.array[index + j]);
				}
			}
			return new BufferAttribute(new this.array.constructor(array), this.itemSize, this.normalized);
		} else {
			if (data.interleavedBuffers == null) {
				data.interleavedBuffers = {};
			}
			if (data.interleavedBuffers[this.data.uuid] == null) {
				data.interleavedBuffers[this.data.uuid] = this.data.clone(data);
			}
			return new InterleavedBufferAttribute(data.interleavedBuffers[this.data.uuid], this.itemSize, this.offset, this.normalized);
		}
	}

	public function toJSON(data:Dynamic):Dynamic {
		if (data == null) {
			trace("THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");
			var array = [];
			for (i in 0...this.count) {
				var index = i * this.data.stride + this.offset;
				for (j in 0...this.itemSize) {
					array.push(this.data.array[index + j]);
				}
			}
			// de-interleave data and save it as an ordinary buffer attribute for now
			return {
				itemSize: this.itemSize,
				type: Type.getClassName(this.array.constructor),
				array: array,
				normalized: this.normalized
			};
		} else {
			// save as true interleaved attribute
			if (data.interleavedBuffers == null) {
				data.interleavedBuffers = {};
			}
			if (data.interleavedBuffers[this.data.uuid] == null) {
				data.interleavedBuffers[this.data.uuid] = this.data.toJSON(data);
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