package three.js.examples.jsm.renderers.common;

import UniformBuffer;

class UniformsGroup extends UniformBuffer {
    public var isUniformsGroup:Bool = true;

    public var uniforms:Array<Dynamic> = [];

    public function new(name:String) {
        super(name);
    }

    public function addUniform(uniform:Dynamic):UniformsGroup {
        uniforms.push(uniform);
        return this;
    }

    public function removeUniform(uniform:Dynamic):UniformsGroup {
        var index:Int = Lambda.indexOf(uniforms, uniform);
        if (index != -1) {
            uniforms.splice(index, 1);
        }
        return this;
    }

    public var buffer:get {
        var buffer:Float32Array = _buffer;
        if (buffer == null) {
            var byteLength:Int = byteLength;
            buffer = new Float32Array(new ArrayBuffer(byteLength));
            _buffer = buffer;
        }
        return buffer;
    }

    public var byteLength(get, never):Int;

    private function get_byteLength():Int {
        var offset:Int = 0; // global buffer offset in bytes
        for (i in 0...uniforms.length) {
            var uniform:Dynamic = uniforms[i];
            var boundary:Int = uniform.boundary;
            var itemSize:Int = uniform.itemSize;

            // offset within a single chunk in bytes
            var chunkOffset:Int = offset % GPU_CHUNK_BYTES;
            var remainingSizeInChunk:Int = GPU_CHUNK_BYTES - chunkOffset;

            // conformance tests
            if (chunkOffset != 0 && (remainingSizeInChunk - boundary) < 0) {
                // check for chunk overflow
                offset += (GPU_CHUNK_BYTES - chunkOffset);
            } else if (chunkOffset % boundary != 0) {
                // check for correct alignment
                offset += (chunkOffset % boundary);
            }

            uniform.offset = offset / bytesPerElement;

            offset += itemSize * bytesPerElement;
        }
        return Math.ceil(offset / GPU_CHUNK_BYTES) * GPU_CHUNK_BYTES;
    }

    public function update():Bool {
        var updated:Bool = false;
        for (uniform in uniforms) {
            if (updateByType(uniform)) {
                updated = true;
            }
        }
        return updated;
    }

    private function updateByType(uniform:Dynamic):Bool {
        if (uniform.isFloatUniform) return updateNumber(uniform);
        if (uniform.isVector2Uniform) return updateVector2(uniform);
        if (uniform.isVector3Uniform) return updateVector3(uniform);
        if (uniform.isVector4Uniform) return updateVector4(uniform);
        if (uniform.isColorUniform) return updateColor(uniform);
        if (uniform.isMatrix3Uniform) return updateMatrix3(uniform);
        if (uniform.isMatrix4Uniform) return updateMatrix4(uniform);

        trace('THREE.WebGPUUniformsGroup: Unsupported uniform type.', uniform);
        return false;
    }

    private function updateNumber(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var v:Float = uniform.getValue();
        var offset:Int = uniform.offset;

        if (a[offset] != v) {
            a[offset] = v;
            updated = true;
        }
        return updated;
    }

    private function updateVector2(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var v:Vector2 = uniform.getValue();
        var offset:Int = uniform.offset;

        if (a[offset + 0] != v.x || a[offset + 1] != v.y) {
            a[offset + 0] = v.x;
            a[offset + 1] = v.y;
            updated = true;
        }
        return updated;
    }

    private function updateVector3(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var v:Vector3 = uniform.getValue();
        var offset:Int = uniform.offset;

        if (a[offset + 0] != v.x || a[offset + 1] != v.y || a[offset + 2] != v.z) {
            a[offset + 0] = v.x;
            a[offset + 1] = v.y;
            a[offset + 2] = v.z;
            updated = true;
        }
        return updated;
    }

    private function updateVector4(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var v:Vector4 = uniform.getValue();
        var offset:Int = uniform.offset;

        if (a[offset + 0] != v.x || a[offset + 1] != v.y || a[offset + 2] != v.z || a[offset + 3] != v.w) {
            a[offset + 0] = v.x;
            a[offset + 1] = v.y;
            a[offset + 2] = v.z;
            a[offset + 3] = v.w;
            updated = true;
        }
        return updated;
    }

    private function updateColor(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var c:Color = uniform.getValue();
        var offset:Int = uniform.offset;

        if (a[offset + 0] != c.r || a[offset + 1] != c.g || a[offset + 2] != c.b) {
            a[offset + 0] = c.r;
            a[offset + 1] = c.g;
            a[offset + 2] = c.b;
            updated = true;
        }
        return updated;
    }

    private function updateMatrix3(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var e:Array<Float> = uniform.getValue().elements;
        var offset:Int = uniform.offset;

        if (a[offset + 0] != e[0] || a[offset + 1] != e[1] || a[offset + 2] != e[2] ||
            a[offset + 4] != e[3] || a[offset + 5] != e[4] || a[offset + 6] != e[5] ||
            a[offset + 8] != e[6] || a[offset + 9] != e[7] || a[offset + 10] != e[8]) {

            a[offset + 0] = e[0];
            a[offset + 1] = e[1];
            a[offset + 2] = e[2];
            a[offset + 4] = e[3];
            a[offset + 5] = e[4];
            a[offset + 6] = e[5];
            a[offset + 8] = e[6];
            a[offset + 9] = e[7];
            a[offset + 10] = e[8];

            updated = true;
        }
        return updated;
    }

    private function updateMatrix4(uniform:Dynamic):Bool {
        var updated:Bool = false;
        var a:Float32Array = buffer;
        var e:Array<Float> = uniform.getValue().elements;
        var offset:Int = uniform.offset;

        if (!arraysEqual(a, e, offset)) {
            a.set(e, offset);
            updated = true;
        }
        return updated;
    }

    private function arraysEqual(a:Float32Array, b:Array<Float>, offset:Int):Bool {
        for (i in 0...b.length) {
            if (a[offset + i] != b[i]) return false;
        }
        return true;
    }
}