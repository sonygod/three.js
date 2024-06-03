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

	public var count(get, never):Int;

	private function get_count():Int {
		return cast(data.count, Int);
	}

	public var array(get, never):Array<Float>;

	private function get_array():Array<Float> {
		return cast(data.array, Array<Float>);
	}

	public var needsUpdate(get, set):Bool;

	private function get_needsUpdate():Bool {
		return cast(data.needsUpdate, Bool);
	}

	private function set_needsUpdate(value:Bool):Bool {
		data.needsUpdate = value;
		return value;
	}

	public function applyMatrix4(m:Dynamic):InterleavedBufferAttribute {
		var _vector = new Vector3();
		for (i in 0...count) {
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
		var value = array[index * cast(data.stride, Int) + offset + component];
		if (normalized) value = MathUtils.denormalize(value, array);
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):InterleavedBufferAttribute {
		if (normalized) value = MathUtils.normalize(value, array);
		array[index * cast(data.stride, Int) + offset + component] = value;
		return this;
	}

	public function setX(index:Int, x:Float):InterleavedBufferAttribute {
		if (normalized) x = MathUtils.normalize(x, array);
		array[index * cast(data.stride, Int) + offset] = x;
		return this;
	}

	public function setY(index:Int, y:Float):InterleavedBufferAttribute {
		if (normalized) y = MathUtils.normalize(y, array);
		array[index * cast(data.stride, Int) + offset + 1] = y;
		return this;
	}

	public function setZ(index:Int, z:Float):InterleavedBufferAttribute {
		if (normalized) z = MathUtils.normalize(z, array);
		array[index * cast(data.stride, Int) + offset + 2] = z;
		return this;
	}

	public function setW(index:Int, w:Float):InterleavedBufferAttribute {
		if (normalized) w = MathUtils.normalize(w, array);
		array[index * cast(data.stride, Int) + offset + 3] = w;
		return this;
	}

	public function getX(index:Int):Float {
		var x = array[index * cast(data.stride, Int) + offset];
		if (normalized) x = MathUtils.denormalize(x, array);
		return x;
	}

	public function getY(index:Int):Float {
		var y = array[index * cast(data.stride, Int) + offset + 1];
		if (normalized) y = MathUtils.denormalize(y, array);
		return y;
	}

	public function getZ(index:Int):Float {
		var z = array[index * cast(data.stride, Int) + offset + 2];
		if (normalized) z = MathUtils.denormalize(z, array);
		return z;
	}

	public function getW(index:Int):Float {
		var w = array[index * cast(data.stride, Int) + offset + 3];
		if (normalized) w = MathUtils.denormalize(w, array);
		return w;
	}

	public function setXY(index:Int, x:Float, y:Float):InterleavedBufferAttribute {
		index = index * cast(data.stride, Int) + offset;
		if (normalized) {
			x = MathUtils.normalize(x, array);
			y = MathUtils.normalize(y, array);
		}
		array[index + 0] = x;
		array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):InterleavedBufferAttribute {
		index = index * cast(data.stride, Int) + offset;
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
		index = index * cast(data.stride, Int) + offset;
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

	public function clone(data:Dynamic = null):Dynamic {
		if (data == null) {
			trace('THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.');
			var array:Array<Float> = [];
			for (i in 0...count) {
				var index = i * cast(data.stride, Int) + offset;
				for (j in 0...itemSize) {
					array.push(array[index + j]);
				}
			}
			return new BufferAttribute(new array.constructor(array), itemSize, normalized);
		} else {
			if (data.interleavedBuffers == null) {
				data.interleavedBuffers = {};
			}
			if (data.interleavedBuffers[cast(data.uuid, String)] == null) {
				data.interleavedBuffers[cast(data.uuid, String)] = data.clone(data);
			}
			return new InterleavedBufferAttribute(data.interleavedBuffers[cast(data.uuid, String)], itemSize, offset, normalized);
		}
	}

	public function toJSON(data:Dynamic = null):Dynamic {
		if (data == null) {
			trace('THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.');
			var array:Array<Float> = [];
			for (i in 0...count) {
				var index = i * cast(data.stride, Int) + offset;
				for (j in 0...itemSize) {
					array.push(array[index + j]);
				}
			}
			// de-interleave data and save it as an ordinary buffer attribute for now
			return {
				itemSize: itemSize,
				type: array.constructor.name,
				array: array,
				normalized: normalized
			};
		} else {
			// save as true interleaved attribute
			if (data.interleavedBuffers == null) {
				data.interleavedBuffers = {};
			}
			if (data.interleavedBuffers[cast(data.uuid, String)] == null) {
				data.interleavedBuffers[cast(data.uuid, String)] = data.toJSON(data);
			}
			return {
				isInterleavedBufferAttribute: true,
				itemSize: itemSize,
				data: cast(data.uuid, String),
				offset: offset,
				normalized: normalized
			};
		}
	}
}