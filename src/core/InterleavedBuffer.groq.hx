package three.js.src.core;

import MathUtils from '../math/MathUtils';
import StaticDrawUsage from '../constants';
import warnOnce from '../utils';

class InterleavedBuffer {

    public var isInterleavedBuffer:Bool = true;

    public var array:Array<Float>;
    public var stride:Int;
    public var count:Int;
    public var usage:StaticDrawUsage;
    public var _updateRange:{ offset:Int, count:Int };
    public var updateRanges:Array<{ start:Int, count:Int }>;
    public var version:Int;
    public var uuid:String;
    public var onUploadCallback:Void->Void;

    public function new(array:Array<Float>, stride:Int) {
        this.array = array;
        this.stride = stride;
        this.count = array != null ? Math.floor(array.length / stride) : 0;
        this.usage = StaticDrawUsage;
        this._updateRange = { offset: 0, count: -1 };
        this.updateRanges = [];
        this.version = 0;
        this.uuid = MathUtils.generateUUID();
    }

    public function onUploadCallback():Void {}

    public function set_needsUpdate(value:Bool):Void {
        if (value) this.version++;
    }

    public function get_updateRange():{ offset:Int, count:Int } {
        warnOnce('THREE.InterleavedBuffer: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
        return _updateRange;
    }

    public function setUsage(value:StaticDrawUsage):InterleavedBuffer {
        this.usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int):Void {
        updateRanges.push({ start: start, count: count });
    }

    public function clearUpdateRanges():Void {
        updateRanges = [];
    }

    public function copy(source:InterleavedBuffer):InterleavedBuffer {
        array = new source.array.constructor(source.array);
        count = source.count;
        stride = source.stride;
        usage = source.usage;
        return this;
    }

    public function copyAt(index1:Int, attribute:InterleavedBuffer, index2:Int):InterleavedBuffer {
        index1 *= stride;
        index2 *= attribute.stride;
        for (i in 0...stride) {
            array[index1 + i] = attribute.array[index2 + i];
        }
        return this;
    }

    public function set(value:Array<Float>, offset:Int = 0):InterleavedBuffer {
        array.set(value, offset);
        return this;
    }

    public function clone(data:Dynamic):InterleavedBuffer {
        if (data.arrayBuffers == null) {
            data.arrayBuffers = {};
        }
        if (array.buffer._uuid == null) {
            array.buffer._uuid = MathUtils.generateUUID();
        }
        if (data.arrayBuffers[array.buffer._uuid] == null) {
            data.arrayBuffers[array.buffer._uuid] = array.slice(0).buffer;
        }
        var array = new array.constructor(data.arrayBuffers[array.buffer._uuid]);
        var ib = new InterleavedBuffer(array, stride);
        ib.setUsage(usage);
        return ib;
    }

    public function onUpload(callback:Void->Void):InterleavedBuffer {
        onUploadCallback = callback;
        return this;
    }

    public function toJSON(data:Dynamic):Dynamic {
        if (data.arrayBuffers == null) {
            data.arrayBuffers = {};
        }
        if (array.buffer._uuid == null) {
            array.buffer._uuid = MathUtils.generateUUID();
        }
        if (data.arrayBuffers[array.buffer._uuid] == null) {
            data.arrayBuffers[array.buffer._uuid] = Array.from(new Uint32Array(array.buffer));
        }
        return {
            uuid: uuid,
            buffer: array.buffer._uuid,
            type: Type.getClassName(Type.getClass(array)),
            stride: stride
        };
    }
}