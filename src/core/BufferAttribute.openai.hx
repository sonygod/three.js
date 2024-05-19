import math.Vector3;
import math.Vector2;
import math.MathUtils;
import constants.StaticDrawUsage;
import constants.FloatType;
import extras.DataUtils;
import utils.warnOnce;


class BufferAttribute {

    public var isBufferAttribute:Bool = true;
    public var name:String = '';
    public var array:Dynamic;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int = StaticDrawUsage;
    public var _updateRange:Dynamic = { offset: 0, count: - 1 };
    public var updateRanges:Array<Dynamic> = [];
    public var gpuType:Int = FloatType;
    public var version:Int = 0;

    public function new(array:Dynamic, itemSize:Int, normalized:Bool = false) {
        if (array:js.Array) {
            throw new TypeError('THREE.BufferAttribute: array should be a Typed Array.');
        }
        this.array = array;
        this.itemSize = itemSize;
        this.count = (array != null) ? array.length / itemSize : 0;
        this.normalized = normalized;
    }

    public function onUploadCallback():Void {}

    public var needsUpdate:Bool;

    public function get updateRange():Dynamic {
        warnOnce('THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
        return this._updateRange;
    }

    public function setUsage(value:Int):BufferAttribute {
        this.usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int):Void {
        this.updateRanges.push({ start: start, count: count });
    }

    public function clearUpdateRanges():Void {
        this.updateRanges = [];
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
        var i = 0;
        var l = this.itemSize;
        while (i < l) {
            this.array[index1 + i] = attribute.array[index2 + i];
            i++;
        }
        return this;
    }

    public function copyArray(array:Dynamic):BufferAttribute {
        this.array.set(array);
        return this;
    }

    public function applyMatrix3(m:Matrix3):BufferAttribute {
        if (this.itemSize == 2) {
            var i = 0;
            var l = this.count;
            while (i < l) {
                math._v2.fromBufferAttribute(this, i);
                math._v2.applyMatrix3(m);
                this.setXY(i, math._v2.x, math._v2.y);
                i++;
            }
        } else if (this.itemSize == 3) {
            var i = 0;
            var l = this.count;
            while (i < l) {
                math._v3.fromBufferAttribute(this, i);
                math._v3.applyMatrix3(m);
                this.setXYZ(i, math._v3.x, math._v3.y, math._v3.z);
                i++;
            }
        }
        return this;
    }

    public function applyMatrix4(m:Matrix4):BufferAttribute {
        var i = 0;
        var l = this.count;
        while (i < l) {
            math._v.fromBufferAttribute(this, i);
            math._v.applyMatrix4(m);
            this.setXYZ(i, math._v.x, math._v.y, math._v.z);
            i++;
        }
        return this;
    }

    public function applyNormalMatrix(m:Matrix3):BufferAttribute {
        var i = 0;
        var l = this.count;
        while (i < l) {
            math._v.fromBufferAttribute(this, i);
            math._v.applyNormalMatrix(m);
            this.setXYZ(i, math._v.x, math._v.y, math._v.z);
            i++;
        }
        return this;
    }

    public function transformDirection(m:Matrix4):BufferAttribute {
        var i = 0;
        var l = this.count;
        while (i < l) {
            math._v.fromBufferAttribute(this, i);
            math._v.transformDirection(m);
            this.setXYZ(i, math._v.x, math._v.y, math._v.z);
            i++;
        }
        return this;
    }

    public function set(value:Dynamic, offset:Int = 0):BufferAttribute {
        this.array.set(value, offset);
        return this;
    }

    public function getComponent(index:Int, component:Int):Dynamic {
        var value = this.array[index * this.itemSize + component];
        if (this.normalized) value = math.denormalize(value, this.array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Dynamic):BufferAttribute {
        if (this.normalized) value = math.normalize(value, this.array);
        this.array[index * this.itemSize + component] = value;
        return this;
    }

    public function getX(index:Int):Dynamic {
        var x = this.array[index * this.itemSize];
        if (this.normalized) x = math.denormalize(x, this.array);
        return x;
    }

    public function setX(index:Int, x:Dynamic):BufferAttribute {
        if (this.normalized) x = math.normalize(x, this.array);
        this.array[index * this.itemSize] = x;
        return this;
    }

    public function getY(index:Int):Dynamic {
        var y = this.array[index * this.itemSize + 1];
        if (this.normalized) y = math.denormalize(y, this.array);
        return y;
    }

    public function setY(index:Int, y:Dynamic):BufferAttribute {
        if (this.normalized) y = math.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = y;
        return this;
    }

    public function getZ(index:Int):Dynamic {
        var z = this.array[index * this.itemSize + 2];
        if (this.normalized) z = math.denormalize(z, this.array);
        return z;
    }

    public function setZ(index:Int, z:Dynamic):BufferAttribute {
        if (this.normalized) z = math.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = z;
        return this;
    }

    public function getW(index:Int):Dynamic {
        var w = this.array[index * this.itemSize + 3];
        if (this.normalized) w = math.denormalize(w, this.array);
        return w;
    }

    public function setW(index:Int, w:Dynamic):BufferAttribute {
        if (this.normalized) w = math.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = w;
        return this;
    }

    public function setXY(index:Int, x:Dynamic, y:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Dynamic, y:Dynamic, z:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
            z = math.normalize(z, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Dynamic, y:Dynamic, z:Dynamic, w:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
            z = math.normalize(z, this.array);
            w = math.normalize(w, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        this.array[index + 3] = w;
        return this;
    }

    public function onUpload(callback: Void->Void):BufferAttribute {
        this.onUploadCallback = callback;
        return this;
    }

    public function clone():BufferAttribute {
        return new this.constructor(this.array, this.itemSize).copy(this);
    }

    public function toJSON():Dynamic {
        var data = {
            itemSize: this.itemSize,
            type: this.array.constructor.name,
            array: this.array.toArray(),
            normalized: this.normalized
        };
        if (this.name != '') data.name = this.name;
        if (this.usage != StaticDrawUsage) data.usage = this.usage;
        return data;
    }
}


class Int8BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Int8Array(array), itemSize, normalized);
    }

}


class Uint8BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint8Array(array), itemSize, normalized);
    }

}


