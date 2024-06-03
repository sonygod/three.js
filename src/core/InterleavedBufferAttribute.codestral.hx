import three.math.Vector3;
import three.core.BufferAttribute;
import three.math.MathUtils;

class InterleavedBufferAttribute {
    public var isInterleavedBufferAttribute:Bool = true;
    public var name:String = "";
    public var data:InterleavedBuffer;
    public var itemSize:Int;
    public var offset:Int;
    public var normalized:Bool;

    public function new(interleavedBuffer:InterleavedBuffer, itemSize:Int, offset:Int, normalized:Bool = false) {
        this.data = interleavedBuffer;
        this.itemSize = itemSize;
        this.offset = offset;
        this.normalized = normalized;
    }

    public function get count():Int {
        return this.data.count;
    }

    public function get array():Array<Dynamic> {
        return this.data.array;
    }

    public function set needsUpdate(value:Bool) {
        this.data.needsUpdate = value;
    }

    public function applyMatrix4(m:Matrix4) {
        var _vector = new Vector3();
        for (var i:Int = 0; i < this.data.count; i++) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyMatrix4(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function applyNormalMatrix(m:Matrix4) {
        var _vector = new Vector3();
        for (var i:Int = 0; i < this.count; i++) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyNormalMatrix(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function transformDirection(m:Matrix4) {
        var _vector = new Vector3();
        for (var i:Int = 0; i < this.count; i++) {
            _vector.fromBufferAttribute(this, i);
            _vector.transformDirection(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function getComponent(index:Int, component:Int):Dynamic {
        var value = this.array[index * this.data.stride + this.offset + component];
        if (this.normalized) value = MathUtils.denormalize(value, this.array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Dynamic) {
        if (this.normalized) value = MathUtils.normalize(value, this.array);
        this.data.array[index * this.data.stride + this.offset + component] = value;
        return this;
    }

    public function setX(index:Int, x:Dynamic) {
        if (this.normalized) x = MathUtils.normalize(x, this.array);
        this.data.array[index * this.data.stride + this.offset] = x;
        return this;
    }

    public function setY(index:Int, y:Dynamic) {
        if (this.normalized) y = MathUtils.normalize(y, this.array);
        this.data.array[index * this.data.stride + this.offset + 1] = y;
        return this;
    }

    public function setZ(index:Int, z:Dynamic) {
        if (this.normalized) z = MathUtils.normalize(z, this.array);
        this.data.array[index * this.data.stride + this.offset + 2] = z;
        return this;
    }

    public function setW(index:Int, w:Dynamic) {
        if (this.normalized) w = MathUtils.normalize(w, this.array);
        this.data.array[index * this.data.stride + this.offset + 3] = w;
        return this;
    }

    public function getX(index:Int):Dynamic {
        var x = this.data.array[index * this.data.stride + this.offset];
        if (this.normalized) x = MathUtils.denormalize(x, this.array);
        return x;
    }

    public function getY(index:Int):Dynamic {
        var y = this.data.array[index * this.data.stride + this.offset + 1];
        if (this.normalized) y = MathUtils.denormalize(y, this.array);
        return y;
    }

    public function getZ(index:Int):Dynamic {
        var z = this.data.array[index * this.data.stride + this.offset + 2];
        if (this.normalized) z = MathUtils.denormalize(z, this.array);
        return z;
    }

    public function getW(index:Int):Dynamic {
        var w = this.data.array[index * this.data.stride + this.offset + 3];
        if (this.normalized) w = MathUtils.denormalize(w, this.array);
        return w;
    }

    public function setXY(index:Int, x:Dynamic, y:Dynamic) {
        index = index * this.data.stride + this.offset;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
        }
        this.data.array[index + 0] = x;
        this.data.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Dynamic, y:Dynamic, z:Dynamic) {
        index = index * this.data.stride + this.offset;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
        }
        this.data.array[index + 0] = x;
        this.data.array[index + 1] = y;
        this.data.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Dynamic, y:Dynamic, z:Dynamic, w:Dynamic) {
        index = index * this.data.stride + this.offset;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.array);
            y = MathUtils.normalize(y, this.array);
            z = MathUtils.normalize(z, this.array);
            w = MathUtils.normalize(w, this.array);
        }
        this.data.array[index + 0] = x;
        this.data.array[index + 1] = y;
        this.data.array[index + 2] = z;
        this.data.array[index + 3] = w;
        return this;
    }

    public function clone(data:Dynamic = null):BufferAttribute {
        if (data == null) {
            trace("THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");
            var array = [];
            for (var i:Int = 0; i < this.count; i++) {
                var index:Int = i * this.data.stride + this.offset;
                for (var j:Int = 0; j < this.itemSize; j++) {
                    array.push(this.data.array[index + j]);
                }
            }
            return new BufferAttribute(new this.array.constructor(array), this.itemSize, this.normalized);
        } else {
            if (data.interleavedBuffers == null) {
                data.interleavedBuffers = {};
            }
            if (data.interleavedBuffers[this.data.uuid] == null) {
                data.interleavedBuffers[this.data.uuid] = this.data.clone(data);
            }
            return new InterleavedBufferAttribute(data.interleavedBuffers[this.data.uuid], this.itemSize, this.offset, this.normalized);
        }
    }

    public function toJSON(data:Dynamic = null):Dynamic {
        if (data == null) {
            trace("THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");
            var array = [];
            for (var i:Int = 0; i < this.count; i++) {
                var index:Int = i * this.data.stride + this.offset;
                for (var j:Int = 0; j < this.itemSize; j++) {
                    array.push(this.data.array[index + j]);
                }
            }
            return {
                itemSize: this.itemSize,
                type: Type.getClassName(Type.getClass(this.array)),
                array: array,
                normalized: this.normalized
            };
        } else {
            if (data.interleavedBuffers == null) {
                data.interleavedBuffers = {};
            }
            if (data.interleavedBuffers[this.data.uuid] == null) {
                data.interleavedBuffers[this.data.uuid] = this.data.toJSON(data);
            }
            return {
                isInterleavedBufferAttribute: true,
                itemSize: this.itemSize,
                data: this.data.uuid,
                offset: this.offset,
                normalized: this.normalized
            };
        }
    }
}