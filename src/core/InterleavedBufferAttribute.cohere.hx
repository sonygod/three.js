package math;

class Vector3 {
    public function new() {
        // ...
    }
    public function fromBufferAttribute(attribute:InterleavedBufferAttribute, index:Int):Void {
        // ...
    }
    public function applyMatrix4(matrix:Matrix4):Void {
        // ...
    }
    public function applyNormalMatrix(matrix:Matrix4):Void {
        // ...
    }
    public function transformDirection(matrix:Matrix4):Void {
        // ...
    }
}

class BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
        // ...
    }
}

class InterleavedBufferAttribute {
    public var isInterleavedBufferAttribute:Bool;
    public var name:String;
    public var data:InterleavedBuffer;
    public var itemSize:Int;
    public var offset:Int;
    public var normalized:Bool;

    public function new(interleavedBuffer:InterleavedBuffer, itemSize:Int, offset:Int, normalized:Bool) {
        this.isInterleavedBufferAttribute = true;
        this.name = "";
        this.data = interleavedBuffer;
        this.itemSize = itemSize;
        this.offset = offset;
        this.normalized = normalized;
    }

    public function get_count():Int {
        return data.count;
    }

    public function get_array():Array<Float> {
        return data.array;
    }

    public function set_needsUpdate(value:Bool):Void {
        data.needsUpdate = value;
    }

    public function applyMatrix4(m:Matrix4):InterleavedBufferAttribute {
        var _vector:Vector3 = new Vector3();
        for (i in 0...data.count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyMatrix4(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function applyNormalMatrix(m:Matrix4):InterleavedBufferAttribute {
        var _vector:Vector3 = new Vector3();
        for (i in 0...count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyNormalMatrix(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function transformDirection(m:Matrix4):InterleavedBufferAttribute {
        var _vector:Vector3 = new Vector3();
        for (i in 0...count) {
            _vector.fromBufferAttribute(this, i);
            _vector.transformDirection(m);
            this.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function getComponent(index:Int, component:Int):Float {
        var value:Float = array[index * data.stride + offset + component];
        if (normalized) value = denormalize(value, array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Float):InterleavedBufferAttribute {
        if (normalized) value = normalize(value, array);
        data.array[index * data.stride + offset + component] = value;
        return this;
    }

    public function setX(index:Int, x:Float):InterleavedBufferAttribute {
        if (normalized) x = normalize(x, array);
        data.array[index * data.stride + offset] = x;
        return this;
    }

    public function setY(index:Int, y:Float):InterleavedBufferAttribute {
        if (normalized) y = normalize(y, array);
        data.array[index * data.stride + offset + 1] = y;
        return this;
    }

    public function setZ(index:Int, z:Float):InterleavedBufferAttribute {
        if (normalized) z = normalize(z, array);
        data.array[index * data.stride + offset + 2] = z;
        return this;
    }

    public function setW(index:Int, w:Float):InterleavedBufferAttribute {
        if (normalized) w = normalize(w, array);
        data.array[index * data.stride + offset + 3] = w;
        return this;
    }

    public function getX(index:Int):Float {
        var x:Float = data.array[index * data.stride + offset];
        if (normalized) x = denormalize(x, array);
        return x;
    }

    public function getY(index:Int):Float {
        var y:Float = data.array[index * data.stride + offset + 1];
        if (normalized) y = denormalize(y, array);
        return y;
    }

    public function getZ(index:Int):Float {
        var z:Float = data.array[index * data.stride + offset + 2];
        if (normalized) z = denormalize(z, array);
        return z;
    }

    public function getW(index:Int):Float {
        var w:Float = data.array[index * data.stride + offset + 3];
        if (normalized) w = denormalize(w, array);
        return w;
    }

    public function setXY(index:Int, x:Float, y:Float):InterleavedBufferAttribute {
        var index:Int = index * data.stride + offset;
        if (normalized) {
            x = normalize(x, array);
            y = normalize(y, array);
        }
        data.array[index + 0] = x;
        data.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):InterleavedBufferAttribute {
        var index:Int = index * data.stride + offset;
        if (normalized) {
            x = normalize(x, array);
            y = normalize(y, array);
            z = normalize(z, array);
        }
        data.array[index + 0] = x;
        data.array[index + 1] = y;
        data.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):InterleavedBufferAttribute {
        var index:Int = index * data.stride + offset;
        if (normalized) {
            x = normalize(x, array);
            y = normalize(y, array);
            z = normalize(z, array);
            w = normalize(w, array);
        }
        data.array[index + 0] = x;
        data.array[index + 1] = y;
        data.array[index + 2] = z;
        data.array[index + 3] = w;
        return this;
    }

    public function clone(data:InterleavedBufferData):BufferAttribute {
        if (data == null) {
            trace("InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");
            var array:Array<Float> = [];
            for (i in 0...count) {
                var index:Int = i * data.stride + offset;
                for (j in 0...itemSize) {
                    array.push(data.array[index + j]);
                }
            }
            return new BufferAttribute(new Array<Float>(array), itemSize, normalized);
        } else {
            if (data.interleavedBuffers == null) {
                data.interleavedBuffers = { };
            }
            if (!data.interleavedBuffers.hasOwnProperty(data.uuid)) {
                data.interleavedBuffers[data.uuid] = data.clone(data);
            }
            return new InterleavedBufferAttribute(data.interleavedBuffers[data.uuid], itemSize, offset, normalized);
        }
    }

    public function toJSON(data:InterleavedBufferData):Dynamic {
        if (data == null) {
            trace("InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");
            var array:Array<Float> = [];
            for (i in 0...count) {
                var index:Int = i * data.stride + offset;
                for (j in 0...itemSize) {
                    array.push(data.array[index + j]);
                }
            }
            // de-interleave data and save it as an ordinary buffer attribute for now
            return {
                itemSize: itemSize,
                type: Type.getClassName(array),
                array: array,
                normalized: normalized
            };
        } else {
            // save as true interleaved attribute
            if (data.interleavedBuffers == null) {
                data.interleavedBuffers = { };
            }
            if (!data.interleavedBuffers.hasOwnProperty(data.uuid)) {
                data.interleavedBuffers[data.uuid] = data.toJSON(data);
            }
            return {
                isInterleavedBufferAttribute: true,
                itemSize: itemSize,
                data: data.uuid,
                offset: offset,
                normalized: normalized
            };
        }
    }
}