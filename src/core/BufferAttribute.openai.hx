package three.core;

import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.Utils;

class BufferAttribute {
    public var isBufferAttribute:Bool;
    public var name:String;
    public var array:Array<Float>;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int;
    public var _updateRange:{offset:Int, count:Int};
    public var updateRanges:Array<{start:Int, count:Int}>;
    public var gpuType:Int;
    public var version:Int;

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
        if (!Std.isOfType(array, Array<Float>)) {
            throw new TypeError('THREE.BufferAttribute: array should be a Typed Array.');
        }

        isBufferAttribute = true;
        this.array = array;
        this.itemSize = itemSize;
        this.count = array.length / itemSize;
        this.normalized = normalized;
        this.usage = StaticDrawUsage;
        this._updateRange = {offset: 0, count: -1};
        this.updateRanges = [];
        this.gpuType = FloatType;
        this.version = 0;
    }

    public function onUploadCallback() {}

    public function setNeedsUpdate(value:Bool) {
        if (value) version++;
    }

    public function getUpdateRange(): {offset:Int, count:Int} {
        Utils.warnOnce('THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
        return _updateRange;
    }

    public function setUsage(value:Int):BufferAttribute {
        usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int) {
        updateRanges.push({start: start, count: count});
    }

    public function clearUpdateRanges() {
        updateRanges = [];
    }

    public function copy(source:BufferAttribute):BufferAttribute {
        name = source.name;
        array = new Float32Array(source.array);
        itemSize = source.itemSize;
        count = source.count;
        normalized = source.normalized;
        usage = source.usage;
        gpuType = source.gpuType;
        return this;
    }

    public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
        index1 *= itemSize;
        index2 *= attribute.itemSize;

        for (i in 0...itemSize) {
            array[index1 + i] = attribute.array[index2 + i];
        }

        return this;
    }

    public function copyArray(array:Array<Float>):BufferAttribute {
        this.array.set(array);
        return this;
    }

    public function applyMatrix3(m:Matrix3):BufferAttribute {
        if (itemSize == 2) {
            for (i in 0...count) {
                var vector = new Vector2();
                vector.fromBufferAttribute(this, i);
                vector.applyMatrix3(m);

                setXY(i, vector.x, vector.y);
            }
        } else if (itemSize == 3) {
            for (i in 0...count) {
                var vector = new Vector3();
                vector.fromBufferAttribute(this, i);
                vector.applyMatrix3(m);

                setXYZ(i, vector.x, vector.y, vector.z);
            }
        }

        return this;
    }

    public function applyMatrix4(m:Matrix4):BufferAttribute {
        for (i in 0...count) {
            var vector = new Vector3();
            vector.fromBufferAttribute(this, i);
            vector.applyMatrix4(m);

            setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function applyNormalMatrix(m:Matrix3):BufferAttribute {
        for (i in 0...count) {
            var vector = new Vector3();
            vector.fromBufferAttribute(this, i);
            vector.applyNormalMatrix(m);

            setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function transformDirection(m:Matrix4):BufferAttribute {
        for (i in 0...count) {
            var vector = new Vector3();
            vector.fromBufferAttribute(this, i);
            vector.transformDirection(m);

            setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
        array.set(value, offset);
        return this;
    }

    public function getComponent(index:Int, component:Int):Float {
        var value = array[index * itemSize + component];
        if (normalized) value = MathUtils.denormalize(value, array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
        if (normalized) value = MathUtils.normalize(value, array);
        array[index * itemSize + component] = value;
        return this;
    }

    public function getX(index:Int):Float {
        var x = array[index * itemSize];
        if (normalized) x = MathUtils.denormalize(x, array);
        return x;
    }

    public function setX(index:Int, x:Float):BufferAttribute {
        if (normalized) x = MathUtils.normalize(x, array);
        array[index * itemSize] = x;
        return this;
    }

    public function getY(index:Int):Float {
        var y = array[index * itemSize + 1];
        if (normalized) y = MathUtils.denormalize(y, array);
        return y;
    }

    public function setY(index:Int, y:Float):BufferAttribute {
        if (normalized) y = MathUtils.normalize(y, array);
        array[index * itemSize + 1] = y;
        return this;
    }

    public function getZ(index:Int):Float {
        var z = array[index * itemSize + 2];
        if (normalized) z = MathUtils.denormalize(z, array);
        return z;
    }

    public function setZ(index:Int, z:Float):BufferAttribute {
        if (normalized) z = MathUtils.normalize(z, array);
        array[index * itemSize + 2] = z;
        return this;
    }

    public function getW(index:Int):Float {
        var w = array[index * itemSize + 3];
        if (normalized) w = MathUtils.denormalize(w, array);
        return w;
    }

    public function setW(index:Int, w:Float):BufferAttribute {
        if (normalized) w = MathUtils.normalize(w, array);
        array[index * itemSize + 3] = w;
        return this;
    }

    public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
        index *= itemSize;

        if (normalized) {
            x = MathUtils.normalize(x, array);
            y = MathUtils.normalize(y, array);
        }

        array[index + 0] = x;
        array[index + 1] = y;

        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
        index *= itemSize;

        if (normalized) {
            x = MathUtils.normalize(x, array);
            y = MathUtils.normalize(y, array);
            z = MathUtils.normalize(z, array);
        }

        array[index + 0] = x;
        array[index + 1] = y;
        array[index + 2] = z;

        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
        index *= itemSize;

        if (normalized) {
            x = MathUtils.normalize(x, array);
            y = MathUtils.normalize(y, array);
            z = MathUtils.normalize(z, array);
            w = MathUtils.normalize(w, array);
        }

        array[index + 0] = x;
        array[index + 1] = y;
        array[index + 2] = z;
        array[index + 3] = w;

        return this;
    }

    public function onUpload(callback:Void->Void):BufferAttribute {
        onUploadCallback = callback;
        return this;
    }

    public function clone():BufferAttribute {
        return new BufferAttribute(array, itemSize).copy(this);
    }

    public function toJSON():Dynamic {
        var data = {
            itemSize: itemSize,
            type: 'Float32Array',
            array: array.toArray(),
            normalized: normalized
        };

        if (name != '') data.name = name;
        if (usage != StaticDrawUsage) data.usage = usage;

        return data;
    }
}

class Int8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Int8Array(array), itemSize, normalized);
    }
}

class Uint8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Uint8Array(array), itemSize, normalized);
    }
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Uint8ClampedArray(array), itemSize, normalized);
    }
}

