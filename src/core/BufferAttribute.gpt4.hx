import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.*;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {

    public var isBufferAttribute:Bool;
    public var name:String;
    public var array:haxe.io.Float32Array;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Dynamic;
    private var _updateRange:{offset:Int, count:Int};
    public var updateRanges:Array<{start:Int, count:Int}>;
    public var gpuType:Dynamic;
    public var version:Int;
    private var onUploadCallback:Void->Void;

    public function new(array:haxe.io.Float32Array, itemSize:Int, normalized:Bool = false) {
        if (array == null) {
            throw new TypeError('THREE.BufferAttribute: array should be a Typed Array.');
        }

        this.isBufferAttribute = true;
        this.name = '';
        this.array = array;
        this.itemSize = itemSize;
        this.count = array != null ? array.length / itemSize : 0;
        this.normalized = normalized;
        this.usage = StaticDrawUsage;
        this._updateRange = {offset: 0, count: -1};
        this.updateRanges = [];
        this.gpuType = FloatType;
        this.version = 0;
        this.onUploadCallback = function() {};
    }

    public function set needsUpdate(value:Bool):Void {
        if (value == true) this.version++;
    }

    public function get updateRange():Dynamic {
        WarnOnce.warn('THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.');
        return this._updateRange;
    }

    public function setUsage(value:Dynamic):BufferAttribute {
        this.usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int):Void {
        this.updateRanges.push({start: start, count: count});
    }

    public function clearUpdateRanges():Void {
        this.updateRanges = [];
    }

    public function copy(source:BufferAttribute):BufferAttribute {
        this.name = source.name;
        this.array = new haxe.io.Float32Array(source.array.length);
        this.array.set(source.array);
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

    public function copyArray(array:haxe.io.Float32Array):BufferAttribute {
        this.array.set(array);
        return this;
    }

    public function applyMatrix3(m:Matrix3):BufferAttribute {
        var _vector = new Vector3();
        var _vector2 = new Vector2();
        if (this.itemSize == 2) {
            for (i in 0...this.count) {
                _vector2.fromBufferAttribute(this, i);
                _vector2.applyMatrix3(m);
                this.setXY(i, _vector2.x, _vector2.y);
            }
        } else if (this.itemSize == 3) {
            for (i in 0...this.count) {
                _vector.fromBufferAttribute(this, i);
                _vector.applyMatrix3(m);
                this.setXYZ(i, _vector.x, _vector.y, _vector.z);
            }
        }
        return this;
    }

    public function applyMatrix4(m:Matrix4):BufferAttribute {
        var _vector = new Vector3();
        for (i in 0...this.count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyMatrix4(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function applyNormalMatrix(m:Matrix3):BufferAttribute {
        var _vector = new Vector3();
        for (i in 0...this.count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyNormalMatrix(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function transformDirection(m:Matrix4):BufferAttribute {
        var _vector = new Vector3();
        for (i in 0...this.count) {
            _vector.fromBufferAttribute(this, i);
            _vector.transformDirection(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function set(value:haxe.io.Float32Array, offset:Int = 0):BufferAttribute {
        this.array.set(value, offset);
        return this;
    }

    public function getComponent(index:Int, component:Int):Float {
        var value = this.array[index * this.itemSize + component];
        if (this.normalized) value = MathUtils.denormalize(value, this.array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
        if (this.normalized) value = MathUtils.normalize(value, this.array);
        this.array[index * this.itemSize + component] = value;
        return this;
    }

    public function getX(index:Int):Float {
        var x = this.array[index * this.itemSize];
        if (this.normalized) x = MathUtils.denormalize(x, this.array);
        return x;
    }

    public function setX(index:Int, x:Float):BufferAttribute {
        if (this.normalized) x = MathUtils.normalize(x, this.array);
        this.array[index * this.itemSize] = x;
        return this;
    }

    public function getY(index:Int):Float {
        var y = this.array[index * this.itemSize + 1];
        if (this.normalized) y = MathUtils.denormalize(y, this.array);
        return y;
    }

    public function setY(index:Int, y:Float):BufferAttribute {
        if (this.normalized) y = MathUtils.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = y;
        return this;
    }

    public function getZ(index:Int):Float {
        var z = this.array[index * this.itemSize + 2];
        if (this.normalized) z = MathUtils.denormalize(z, this.array);
        return z;
    }

    public function setZ(index:Int, z:Float):BufferAttribute {
        if (this.normalized) z = MathUtils.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = z;
        return this;
    }

    public function getW(index:Int):Float {
        var w = this.array[index * this.itemSize + 3];
        if (this.normalized) w = MathUtils.denormalize(w, this.array);
        return w;
    }

    public function setW(index:Int, w:Float):BufferAttribute {
        if (this.normalized) w = MathUtils.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = w;
        return this;
    }

    public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
            w = MathUtils.normalize(w, this.array);
        }
        this.array[index + 0] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        this.array[index + 3] = w;
        return this;
    }

    public function onUpload(callback:Void->Void):BufferAttribute {
        this.onUploadCallback = callback;
        return this;
    }

    public function clone():BufferAttribute {
        return new BufferAttribute(this.array, this.itemSize).copy(this);
    }

    public function toJSON():Dynamic {
        var data = {
            itemSize: this.itemSize,
            type: Type.getClassName(this.array.__c),
            array: this.array.toArray(),
            normalized: this.normalized
        };
        if (this.name != '') data.name = this.name;
        if (this.usage != StaticDrawUsage) data.usage = this.usage;
        return data;
    }
}

//

class Int8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.Int8Array.ofArray(array), itemSize, normalized);
    }
}

class Uint8BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.UInt8Array.ofArray(array), itemSize, normalized);
    }
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.UInt8ClampedArray.ofArray(array), itemSize, normalized);
    }
}

class Int16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.Int16Array.ofArray(array), itemSize, normalized);
    }
}

