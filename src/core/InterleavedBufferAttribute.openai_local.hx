import three.math.Vector3;
import three.core.BufferAttribute;
import three.math.MathUtils;

class InterleavedBufferAttribute {
    public var isInterleavedBufferAttribute:Bool;
    public var name:String;
    public var data:InterleavedBuffer; // 假设 InterleavedBuffer 是一个类，需在其他地方定义
    public var itemSize:Int;
    public var offset:Int;
    public var normalized:Bool;

    private static var _vector:Vector3 = new Vector3();

    public function new(interleavedBuffer:InterleavedBuffer, itemSize:Int, offset:Int, normalized:Bool = false) {
        this.isInterleavedBufferAttribute = true;
        this.name = '';
        this.data = interleavedBuffer;
        this.itemSize = itemSize;
        this.offset = offset;
        this.normalized = normalized;
    }

    public function get_count():Int {
        return this.data.count;
    }

    public function get_array():Array<Float> {
        return this.data.array;
    }

    public function set_needsUpdate(value:Bool):Void {
        this.data.needsUpdate = value;
    }

    public function applyMatrix4(m:Matrix4):InterleavedBufferAttribute {
        for (i in 0...this.data.count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyMatrix4(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function applyNormalMatrix(m:Matrix3):InterleavedBufferAttribute {
        for (i in 0...this.get_count()) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyNormalMatrix(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function transformDirection(m:Matrix4):InterleavedBufferAttribute {
        for (i in 0...this.get_count()) {
            _vector.fromBufferAttribute(this, i);
            _vector.transformDirection(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function getComponent(index:Int, component:Int):Float {
        var value = this.get_array()[index * this.data.stride + this.offset + component];
        if (this.normalized) value = MathUtils.denormalize(value, this.get_array());
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Float):InterleavedBufferAttribute {
        if (this.normalized) value = MathUtils.normalize(value, this.get_array());
        this.data.array[index * this.data.stride + this.offset + component] = value;
        return this;
    }

    public function setX(index:Int, x:Float):InterleavedBufferAttribute {
        if (this.normalized) x = MathUtils.normalize(x, this.get_array());
        this.data.array[index * this.data.stride + this.offset] = x;
        return this;
    }

    public function setY(index:Int, y:Float):InterleavedBufferAttribute {
        if (this.normalized) y = MathUtils.normalize(y, this.get_array());
        this.data.array[index * this.data.stride + this.offset + 1] = y;
        return this;
    }

    public function setZ(index:Int, z:Float):InterleavedBufferAttribute {
        if (this.normalized) z = MathUtils.normalize(z, this.get_array());
        this.data.array[index * this.data.stride + this.offset + 2] = z;
        return this;
    }

    public function setW(index:Int, w:Float):InterleavedBufferAttribute {
        if (this.normalized) w = MathUtils.normalize(w, this.get_array());
        this.data.array[index * this.data.stride + this.offset + 3] = w;
        return this;
    }

    public function getX(index:Int):Float {
        var x = this.data.array[index * this.data.stride + this.offset];
        if (this.normalized) x = MathUtils.denormalize(x, this.get_array());
        return x;
    }

    public function getY(index:Int):Float {
        var y = this.data.array[index * this.data.stride + this.offset + 1];
        if (this.normalized) y = MathUtils.denormalize(y, this.get_array());
        return y;
    }

    public function getZ(index:Int):Float {
        var z = this.data.array[index * this.data.stride + this.offset + 2];
        if (this.normalized) z = MathUtils.denormalize(z, this.get_array());
        return z;
    }

    public function getW(index:Int):Float {
        var w = this.data.array[index * this.data.stride + this.offset + 3];
        if (this.normalized) w = MathUtils.denormalize(w, this.get_array());
        return w;
    }

    public function setXY(index:Int, x:Float, y:Float):InterleavedBufferAttribute {
        index = index * this.data.stride + this.offset;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.get_array());
            y = MathUtils.normalize(y, this.get_array());
        }
        this.data.array[index] = x;
        this.data.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):InterleavedBufferAttribute {
        index = index * this.data.stride + this.offset;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.get_array());
            y = MathUtils.normalize(y, this.get_array());
            z = MathUtils.normalize(z, this.get_array());
        }
        this.data.array[index] = x;
        this.data.array[index + 1] = y;
        this.data.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):InterleavedBufferAttribute {
        index = index * this.data.stride + this.offset;
        if (this.normalized) {
            x = MathUtils.normalize(x, this.get_array());
            y = MathUtils.normalize(y, this.get_array());
            z = MathUtils.normalize(z, this.get_array());
            w = MathUtils.normalize(w, this.get_array());
        }
        this.data.array[index] = x;
        this.data.array[index + 1] = y;
        this.data.array[index + 2] = z;
        this.data.array[index + 3] = w;
        return this;
    }

    public function clone(data:Dynamic):BufferAttribute {
        if (data == null) {
            trace('THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.');
            var array = [];
            for (i in 0...this.get_count()) {
                var index = i * this.data.stride + this.offset;
                for (j in 0...this.itemSize) {
                    array.push(this.data.array[index + j]);
                }
            }
            return new BufferAttribute(new Array<Float>(array), this.itemSize, this.normalized);
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

    public function toJSON(data:Dynamic):Dynamic {
        if (data == null) {
            trace('THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.');
            var array = [];
            for (i in 0...this.get_count()) {
                var index = i * this.data.stride + this.offset;
                for (j in 0...this.itemSize) {
                    array.push(this.data.array[index + j]);
                }
            }
            return {
                itemSize: this.itemSize,
                type: Type.getClassName(Type.getClass(this.get_array())),
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