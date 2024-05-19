import js.Browser.MathUtils;
import js.Browser.StaticDrawUsage;
import js.Browser.warnOnce;

class InterleavedBuffer {

    public var isInterleavedBuffer:Bool;
    public var array:Array<Dynamic>;
    public var stride:Int;
    public var count:Int;
    public var usage:Dynamic;
    public var _updateRange:Dynamic;
    public var updateRanges:Array<Dynamic>;
    public var version:Int;
    public var uuid:String;

    public function new(array:Array<Dynamic>, stride:Int) {
        this.isInterleavedBuffer = true;
        this.array = array;
        this.stride = stride;
        this.count = if (array !== undefined) array.length / stride else 0;
        this.usage = StaticDrawUsage;
        this._updateRange = { offset: 0, count: - 1 };
        this.updateRanges = [];
        this.version = 0;
        this.uuid = MathUtils.generateUUID();
    }

    public function onUploadCallback():Void {}

    public function set needsUpdate(value:Bool):Void {
        if (value === true) this.version ++;
    }

    public function get updateRange():Dynamic {
        warnOnce('THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.'); // @deprecated, r159
        return this._updateRange;
    }

    public function setUsage(value:Dynamic):InterleavedBuffer {
        this.usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int):Void {
        this.updateRanges.push({ start: start, count: count });
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

    public function copyAt(index1:Int, attribute:InterleavedBuffer, index2:Int):InterleavedBuffer {
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
        if (data.arrayBuffers === undefined) {
            data.arrayBuffers = {};
        }
        if (this.array.buffer._uuid === undefined) {
            this.array.buffer._uuid = MathUtils.generateUUID();
        }
        if (data.arrayBuffers[this.array.buffer._uuid] === undefined) {
            data.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0).buffer;
        }
        var array = new this.array.constructor(data.arrayBuffers[this.array.buffer._uuid]);
        var ib = new InterleavedBuffer(array, this.stride);
        ib.setUsage(this.usage);
        return ib;
    }

    public function onUpload(callback:Dynamic):InterleavedBuffer {
        this.onUploadCallback = callback;
        return this;
    }

    public function toJSON(data:Dynamic):Dynamic {
        if (data.arrayBuffers === undefined) {
            data.arrayBuffers = {};
        }
        if (this.array.buffer._uuid === undefined) {
            this.array.buffer._uuid = MathUtils.generateUUID();
        }
        if (data.arrayBuffers[this.array.buffer._uuid] === undefined) {
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