import MathUtils from "three/math/MathUtils";
import StaticDrawUsage from "three/constants/StaticDrawUsage";
import { warnOnce } from "three/utils";

class InterleavedBuffer {
	public var isInterleavedBuffer:Bool = true;

	public var array:Array<Float>;
	public var stride:Int;
	public var count:Int;
	public var usage:Dynamic;
	public var _updateRange:{offset:Int, count:Int};
	public var updateRanges:Array<{start:Int, count:Int}>;
	public var version:Int;
	public var uuid:String;

	public function new(array:Array<Float>, stride:Int) {
		this.isInterleavedBuffer = true;
		this.array = array;
		this.stride = stride;
		this.count = array != null ? array.length / stride : 0;
		this.usage = StaticDrawUsage;
		this._updateRange = {offset:0, count:-1};
		this.updateRanges = [];
		this.version = 0;
		this.uuid = MathUtils.generateUUID();
	}

	public function onUploadCallback() : Void {
	}

	public function set_needsUpdate(value:Bool) : Void {
		if (value == true) this.version++;
	}

	public function get_updateRange() : {offset:Int, count:Int} {
		warnOnce("THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
		return this._updateRange;
	}

	public function setUsage(value:Dynamic) : InterleavedBuffer {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int) : Void {
		this.updateRanges.push({start:start, count:count});
	}

	public function clearUpdateRanges() : Void {
		this.updateRanges.length = 0;
	}

	public function copy(source:InterleavedBuffer) : InterleavedBuffer {
		this.array = new source.array.constructor(source.array);
		this.count = source.count;
		this.stride = source.stride;
		this.usage = source.usage;
		return this;
	}

	public function copyAt(index1:Int, attribute:InterleavedBuffer, index2:Int) : InterleavedBuffer {
		index1 *= this.stride;
		index2 *= attribute.stride;
		for (i in 0...this.stride) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}
		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0) : InterleavedBuffer {
		this.array.set(value, offset);
		return this;
	}

	public function clone(data:{arrayBuffers:Dynamic}) : InterleavedBuffer {
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

	public function onUpload(callback:() -> Void) : InterleavedBuffer {
		this.onUploadCallback = callback;
		return this;
	}

	public function toJSON(data:{arrayBuffers:Dynamic}) : Dynamic {
		if (data.arrayBuffers == null) {
			data.arrayBuffers = {};
		}
		if (this.array.buffer._uuid == null) {
			this.array.buffer._uuid = MathUtils.generateUUID();
		}
		if (data.arrayBuffers[this.array.buffer._uuid] == null) {
			data.arrayBuffers[this.array.buffer._uuid] = Array.from(new Uint32Array(this.array.buffer));
		}
		return {
			uuid: this.uuid,
			buffer: this.array.buffer._uuid,
			type: this.array.constructor.name,
			stride: this.stride
		};
	}

}