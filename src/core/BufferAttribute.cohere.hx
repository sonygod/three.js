import js.Browser.TypedArray;
import js.Browser.Float32Array;
import js.Browser.Float64Array;
import js.Browser.Int8Array;
import js.Browser.Int16Array;
import js.Browser.Int32Array;
import js.Browser.Uint8Array;
import js.Browser.Uint16Array;
import js.Browser.Uint32Array;
import js.Browser.Uint8ClampedArray;

import js.three.Vector3;
import js.three.Vector2;

class BufferAttribute {
    public var isBufferAttribute:Bool;
    public var name:String;
    public var array:TypedArray;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int;
    public var _updateRange:Dynamic;
    public var updateRanges:Array<Dynamic>;
    public var gpuType:Int;
    public var version:Int;
    public var onUploadCallback:Dynamic;

    public function new(array:TypedArray, itemSize:Int, normalized:Bool = false) {
        if (Type.enumIndex(array) != null) {
            throw $assert('THREE.BufferAttribute: array should be a Typed Array.');
        }

        this.isBufferAttribute = true;
        this.name = '';
        this.array = array;
        this.itemSize = itemSize;
        this.count = Std.int(array.length / itemSize);
        this.normalized = normalized;
        this.usage = js.three.StaticDrawUsage;
        this._updateRange = { offset: 0, count: -1 };
        this.updateRanges = [];
        this.gpuType = js.three.FloatType;
        this.version = 0;
    }

    public function set needsUpdate(value:Bool) {
        if (value) {
            this.version++;
        }
    }

    public function get updateRange():Dynamic {
        trace('THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
        return this._updateRange;
    }

    public function setUsage(value:Int):BufferAttribute {
        this.usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int):Void {
        this.updateRanges.push({ start, count });
    }

    public function clearUpdateRanges():Void {
        this.updateRanges.length = 0;
    }

    public function copy(source:BufferAttribute):BufferAttribute {
        this.name = source.name;
        this.array = new source.array.constructor(source.array);
        this.itemSize = source.itemSize;
        this.count = source.count;
        this.normalized = source.normalized;
        this.usage = source.usage;
        this.gpuType = source.gpuType;
        return this;
    }

    public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
        index1 *= this.itemSize;
        index2 *= attribute.itemSize;

        for (i in 0...this.itemSize) {
            this.array[index1 + i] = attribute.array[index2 + i];
        }

        return this;
    }

    public function copyArray(array:Array<Float>):BufferAttribute {
        this.array.set(array);
        return this;
    }

    public function applyMatrix3(m:Dynamic):BufferAttribute {
        if (this.itemSize == 2) {
            for (i in 0...this.count) {
                var vector2 = new js.three.Vector2();
                vector2.fromBufferAttribute(this, i);
                vector2.applyMatrix3(m);
                this.setXY(i, vector2.x, vector2.y);
            }
        } else if (this.itemSize == 3) {
            for (i in 0...this.count) {
                var vector = new js.three.Vector3();
                vector.fromBufferAttribute(this, i);
                vector.applyMatrix3(m);
                this.setXYZ(i, vector.x, vector.y, vector.z);
            }
        }

        return this;
    }

    public function applyMatrix4(m:Dynamic):BufferAttribute {
        for (i in 0...this.count) {
            var vector = new js.three.Vector3();
            vector.fromBufferAttribute(this, i);
            vector.applyMatrix4(m);
            this.setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function applyNormalMatrix(m:Dynamic):BufferAttribute {
        for (i in 0...this.count) {
            var vector = new js.three.Vector3();
            vector.fromBufferAttribute(this, i);
            vector.applyNormalMatrix(m);
            this.setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function transformDirection(m:Dynamic):BufferAttribute {
        for (i in 0...this.count) {
            var vector = new js.three.Vector3();
            vector.fromBufferAttribute(this, i);
            vector.transformDirection(m);
            this.setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function set(value:Dynamic, offset:Int = 0):BufferAttribute {
        this.array.set(value, offset);
        return this;
    }

    public function getComponent(index:Int, component:Int):Float {
        var value = this.array[index * this.itemSize + component];
        if (this.normalized) {
            value = js.three.MathUtils.denormalize(value, this.array);
        }
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
        if (this.normalized) {
            value = js.three.MathUtils.normalize(value, this.array);
        }
        this.array[index * this.itemSize + component] = value;
        return this;
    }

    public function getX(index:Int):Float {
        var x = this.array[index * this.itemSize];
        if (this.normalized) {
            x = js.three.MathUtils.denormalize(x, this.array);
        }
        return x;
    }

    public function setX(index:Int, x:Float):BufferAttribute {
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
        }
        this.array[index * this.itemSize] = x;
        return this;
    }

    public function getY(index:Int):Float {
        var y = this.array[index * this.itemSize + 1];
        if (this.normalized) {
            y = js.three.MathUtils.denormalize(y, this.array);
        }
        return y;
    }

    public function setY(index:Int, y:Float):BufferAttribute {
        if (this.normalized) {
            y = js.three.MathUtils.normalize(y, this.array);
        }
        this.array[index * this.itemSize + 1] = y;
        return this;
    }

    public function getZ(index:Int):Float {
        var z = this.array[index * this.itemSize + 2];
        if (this.normalized) {
            z = js.three.MathUtils.denormalize(z, this.array);
        }
        return z;
    }

    public function setZ(index:Int, z:Float):BufferAttribute {
        if (this.normalized) {
            z = js.three.MathUtils.normalize(z, this.array);
        }
        this.array[index * this.itemSize + 2] = z;
        return this;
    }

    public function getW(index:Int):Float {
        var w = this.array[index * this.itemSize + 3];
        if (this.normalized) {
            w = js.three.MathUtils.denormalize(w, this.array);
        }
        return w;
    }

    public function setW(index:Int, w:Float):BufferAttribute {
        if (this.normalized) {
            w = js.three.MathUtils.normalize(w, this.array);
        }
        this.array[index * this.itemSize + 3] = w;
        return this;
    }

    public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
            z = js.three.MathUtils.normalize(z, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
            z = js.three.MathUtils.normalize(z, this.array);
            w = js.three.MathUtils.normalize(w, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        this.array[index + 3] = w;
        return this;
    }

    public function onUpload(callback:Dynamic):BufferAttribute {
        this.onUploadCallback = callback;
        return this;
    }

    public function clone():BufferAttribute {
        return new this.constructor(this.array, this.itemSize).copy(this);
    }

    public function toJSON():Dynamic {
        var data = {
            itemSize: this.itemSize,
            type: Type.getClassName(this.array),
            array: this.array.toArray(),
            normalized: this.normalized
        };

        if (this.name != '') {
            data.name = this.name;
        }
        if (this.usage != js.three.StaticDrawUsage) {
            data.usage = this.usage;
        }

        return data;
    }
}

class Int8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Int8Array(array), itemSize, normalized);
    }
}

class Uint8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Uint8Array(array), itemSize, normalized);
    }
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Uint8ClampedArray(array), itemSize, normalized);
    }
}