class Int16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Int16Array(array), itemSize, normalized);
    }
}

class Uint16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Uint16Array(array), itemSize, normalized);
    }
}

class Int32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Int32Array(array), itemSize, normalized);
    }
}

class Uint32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Uint32Array(array), itemSize, normalized);
    }
}

class Float16BufferAttribute extends BufferAttribute {
    public var isFloat16BufferAttribute:Bool;

    public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
        super(new Uint16Array(array), itemSize, normalized);
        isFloat16BufferAttribute = true;
    }

    override public function getX(index:Int):Float {
        var x = DataUtils.fromHalfFloat(array[index * itemSize]);
        if (normalized) x = MathUtils.denormalize(x, array);
        return x;
    }

    override public function setX(index:Int, x:Float):BufferAttribute {
        if (normalized) x = MathUtils.normalize(x, array);
        array[index * itemSize] = DataUtils.toHalfFloat(x);
        return this;
    }

    override public function getY(index:Int):Float {
        var y = DataUtils.fromHalfFloat(array[index * itemSize + 1]);
        if (normalized) y = MathUtils.denormalize(y, array);
        return y;
    }

    override public function setY(index:Int, y:Float):BufferAttribute {
        if (normalized) y = MathUtils.normalize(y, array);
        array[index * itemSize + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    override public function getZ(index:Int):Float {
        var z = DataUtils.fromHalfFloat(array[index * itemSize + 2]);
        if (normalized) z = MathUtils.denormalize(z, array);
        return z;
    }

    override public function setZ(index:Int, z:Float):BufferAttribute {
        if (normalized) z = MathUtils.normalize(z, array);
        array[index * itemSize + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    override public function getW(index:Int):Float {
        var w = DataUtils.fromHalfFloat(array[index * itemSize + 3]);
        if (normalized) w = MathUtils.denormalize(w, array);
        return w;
    }

    override public function setW(index:Int, w:Float):BufferAttribute {
        if (normalized) w = MathUtils.normalize(w, array);
        array[index * itemSize + 3] = DataUtils.toHalfFloat(w);
        return this;
    }

    override public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
        index *= itemSize;

        if (normalized) {
            x = MathUtils.normalize(x, array);
            y = MathUtils.normalize(y, array);
        }

        array[index + 0] = DataUtils.toHalfFloat(x);
        array[index + 1] = DataUtils.toHalfFloat(y);

        return this;
    }

    override public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
        index *= itemSize;

        if (normalized) {
            x = MathUtils.normalize(x, array);
            y = MathUtils.normalize(y, array);
            z = MathUtils.normalize(z, array);
        }

        array[index + 0] = DataUtils.toHalfFloat(x);
        array[index + 1] = DataUtils.toHalfFloat(y);
        array[index + 2] = DataUtils.toHalfFloat(z);

        return this;
    }

    override public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
        index *= itemSize;

        if (normalized) {
            x = MathUtils.normalize(x, array);
            y = MathUtils.normalize(y, array);
            z = MathUtils.normalize(z, array);
            w = MathUtils.normalize(w, array);
        }

        array[index + 0] = DataUtils.toHalfFloat(x);
        array[index + 1] = DataUtils.toHalfFloat(y);
        array[index + 2] = DataUtils.toHalfFloat(z);
        array[index + 3] = DataUtils.toHalfFloat(w);

        return this;
    }
}

class Float32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
        super(new Float32Array(array), itemSize, normalized);
    }
}