import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.warnOnce;

class BufferAttribute {

    public var name:String;
    public var array:Dynamic;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int;
    private var _updateRange:{ var offset:Int; var count:Int };
    public var updateRanges:Array<{ start:Int, count:Int }>;
    public var gpuType:Int;
    public var version:Int;
    public var isBufferAttribute:Bool;

    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        if (Reflect.isObject(array) && Reflect.hasField(array, "length")) {
            throw new haxe.exceptions.ValueException("THREE.BufferAttribute: array should be a Typed Array.");
        }

        this.isBufferAttribute = true;
        this.name = "";
        this.array = array;
        this.itemSize = itemSize;
        this.count = if (array != null) array.length / itemSize else 0;
        this.normalized = normalized;

        this.usage = StaticDrawUsage;
        this._updateRange = { offset: 0, count: -1 };
        this.updateRanges = [];
        this.gpuType = FloatType;

        this.version = 0;
    }

    public function set needsUpdate(value:Bool):Void {
        if (value) this.version++;
    }

    public function get updateRange():{ var offset:Int; var count:Int } {
        warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
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
        this.array = source.array.copy();
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

    public function copyArray(array:Dynamic):BufferAttribute {
        this.array.set(array);
        return this;
    }

    public function applyMatrix3(m:Matrix3):BufferAttribute {
        var vector = new Vector3();
        var vector2 = new Vector2();

        if (this.itemSize == 2) {
            for (i in 0...this.count) {
                vector2.fromBufferAttribute(this, i);
                vector2.applyMatrix3(m);

                this.setXY(i, vector2.x, vector2.y);
            }
        } else if (this.itemSize == 3) {
            for (i in 0...this.count) {
                vector.fromBufferAttribute(this, i);
                vector.applyMatrix3(m);

                this.setXYZ(i, vector.x, vector.y, vector.z);
            }
        }

        return this;
    }

    public function applyMatrix4(m:Matrix4):BufferAttribute {
        var vector = new Vector3();

        for (i in 0...this.count) {
            vector.fromBufferAttribute(this, i);
            vector.applyMatrix4(m);
            this.setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function applyNormalMatrix(m:Matrix3):BufferAttribute {
        var vector = new Vector3();

        for (i in 0...this.count) {
            vector.fromBufferAttribute(this, i);
            vector.applyNormalMatrix(m);
            this.setXYZ(i, vector.x, vector.y, vector.z);
        }

        return this;
    }

    public function transformDirection(m:Matrix4):BufferAttribute {
        var vector = new Vector3();

        for (i in 0...this.count) {
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

    public function getComponent(index:Int, component:Int):Dynamic {
        var value = this.array[index * this.itemSize + component];
        if (this.normalized) value = MathUtils.denormalize(value, this.array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Dynamic):BufferAttribute {
        if (this.normalized) value = MathUtils.normalize(value, this.array);
        this.array[index * this.itemSize + component] = value;
        return this;
    }

    public function getX(index:Int):Dynamic {
        var x = this.array[index * this.itemSize];
        if (this.normalized) x = MathUtils.denormalize(x, this.array);
        return x;
    }

    public function setX(index:Int, x:Dynamic):BufferAttribute {
        if (this.normalized) x = MathUtils.normalize(x, this.array);
        this.array[index * this.itemSize] = x;
        return this;
    }

    public function getY(index:Int):Dynamic {
        var y = this.array[index * this.itemSize + 1];
        if (this.normalized) y = MathUtils.denormalize(y, this.array);
        return y;
    }

    public function setY(index:Int, y:Dynamic):BufferAttribute {
        if (this.normalized) y = MathUtils.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = y;
        return this;
    }

    public function getZ(index:Int):Dynamic {
        var z = this.array[index * this.itemSize + 2];
        if (this.normalized) z = MathUtils.denormalize(z, this.array);
        return z;
    }

    public function setZ(index:Int, z:Dynamic):BufferAttribute {
        if (this.normalized) z = MathUtils.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = z;
        return this;
    }

    public function getW(index:Int):Dynamic {
        var w = this.array[index * this.itemSize + 3];
        if (this.normalized) w = MathUtils.denormalize(w, this.array);
        return w;
    }

    public function setW(index:Int, w:Dynamic):BufferAttribute {
        if (this.normalized) w = MathUtils.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = w;
        return this;
    }

    public function setXY(index:Int, x:Dynamic, y:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
        }
        this.array[index] = x;
        this.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Dynamic, y:Dynamic, z:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
        }
        this.array[index] = x;
        this.array[index + 1] = y;
        this.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Dynamic, y:Dynamic, z:Dynamic, w:Dynamic):BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
            w = MathUtils.normalize(w, this.array);
        }
        this.array[index] = x;
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
        return new BufferAttribute(this.array, this.itemSize, this.normalized).copy(this);
    }

    public function toJSON():Dynamic {
        var data:Dynamic = {
            itemSize: this.itemSize,
            type: Type.getClassName(Type.getClass(this.array)),
            array: this.array,
            normalized: this.normalized
        };

        if (this.name != "") data.name = this.name;
        if (this.usage != StaticDrawUsage) data.usage = this.usage;

        return data;
    }

    private var onUploadCallback:Void->Void;
}

class Int8BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Int8Array(array), itemSize, normalized);
    }
}

