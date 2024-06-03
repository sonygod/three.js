import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.utils.warnOnce;

class InterleavedBuffer {
    public var isInterleavedBuffer:Bool;
    public var array:Array<Float>;
    public var stride:Int;
    public var count:Int;
    public var usage:Int;
    public var _updateRange:Dynamic;
    public var updateRanges:Array<Dynamic>;
    public var version:Int;
    public var uuid:String;
    public var onUploadCallback:Dynamic;

    public function new(array?:Array<Float>, stride?:Int) {
        this.isInterleavedBuffer = true;
        this.array = array != null ? array : [];
        this.stride = stride != null ? stride : 0;
        this.count = array != null ? array.length / this.stride : 0;
        this.usage = StaticDrawUsage;
        this._updateRange = { offset: 0, count: -1 };
        this.updateRanges = [];
        this.version = 0;
        this.uuid = MathUtils.generateUUID();
        this.onUploadCallback = function() {};
    }

    public function set needsUpdate(value:Bool) {
        if (value) this.version++;
    }

    public function get updateRange():Dynamic {
        warnOnce("THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
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
        this.array = source.array.slice();
        this.count = source.count;
        this.stride = source.stride;
        this.usage = source.usage;
        return this;
    }

    public function copyAt(index1:Int, attribute:InterleavedBuffer, index2:Int):InterleavedBuffer {
        index1 *= this.stride;
        index2 *= attribute.stride;
        for (var i = 0; i < this.stride; i++) {
            this.array[index1 + i] = attribute.array[index2 + i];
        }
        return this;
    }

    public function set(value:Array<Float>, offset:Int = 0):InterleavedBuffer {
        this.array.splice(offset, value.length, ...value);
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
            data.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0);
        }
        var array = data.arrayBuffers[this.array.buffer._uuid];
        var ib = new InterleavedBuffer(array, this.stride);
        ib.setUsage(this.usage);
        return ib;
    }

    public function onUpload(callback:Dynamic):InterleavedBuffer {
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
            data.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0);
        }
        return {
            uuid: this.uuid,
            buffer: this.array.buffer._uuid,
            type: Type.getClass(this.array).getName(),
            stride: this.stride
        };
    }
}