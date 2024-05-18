package three.core;

import three.math.Vector3;
import three.core.BufferAttribute;
import three.math.MathUtils;

class InterleavedBufferAttribute extends BufferAttribute {

    public var isInterleavedBufferAttribute:Bool = true;

    public var name:String = '';

    public var data:Dynamic;
    public var itemSize:Int;
    public var offset:Int;
    public var normalized:Bool;

    public function new(interleavedBuffer:Dynamic, itemSize:Int, offset:Int, normalized:Bool = false) {
        super();

        this.data = interleavedBuffer;
        this.itemSize = itemSize;
        this.offset = offset;
        this.normalized = normalized;
    }

    public var count(get, never):Int;
    private function get_count():Int {
        return data.count;
    }

    public var array(get, never):Dynamic;
    private function get_array():Dynamic {
        return data.array;
    }

    public function set_needsUpdate(value:Bool):Void {
        data.needsUpdate = value;
    }

    public function applyMatrix4(m:Matrix4):InterleavedBufferAttribute {
        for (i in 0...data.count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyMatrix4(m);
            setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function applyNormalMatrix(m:Matrix4):InterleavedBufferAttribute {
        for (i in 0...count) {
            _vector.fromBufferAttribute(this, i);
            _vector.applyNormalMatrix(m);
            setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function transformDirection(m:Matrix4):InterleavedBufferAttribute {
        for (i in 0...count) {
            _vector.fromBufferAttribute(this, i);
            _vector.transformDirection(m);
            setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
        return this;
    }

    public function getComponent(index:Int, component:Int):Float {
        var value:Float = data.array[index * data.stride + offset + component];
        if (normalized) value = MathUtils.denormalize(value, data.array);
        return value;
    }

    public function setComponent(index:Int, component:Int, value:Float):InterleavedBufferAttribute {
        if (normalized) value = MathUtils.normalize(value, data.array);
        data.array[index * data.stride + offset + component] = value;
        return this;
    }

    public function setX(index:Int, x:Float):InterleavedBufferAttribute {
        if (normalized) x = MathUtils.normalize(x, data.array);
        data.array[index * data.stride + offset] = x;
        return this;
    }

    public function setY(index:Int, y:Float):InterleavedBufferAttribute {
        if (normalized) y = MathUtils.normalize(y, data.array);
        data.array[index * data.stride + offset + 1] = y;
        return this;
    }

    public function setZ(index:Int, z:Float):InterleavedBufferAttribute {
        if (normalized) z = MathUtils.normalize(z, data.array);
        data.array[index * data.stride + offset + 2] = z;
        return this;
    }

    public function setW(index:Int, w:Float):InterleavedBufferAttribute {
        if (normalized) w = MathUtils.normalize(w, data.array);
        data.array[index * data.stride + offset + 3] = w;
        return this;
    }

    public function getX(index:Int):Float {
        var x:Float = data.array[index * data.stride + offset];
        if (normalized) x = MathUtils.denormalize(x, data.array);
        return x;
    }

    public function getY(index:Int):Float {
        var y:Float = data.array[index * data.stride + offset + 1];
        if (normalized) y = MathUtils.denormalize(y, data.array);
        return y;
    }

    public function getZ(index:Int):Float {
        var z:Float = data.array[index * data.stride + offset + 2];
        if (normalized) z = MathUtils.denormalize(z, data.array);
        return z;
    }

    public function getW(index:Int):Float {
        var w:Float = data.array[index * data.stride + offset + 3];
        if (normalized) w = MathUtils.denormalize(w, data.array);
        return w;
    }

    public function setXY(index:Int, x:Float, y:Float):InterleavedBufferAttribute {
        index *= data.stride + offset;
        if (normalized) {
            x = MathUtils.normalize(x, data.array);
            y = MathUtils.normalize(y, data.array);
        }
        data.array[index + 0] = x;
        data.array[index + 1] = y;
        return this;
    }

    public function setXYZ(index:Int, x:Float, y:Float, z:Float):InterleavedBufferAttribute {
        index *= data.stride + offset;
        if (normalized) {
            x = MathUtils.normalize(x, data.array);
            y = MathUtils.normalize(y, data.array);
            z = MathUtils.normalize(z, data.array);
        }
        data.array[index + 0] = x;
        data.array[index + 1] = y;
        data.array[index + 2] = z;
        return this;
    }

    public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):InterleavedBufferAttribute {
        index *= data.stride + offset;
        if (normalized) {
            x = MathUtils.normalize(x, data.array);
            y = MathUtils.normalize(y, data.array);
            z = MathUtils.normalize(z, data.array);
            w = MathUtils.normalize(w, data.array);
        }
        data.array[index + 0] = x;
        data.array[index + 1] = y;
        data.array[index + 2] = z;
        data.array[index + 3] = w;
        return this;
    }

    public function clone(data:Dynamic = null):InterleavedBufferAttribute {
        if (data == null) {
            trace('THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.');
            var array:Array<Float> = [];
            for (i in 0...count) {
                var index:Int = i * data.stride + offset;
                for (j in 0...itemSize) {
                    array.push(data.array[index + j]);
                }
            }
            return new BufferAttribute(new data.array.constructor(array), itemSize, normalized);
        } else {
            if (data.interleavedBuffers == null) {
                data.interleavedBuffers = {};
            }
            if (data.interleavedBuffers[data.uuid] == null) {
                data.interleavedBuffers[data.uuid] = data.clone(data);
            }
            return new InterleavedBufferAttribute(data.interleavedBuffers[data.uuid], itemSize, offset, normalized);
        }
    }

    public function toJSON(data:Dynamic = null):Dynamic {
        if (data == null) {
            trace('THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.');
            var array:Array<Float> = [];
            for (i in 0...count) {
                var index:Int = i * data.stride + offset;
                for (j in 0...itemSize) {
                    array.push(data.array[index + j]);
                }
            }
            return {
                itemSize: itemSize,
                type: data.array.constructor.name,
                array: array,
                normalized: normalized
            };
        } else {
            if (data.interleavedBuffers == null) {
                data.interleavedBuffers = {};
            }
            if (data.interleavedBuffers[data.uuid] == null) {
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

static var _vector:Vector3 = new Vector3();