class Int16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Int16Array(array), itemSize, normalized);
    }
}

class Uint16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Uint16Array(array), itemSize, normalized);
    }
}

class Int32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Int32Array(array), itemSize, normalized);
    }
}

class Uint32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Uint32Array(array), itemSize, normalized);
    }
}

class Float16BufferAttribute extends BufferAttribute {
    public var isFloat16BufferAttribute:Bool;

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
        super(new Uint16Array(array), itemSize, normalized);
        this.isFloat16BufferAttribute = true;
    }

    public function getX(index:Int):Float {
        var x = js.three.DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
        if (this.normalized) {
            x = js.three.MathUtils.denormalize(x, this.array);
        }
        return x;
    }

    public function setX(index:Int, x:Float):Float16BufferAttribute {
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
        }
        this.array[index * this.itemSize] = js.three.DataUtils.toHalfFloat(x);
        return this;
    }

    public function getY(index:Int):Float {
        var y = js.three.DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
        if (this.normalized) {
            y = js.three.MathUtils.denormalize(y, this.array);
        }
        return y;
    }

    public function setY(index:Int, y:Float):Float16BufferAttribute {
        if (this.normalized) {
            y = js.three.MathUtils.normalize(y, this.array);
        }
        this.array[index * this.itemSize + 1] = js.three.DataUtils.toHalfFloat(y);
        return this;
    }

    public function getZ(index:Int):Float {
        var z = js.three.DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
        if (this.normalized) {
            z = js.three.MathUtils.denormalize(z, this.array);
        }
        return z;
    }

    public function setZ(index:Int, z:Float):Float16BufferAttribute {
        if (this.normalized) {
            z = js.three.MathUtils.normalize(z, this.array);
        }
        this.array[index * this.itemSize + 2] = js.three.DataUtils.toHalfFloat(z);
        return this;
    }

    public function getW(index:Int):Float {
        var w = js.three.DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
        if (this.normalized) {
            w = js.three.MathUtils.denormalize(w, this.array);
        }
        return w;
    }

    public function setW(index:Int, w:Float):Float16BufferAttribute {
        if (this.normalized) {
            w = js.three.MathUtils.normalize(w, this.array);
        }
        this.array[index * this.itemSize + 3] = js.three.DataUtils.toHalfFloat(w);
        return this;
    }

    public function setXY(index:Int, x:Float, y:Float):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
        }
        this.array[index + 0] = js.three.DataUtils.toHalfFloat(x);
        this.array[index + 1] = js.three.DataUtils.toHalfFloat(y);
        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
            z = js.three.MathUtils.normalize(z, this.array);
        }
        this.array[index + 0] = js.three.DataUtils.toHalfFloat(x);
        this.array[index + 1] = js.three.DataUtils.toHalfFloat(y);
        this.array[index + 2] = js.three.DataUtils.toHalfFloat(z);
        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
            z = js.three.MathUtils.normalize(z, this.array);
            w
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = js.three.MathUtils.normalize(x, this.array);
            y = js.three.MathUtils.normalize(y, this.array);
            z = js.three.MathUtils.normalize(z, this.array);
            w = js.three.MathUtils.normalize(w, this.array);
        }
        this.array[index + 0] = js.three.DataUtils.toHalfFloat(x);
        this.array[index + 1] = js.three.DataUtils.toHalfFloat(y);
        this.array[index + 2] = js.three.DataUtils.toHalfFloat(z);
        this.array[index + 3] = js.three.DataUtils.toHalfFloat(w);
        return this;
    }
}

class Float32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
        super(new Float32Array(array), itemSize, normalized);
    }
}

class Float32BufferAttribute {
    public function new(array:Float32Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Float16BufferAttribute {
    public function new(array:Uint16Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Uint32BufferAttribute {
    public function new(array:Uint32Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Int32BufferAttribute {
    public function new(array:Int32Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Uint16BufferAttribute {
    public function new(array:Uint16Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Int16BufferAttribute {
    public function new(array:Int16Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Uint8ClampedBufferAttribute {
    public function new(array:Uint8ClampedArray, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Uint8BufferAttribute {
    public function new(array:Uint8Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}

class Int8BufferAttribute {
    public function new(array:Int8Array, itemSize:Int, normalized:Bool = false) {
        super(array, itemSize, normalized);
    }
}