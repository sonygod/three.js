import MathUtils.MathUtils;
import StaticDrawUsage;
import utils.warnOnce;

class InterleavedBuffer {

	public var isInterleavedBuffer:Bool = true;
	public var array:Dynamic;
	public var stride:Int;
	public var count:Int;
	public var usage:StaticDrawUsage;
	public var _updateRange:Dynamic;
	public var updateRanges:Array<Dynamic>;
	public var version:Int;
	public var uuid:String;

	public function new(array:Dynamic, stride:Int) {
		this.array = array;
		this.stride = stride;
		this.count = array !== null ? array.length / stride : 0;
		this.usage = StaticDrawUsage.STATIC_DRAW;
		this._updateRange = { offset: 0, count: -1 };
		this.updateRanges = [];
		this.version = 0;
		this.uuid = MathUtils.generateUUID();
	}

	public function onUploadCallback():Void {}

	public function set needsUpdate(value:Bool) {
		if (value == true) this.version++;
	}

	public function get updateRange():Dynamic {
		warnOnce('THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
		return this._updateRange;
	}

	public function setUsage(value:StaticDrawUsage):InterleavedBuffer {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start, count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges.length = 0;
	}

	public function copy(source:InterleavedBuffer):InterleavedBuffer {
		this.array = new source.array.constructor(source.array);
		this.count = source.count;
		this.stride = source.stride;
		this.usage = source.usage;
		return this;
	}

	public function copyAt(index1:Int, attribute:Dynamic, index2:Int):InterleavedBuffer {
		index1 *= this.stride;
		index2 *= attribute.stride;
		for (i in 0...this.stride) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}
		return this;
	}

	public function set(value:Dynamic, offset:Int = 0):InterleavedBuffer {
		this.array.set(value, offset);
		return this;
	}

	public function clone(data:Dynamic):InterleavedBuffer {
		if (data.arrayBuffers == null) {
			data.arrayBuffers = new Map<String, Dynamic>();
		}
		if (this.array.buffer._uuid == null) {
			this.array.buffer._uuid = MathUtils.generateUUID();
		}
		if (!data.arrayBuffers.exists(this.array.buffer._uuid)) {
			data.arrayBuffers.set(this.array.buffer._uuid, this.array.slice(0).buffer);
		}
		var array = new this.array.constructor(data.arrayBuffers.get(this.array.buffer._uuid));
		var ib = new InterleavedBuffer(array, this.stride);
		ib.setUsage(this.usage);
		return ib;
	}

	public function onUpload(callback:Dynamic->Void):InterleavedBuffer {
		this.onUploadCallback = callback;
		return this;
	}

	public function toJSON(data:Dynamic):Dynamic {
		if (data.arrayBuffers == null) {
			data.arrayBuffers = new Map<String, Dynamic>();
		}
		if (this.array.buffer._uuid == null) {
			this.array.buffer._uuid = MathUtils.generateUUID();
		}
		if (!data.arrayBuffers.exists(this.array.buffer._uuid)) {
			data.arrayBuffers.set(this.array.buffer._uuid, Array.from(new Uint32Array(this.array.buffer)));
		}
		return {
			uuid: this.uuid,
			buffer: this.array.buffer._uuid,
			type: Type.getClassName(Type.getClass(this.array)),
			stride: this.stride
		};
	}
}

export class InterleavedBuffer;