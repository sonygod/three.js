package;

import js.Lib;
import js.Browser.window;
import js.QUnit.QUnit;

class BufferAttribute {
    public var array:js.TypedArray<Float32Array>;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int;
    public var updateRanges:Array<Int>;
    public var version:Int;
    public var onUploadCallback:Dynamic->Void;
    public var needsUpdate:Bool;
    public var isBufferAttribute:Bool;

    public function new(array:js.TypedArray<Float32Array>, itemSize:Int, normalized:Bool) {
        this.array = array;
        this.itemSize = itemSize;
        this.normalized = normalized;
        this.count = array.length / itemSize;
        this.usage = 0;
        this.updateRanges = [];
        this.version = 0;
        this.onUploadCallback = function() {};
        this.needsUpdate = false;
        this.isBufferAttribute = true;
    }

    public function setUsage(usage:Int):Void {
        this.usage = usage;
    }

    public function copy(attr:BufferAttribute):BufferAttribute {
        var attrCopy = new BufferAttribute(attr.array, attr.itemSize, attr.normalized);
        attrCopy.setUsage(attr.usage);
        attrCopy.needsUpdate = attr.needsUpdate;
        return attrCopy;
    }

    public function copyAt(index:Int, attr:BufferAttribute, attrIndex:Int):Void {
        var i = attr.array;
        var i2 = this.array;
        for (i2Index in i2) {
            if (i2Index >= index * attr.itemSize && i2Index < (index + 1) * attr.itemSize) {
                i2[i2Index] = i[attrIndex * attr.itemSize + i2Index - index * attr.itemSize];
            }
        }
    }

    public function copyArray(array:js.TypedArray<Float32Array>):Void {
        this.array = array;
    }

    public function set(value:Array<Float>):Void {
        for (i in value) {
            this.array[i] = value[i];
        }
    }

    public function setX(index:Int, x:Float):Void {
        this.array[index * this.itemSize] = x;
    }

    public function setY(index:Int, y:Float):Void {
        this.array[index * this.itemSize + 1] = y;
    }

    public function setZ(index:Int, z:Float):Void {
        this.array[index * this.itemSize + 2] = z;
    }

    public function setW(index:Int, w:Float):Void {
        this.array[index * this.itemSize + 3] = w;
    }

    public function setXY(index:Int, x:Float, y:Float):Void {
        this.setX(index, x);
        this.setY(index, y);
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):Void {
        this.setX(index, x);
        this.setY(index, y);
        this.setZ(index, z);
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):Void {
        this.setX(index, x);
        this.setY(index, y);
        this.setZ(index, z);
        this.setW(index, w);
    }

    public function onUpload(callback:Dynamic->Void):Void {
        this.onUploadCallback = callback;
    }

    public function clone():BufferAttribute {
        var attrCopy = new BufferAttribute(this.array, this.itemSize, this.normalized);
        attrCopy.setUsage(this.usage);
        attrCopy.needsUpdate = this.needsUpdate;
        return attrCopy;
    }

    public function toJSON():Dynamic {
        return {
            itemSize: this.itemSize,
            type: this.array.constructor.name,
            array: this.array,
            normalized: this.normalized
        };
    }
}

class Int8BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Int8Array(), 1, false);
    }
}

class Uint8BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Uint8Array(), 1, false);
    }
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
    public function new() {
        super(new Uint8ClampedArray(), 1, false);
    }
}

class Int16BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Int16Array(), 1, false);
    }
}

class Uint16BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Uint16Array(), 1, false);
    }
}

class Int32BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Int32Array(), 1, false);
    }
}

class Uint32BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Uint32Array(), 1, false);
    }
}

class Float16BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Uint16Array(), 1, false);
    }
}

class Float32BufferAttribute extends BufferAttribute {
    public function new() {
        super(new Float32Array(), 1, false);
    }
}

class Test {
    static function main() {
        // 在这里添加你的测试代码
    }
}