class Uint8ClampedBufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint8ClampedArray(array), itemSize, normalized);
    }

}


class Int16BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Int16Array(array), itemSize, normalized);
    }

}


class Uint16BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint16Array(array), itemSize, normalized);
    }
}


class Int32BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Int32Array(array), itemSize, normalized);
    }
}


class Uint32BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint32Array(array), itemSize, normalized);
    }
}


class Float16BufferAttribute extends BufferAttribute {

    public var isFloat16BufferAttribute:Bool = true;

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint16Array(array), itemSize, normalized);
    }

    public function getX(index:Int):Dynamic {
        var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
        if (this.normalized) x = math.denormalize(x, this.array);
        return x;
    }

    public function setX(index:Int, x:Dynamic):BufferAttribute {
        if (this.normalized) x = math.normalize(x, this.array);
        this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
        return this;
    }

    public function getY(index:Int):Dynamic {
        var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
        if (this.normalized) y = math.denormalize(y, this.array);
        return y;
    }

    public function setY(index:Int, y:Dynamic):BufferAttribute {
        if (this.normalized) y = math.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    public function getZ(index:Int):Dynamic {
        var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
        if (this.normalized) z = math.denormalize(z, this.array);
        return z;
    }

    public function setZ(index:Int, z:Dynamic):BufferAttribute {
        if (this.normalized) z = math.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    public function getW(index:Int):Dynamic {
        var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
        if (this.normalized) w = math.denormalize(w, this.array);
        return w;
    }

    public function setW(index:Int, w:Dynamic):BufferAttribute {
        if (this.normalized) w = math.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
        return this;
    }

    public function setXY(index:Int, x:Dynamic, y:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    public function setXYZ(index:Int, x:Dynamic, y:Dynamic, z:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
            z = math.normalize(z, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    public function setXYZW(index:Int, x:Dynamic, y:Dynamic, z:Dynamic, w:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
            z = math.normalize(z, this.array);
            w = math.normalize(w, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        this.array[index + 3] = DataUtils.toHalfFloat(w);
        return this;
    }
}


class Float32BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Float32Array(array), itemSize, normalized);
    }
}


class Int8BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Int8Array(array), itemSize, normalized);
    }
}


class Uint8BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint8Array(array), itemSize, normalized);
    }
}


class Uint8ClampedBufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint8ClampedArray(array), itemSize, normalized);
    }
}


class Int16BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Int16Array(array), itemSize, normalized);
    }
}


class Uint16BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint16Array(array), itemSize, normalized);
    }
}


class Int32BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Int32Array(array), itemSize, normalized);
    }
}


class Uint32BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint32Array(array), itemSize, normalized);
    }
}


class Float16BufferAttribute extends BufferAttribute {

    public var isFloat16BufferAttribute:Bool = true;

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Uint16Array(array), itemSize, normalized);
    }

    public function getX(index:Int):Dynamic {
        var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
        if (this.normalized) x = math.denormalize(x, this.array);
        return x;
    }

    public function setX(index:Int, x:Dynamic):BufferAttribute {
        if (this.normalized) x = math.normalize(x, this.array);
        this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
        return this;
    }

    public function getY(index:Int):Dynamic {
        var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
        if (this.normalized) y = math.denormalize(y, this.array);
        return y;
    }

    public function setY(index:Int, y:Dynamic):BufferAttribute {
        if (this.normalized) y = math.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    public function getZ(index:Int):Dynamic {
        var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
        if (this.normalized) z = math.denormalize(z, this.array);
        return z;
    }

    public function setZ(index:Int, z:Dynamic):BufferAttribute {
        if (this.normalized) z = math.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    public function getW(index:Int):Dynamic {
        var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
        if (this.normalized) w = math.denormalize(w, this.array);
        return w;
    }

    public function setW(index:Int, w:Dynamic):BufferAttribute {
        if (this.normalized) w = math.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
        return this;
    }

    public function setXY(index:Int, x:Dynamic, y:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    public function setXYZ(index:Int, x:Dynamic, y:Dynamic, z:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
            z = math.normalize(z, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    public function setXYZW(index:Int, x:Dynamic, y:Dynamic, z:Dynamic, w:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = math.normalize(x, this.array);
            y = math.normalize(y, this.array);
            z = math.normalize(z, this.array);
            w = math.normalize(w, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        this.array[index + 3] = DataUtils.toHalfFloat(w);
        return this;
    }
}


class Float32BufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, normalized:Bool) {
        super(new Float32Array(array), itemSize, normalized);
    }
}


class BufferAttributeConverter {
    public static var Float32BufferAttribute = Float32BufferAttribute;
    public static var Float16BufferAttribute = Float16BufferAttribute;
    public static var Uint32BufferAttribute = Uint32BufferAttribute;
    public static var Int32BufferAttribute = Int32BufferAttribute;
    public static var Uint16BufferAttribute = Uint16BufferAttribute;
    public static var Int16BufferAttribute = Int16BufferAttribute;
    public static var Uint8ClampedBufferAttribute = Uint8ClampedBufferAttribute;
    public static var Uint8BufferAttribute = Uint8BufferAttribute;
    public static var Int8BufferAttribute = Int8BufferAttribute;
    public static var BufferAttribute = BufferAttribute;
}
