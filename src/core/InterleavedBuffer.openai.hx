import js.html.Uint32Array;
import js.util.UUID;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.utils.warnOnce;

class InterleavedBuffer {

    public var isInterleavedBuffer:Bool = true;
    public var array:Dynamic;
    public var stride:Int;
    public var count:Int;
    public var usage:Dynamic = StaticDrawUsage;
    public var _updateRange:{ offset:Int, count:Int };
    public var updateRanges:Array<{ start:Int, count:Int }>;
    public var version:Int;
    public var uuid:String;

    public function new(array:Dynamic, stride:Int) {
        this.array = array;
        this.stride = stride;
        this.count = array != null ? array.length / stride : 0;
        this._updateRange = { offset: 0, count: - 1 };
        this.updateRanges = [];
        this.version = 0;
        this.uuid = MathUtils.generateUUID();
    }

    public function onUploadCallback():Void {}

    public var needsUpdate:Bool;

    public function get_updateRange():{ offset:Int, count:Int } {
        warnOnce('THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
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

    public function set(value:Dynamic, ?offset:Int = 0):InterleavedBuffer {
        Reflect.callMethod(this.array, "set", [value, offset]);
        return this;
    }

    public function clone(data:{arrayBuffers:Dynamic}):InterleavedBuffer {
        if (data.arrayBuffers == null) {
            data.arrayBuffers = {};
        }
        if (Reflect.field(this.array.buffer, "_uuid") == null) {
            Reflect.setField(this.array.buffer, "_uuid", UUID.generateUUID());
        }
        if (data.arrayBuffers[Reflect.field(this.array.buffer, "_uuid")] == null) {
            data.arrayBuffers[Reflect.field(this.array.buffer, "_uuid")] = this.array.slice(0).buffer;
        }
        var array:Dynamic = new (js.Browser.getEnv("constructor", this.array))(data.arrayBuffers[Reflect.field(this.array.buffer, "_uuid")]);
        var ib:InterleavedBuffer = new InterleavedBuffer(array, this.stride);
        ib.setUsage(this.usage);
        return ib;
    }

    public function onUpload(callback:Void -> Void):InterleavedBuffer {
        this.onUploadCallback = callback;
        return this;
    }

    public function toJSON(data:{arrayBuffers:Dynamic}):Dynamic {
        if (data.arrayBuffers == null) {
            data.arrayBuffers = {};
        }
        if (Reflect.field(this.array.buffer, "_uuid") == null) {
            Reflect.setField(this.array.buffer, "_uuid", UUID.generateUUID());
        }
        if (data.arrayBuffers[Reflect.field(this.array.buffer, "_uuid")] == null) {
            data.arrayBuffers[Reflect.field(this.array.buffer, "_uuid")] = Array.from(new Uint32Array(this.array.buffer));
        }
        return {
            uuid: this.uuid,
            buffer: Reflect.field(this.array.buffer, "_uuid"),
            type: Reflect.field(this.array.constructor, "name"),
            stride: this.stride
        };
    }

}