class Uint16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.UInt16Array.ofArray(array), itemSize, normalized);
    }
}

class Int32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.Int32Array.ofArray(array), itemSize, normalized);
    }
}

class Uint32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.UInt32Array.ofArray(array), itemSize, normalized);
    }
}

class Float16BufferAttribute extends BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(haxe.io.UInt16Array.ofArray(array), itemSize, normalized);
    }

    public override function getX(index:Int):Float {
        var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
        if (this.normalized) x = MathUtils.denormalize(x, this.array);
        return x;
    }

    public override function setX(index:Int, x:Float):BufferAttribute {
        if (this.normalized) x = MathUtils.normalize(x, this.array);
        this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
        return this;
    }

    public override function getY(index:Int):Float {
        var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
        if (this.normalized) y = MathUtils.denormalize(y, this.array);
        return y;
    }

    public override function setY(index:Int, y:Float):BufferAttribute {
        if (this.normalized) y = MathUtils.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    public override function getZ(index:Int):Float {
        var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
        if (this.normalized) z = MathUtils.denormalize(z, this.array);
        return z;
    }

    public override function setZ(index:Int, z:Float):BufferAttribute {
        if (this.normalized) z = MathUtils.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    public override function getW(index:Int):Float {
        var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
        if (this.normalized) w = MathUtils.denormalize(w, this.array);
        return w;
    }

    public override function setW(index:Int, w:Float):BufferAttribute {
        if (this.normalized) w = MathUtils.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
        return this;
    }

    public override function setXY(index:Int, x:Float, y:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    public override function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    public override function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
            w = MathUtils.normalize(w, this.array);
        }
        this.array[index + 0] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        this.array[index + 3] = DataUtils.toHalfFloat(w);
        return this;
    }
}

class Float32BufferAttribute extends BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
        super(haxe.io.Float32Array.ofArray(array), itemSize, normalized);
    }
}