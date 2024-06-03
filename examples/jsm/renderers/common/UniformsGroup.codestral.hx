import UniformBuffer;
import Constants;

class UniformsGroup extends UniformBuffer {

    public var isUniformsGroup:Bool = true;
    public var uniforms:Array<Dynamic>;

    public function new(name:String) {
        super(name);
        this.uniforms = [];
    }

    public function addUniform(uniform:Dynamic):UniformsGroup {
        this.uniforms.push(uniform);
        return this;
    }

    public function removeUniform(uniform:Dynamic):UniformsGroup {
        var index:Int = this.uniforms.indexOf(uniform);
        if(index != -1) {
            this.uniforms.splice(index, 1);
        }
        return this;
    }

    public function get buffer():Float {
        var buffer:Float = this._buffer;

        if(buffer == null) {
            var byteLength:Int = this.byteLength;
            buffer = new Float(new ArrayBuffer(byteLength));
            this._buffer = buffer;
        }

        return buffer;
    }

    public function get byteLength():Int {
        var offset:Int = 0;

        for(uniform in this.uniforms) {
            var boundary:Int = Std.parseInt(Reflect.field(uniform, "boundary"));
            var itemSize:Int = Std.parseInt(Reflect.field(uniform, "itemSize"));

            var chunkOffset:Int = offset % Constants.GPU_CHUNK_BYTES;
            var remainingSizeInChunk:Int = Constants.GPU_CHUNK_BYTES - chunkOffset;

            if(chunkOffset != 0 && (remainingSizeInChunk - boundary) < 0) {
                offset += (Constants.GPU_CHUNK_BYTES - chunkOffset);
            } else if(chunkOffset % boundary != 0) {
                offset += (chunkOffset % boundary);
            }

            Reflect.setField(uniform, "offset", (offset / this.bytesPerElement));
            offset += (itemSize * this.bytesPerElement);
        }

        return Math.ceil(offset / Constants.GPU_CHUNK_BYTES) * Constants.GPU_CHUNK_BYTES;
    }

    public function update():Bool {
        var updated:Bool = false;

        for(uniform in this.uniforms) {
            if(this.updateByType(uniform) == true) {
                updated = true;
            }
        }

        return updated;
    }

    public function updateByType(uniform:Dynamic):Bool {
        if(Reflect.hasField(uniform, "isFloatUniform")) return this.updateNumber(uniform);
        if(Reflect.hasField(uniform, "isVector2Uniform")) return this.updateVector2(uniform);
        if(Reflect.hasField(uniform, "isVector3Uniform")) return this.updateVector3(uniform);
        if(Reflect.hasField(uniform, "isVector4Uniform")) return this.updateVector4(uniform);
        if(Reflect.hasField(uniform, "isColorUniform")) return this.updateColor(uniform);
        if(Reflect.hasField(uniform, "isMatrix3Uniform")) return this.updateMatrix3(uniform);
        if(Reflect.hasField(uniform, "isMatrix4Uniform")) return this.updateMatrix4(uniform);

        trace("THREE.WebGPUUniformsGroup: Unsupported uniform type.", uniform);
        return false;
    }

    public function updateNumber(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var v:Float = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(a.get(offset) != v) {
            a.set(offset, v);
            updated = true;
        }

        return updated;
    }

    public function updateVector2(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var v = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(a.get(offset + 0) != v.x || a.get(offset + 1) != v.y) {
            a.set(offset + 0, v.x);
            a.set(offset + 1, v.y);

            updated = true;
        }

        return updated;
    }

    public function updateVector3(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var v = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(a.get(offset + 0) != v.x || a.get(offset + 1) != v.y || a.get(offset + 2) != v.z) {
            a.set(offset + 0, v.x);
            a.set(offset + 1, v.y);
            a.set(offset + 2, v.z);

            updated = true;
        }

        return updated;
    }

    public function updateVector4(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var v = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(a.get(offset + 0) != v.x || a.get(offset + 1) != v.y || a.get(offset + 2) != v.z || a.get(offset + 4) != v.w) {
            a.set(offset + 0, v.x);
            a.set(offset + 1, v.y);
            a.set(offset + 2, v.z);
            a.set(offset + 3, v.w);

            updated = true;
        }

        return updated;
    }

    public function updateColor(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var c = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(a.get(offset + 0) != c.r || a.get(offset + 1) != c.g || a.get(offset + 2) != c.b) {
            a.set(offset + 0, c.r);
            a.set(offset + 1, c.g);
            a.set(offset + 2, c.b);

            updated = true;
        }

        return updated;
    }

    public function updateMatrix3(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var e = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(a.get(offset + 0) != e[0] || a.get(offset + 1) != e[1] || a.get(offset + 2) != e[2] ||
           a.get(offset + 4) != e[3] || a.get(offset + 5) != e[4] || a.get(offset + 6) != e[5] ||
           a.get(offset + 8) != e[6] || a.get(offset + 9) != e[7] || a.get(offset + 10) != e[8]) {

            a.set(offset + 0, e[0]);
            a.set(offset + 1, e[1]);
            a.set(offset + 2, e[2]);
            a.set(offset + 4, e[3]);
            a.set(offset + 5, e[4]);
            a.set(offset + 6, e[5]);
            a.set(offset + 8, e[6]);
            a.set(offset + 9, e[7]);
            a.set(offset + 10, e[8]);

            updated = true;
        }

        return updated;
    }

    public function updateMatrix4(uniform:Dynamic):Bool {
        var updated:Bool = false;

        var a:Float = this.buffer;
        var e = Reflect.callMethod(uniform, "getValue");
        var offset:Int = Std.parseInt(Reflect.field(uniform, "offset"));

        if(arraysEqual(a, e, offset) == false) {
            for(i in 0...e.length) {
                a.set(offset + i, e[i]);
            }
            updated = true;
        }

        return updated;
    }

    private function arraysEqual(a:Float, b:Array<Float>, offset:Int):Bool {
        for(i in 0...b.length) {
            if(a.get(offset + i) != b[i]) return false;
        }

        return true;
    }
}