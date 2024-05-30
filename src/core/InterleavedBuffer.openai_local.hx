import MathUtils;
import StaticDrawUsage;
import warnOnce;

class InterleavedBuffer {

	public var isInterleavedBuffer:Bool = true;

	public var array:Array<Float>;
	public var stride:Int;
	public var count:Int;
	public var usage:Int = StaticDrawUsage;
	private var _updateRange:Dynamic = { offset: 0, count: -1 };
	public var updateRanges:Array<Dynamic> = [];
	public var version:Int = 0;
	public var uuid:String;

	public function new(array:Array<Float>, stride:Int) {
		this.array = array;
		this.stride = stride;
		this.count = array != null ? array.length / stride : 0;
		this.uuid = MathUtils.generateUUID();
	}

	public function onUploadCallback() {}

	public function set_needsUpdate(value:Bool):Void {
		if (value == true) this.version++;
	}

	public function get_updateRange():Dynamic {
		warnOnce('THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
		return this._updateRange;
	}

	public function setUsage(value:Int):InterleavedBuffer {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges = [];
	}

	public function copy(source:InterleavedBuffer):InterleavedBuffer {
		this.array = new source.array.constructor(source.array);
		this.count = source.count;
		this.stride = source.stride;
		this.usage = source.usage;
		return this;
	}

	public function copyAt(index1:Int, attribute:InterleavedBuffer, index2:Int):InterleavedBuffer {
		index1 *= this.stride;
		index2 *= attribute.stride;

		for (i in 0...this.stride) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}

		return this;
	}

	public function set(value:Array<Float>, ?offset:Int = 0):InterleavedBuffer {
		this.array.set(value, offset);
		return this;
	}

	public function clone(data:Dynamic):InterleavedBuffer {
		if (data.arrayBuffers == null) {
			data.arrayBuffers = {};
		}

		if (this.array.buffer._uuid == null) {
			this.array.buffer._uuid = MathUtils.generateUUID();
		}

		if (data.arrayBuffers[this.array.buffer._uuid] == null) {
			data.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0).buffer;
		}

		var array = new this.array.constructor(data.arrayBuffers[this.array.buffer._uuid]);
		var ib = new InterleavedBuffer(array, this.stride);
		ib.setUsage(this.usage);

		return ib;
	}

	public function onUpload(callback:Void -> Void):InterleavedBuffer {
		this.onUploadCallback = callback;
		return this;
	}

	public function toJSON(data:Dynamic):Dynamic {
		if (data.arrayBuffers == null) {
			data.arrayBuffers = {};
		}

		if (this.array.buffer._uuid == null) {
			this.array.buffer._uuid = MathUtils.generateUUID();
		}

		if (data.arrayBuffers[this.array.buffer._uuid] == null) {
			data.arrayBuffers[this.array.buffer._uuid] = Array.from(new UInt32Array(this.array.buffer));
		}

		return {
			uuid: this.uuid,
			buffer: this.array.buffer._uuid,
			type: Type.getClassName(Type.getClass(this.array)),
			stride: this.stride
		};
	}
}