class Uint8BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Uint8Array(array), itemSize, normalized);
    }
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Uint8ClampedArray(array), itemSize, normalized);
    }
}

class Int16BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Int16Array(array), itemSize, normalized);
    }
}

class Uint16BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Uint16Array(array), itemSize, normalized);
    }
}

class Int32BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Int32Array(array), itemSize, normalized);
    }
}

class Uint32BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Uint32Array(array), itemSize, normalized);
    }
}

class Float16BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Uint16Array(array), itemSize, normalized);
        this.isFloat16BufferAttribute = true;
    }

    override public function getX(index:Int):Dynamic {
        var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
        if (this.normalized) x = MathUtils.denormalize(x, this.array);
        return x;
    }

    override public function setX(index:Int, x:Dynamic):Float16BufferAttribute {
        if (this.normalized) x = MathUtils.normalize(x, this.array);
        this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
        return this;
    }

    override public function getY(index:Int):Dynamic {
        var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
        if (this.normalized) y = MathUtils.denormalize(y, this.array);
        return y;
    }

    override public function setY(index:Int, y:Dynamic):Float16BufferAttribute {
        if (this.normalized) y = MathUtils.normalize(y, this.array);
        this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    override public function getZ(index:Int):Dynamic {
        var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
        if (this.normalized) z = MathUtils.denormalize(z, this.array);
        return z;
    }

    override public function setZ(index:Int, z:Dynamic):Float16BufferAttribute {
        if (this.normalized) z = MathUtils.normalize(z, this.array);
        this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    override public function getW(index:Int):Dynamic {
        var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
        if (this.normalized) w = MathUtils.denormalize(w, this.array);
        return w;
    }

    override public function setW(index:Int, w:Dynamic):Float16BufferAttribute {
        if (this.normalized) w = MathUtils.normalize(w, this.array);
        this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
        return this;
    }

    override public function setXY(index:Int, x:Dynamic, y:Dynamic):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
        }
        this.array[index] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        return this;
    }

    override public function setXYZ(index:Int, x:Dynamic, y:Dynamic, z:Dynamic):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
        }
        this.array[index] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        return this;
    }

    override public function setXYZW(index:Int, x:Dynamic, y:Dynamic, z:Dynamic, w:Dynamic):Float16BufferAttribute {
        index *= this.itemSize;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
            w = MathUtils.normalize(w, this.array);
        }
        this.array[index] = DataUtils.toHalfFloat(x);
        this.array[index + 1] = DataUtils.toHalfFloat(y);
        this.array[index + 2] = DataUtils.toHalfFloat(z);
        this.array[index + 3] = DataUtils.toHalfFloat(w);
        return this;
    }

    public var isFloat16BufferAttribute:Bool;
}

class Float32BufferAttribute extends BufferAttribute {
    public function new(array:Dynamic, itemSize:Int, ?normalized:Bool = false) {
        super(new haxe.io.Float32Array(array), itemSize, normalized);
    }
}

//

@:expose("three.Float32BufferAttribute")
@:expose("three.Float16BufferAttribute")
@:expose("three.Uint32BufferAttribute")
@:expose("three.Int32BufferAttribute")
@:expose("three.Uint16BufferAttribute")
@:expose("three.Int16BufferAttribute")
@:expose("three.Uint8ClampedBufferAttribute")
@:expose("three.Uint8BufferAttribute")
@:expose("three.Int8BufferAttribute")
@:expose("three.BufferAttribute")