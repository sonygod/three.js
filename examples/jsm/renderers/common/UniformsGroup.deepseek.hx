import UniformBuffer from './UniformBuffer.hx';
import { GPU_CHUNK_BYTES } from './Constants.hx';

class UniformsGroup extends UniformBuffer {

	public function new(name:String) {
		super(name);
		this.isUniformsGroup = true;
		this.uniforms = [];
	}

	public function addUniform(uniform:Dynamic):UniformsGroup {
		this.uniforms.push(uniform);
		return this;
	}

	public function removeUniform(uniform:Dynamic):UniformsGroup {
		var index = this.uniforms.indexOf(uniform);
		if (index != -1) {
			this.uniforms.splice(index, 1);
		}
		return this;
	}

	public function get buffer():Float32Array {
		var buffer = this._buffer;
		if (buffer == null) {
			var byteLength = this.byteLength;
			buffer = new Float32Array(new ArrayBuffer(byteLength));
			this._buffer = buffer;
		}
		return buffer;
	}

	public function get byteLength():Int {
		var offset = 0;
		for (i in 0...this.uniforms.length) {
			var uniform = this.uniforms[i];
			var boundary = uniform.boundary;
			var itemSize = uniform.itemSize;
			var chunkOffset = offset % GPU_CHUNK_BYTES;
			var remainingSizeInChunk = GPU_CHUNK_BYTES - chunkOffset;
			if (chunkOffset != 0 && (remainingSizeInChunk - boundary) < 0) {
				offset += (GPU_CHUNK_BYTES - chunkOffset);
			} else if (chunkOffset % boundary != 0) {
				offset += (chunkOffset % boundary);
			}
			uniform.offset = (offset / this.bytesPerElement);
			offset += (itemSize * this.bytesPerElement);
		}
		return Math.ceil(offset / GPU_CHUNK_BYTES) * GPU_CHUNK_BYTES;
	}

	public function update():Bool {
		var updated = false;
		for (uniform in this.uniforms) {
			if (this.updateByType(uniform) == true) {
				updated = true;
			}
		}
		return updated;
	}

	public function updateByType(uniform:Dynamic):Bool {
		if (uniform.isFloatUniform) return this.updateNumber(uniform);
		if (uniform.isVector2Uniform) return this.updateVector2(uniform);
		if (uniform.isVector3Uniform) return this.updateVector3(uniform);
		if (uniform.isVector4Uniform) return this.updateVector4(uniform);
		if (uniform.isColorUniform) return this.updateColor(uniform);
		if (uniform.isMatrix3Uniform) return this.updateMatrix3(uniform);
		if (uniform.isMatrix4Uniform) return this.updateMatrix4(uniform);
		trace('THREE.WebGPUUniformsGroup: Unsupported uniform type.', uniform);
		return false;
	}

	public function updateNumber(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var v = uniform.getValue();
		var offset = uniform.offset;
		if (a[offset] != v) {
			a[offset] = v;
			updated = true;
		}
		return updated;
	}

	public function updateVector2(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var v = uniform.getValue();
		var offset = uniform.offset;
		if (a[offset + 0] != v.x || a[offset + 1] != v.y) {
			a[offset + 0] = v.x;
			a[offset + 1] = v.y;
			updated = true;
		}
		return updated;
	}

	public function updateVector3(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var v = uniform.getValue();
		var offset = uniform.offset;
		if (a[offset + 0] != v.x || a[offset + 1] != v.y || a[offset + 2] != v.z) {
			a[offset + 0] = v.x;
			a[offset + 1] = v.y;
			a[offset + 2] = v.z;
			updated = true;
		}
		return updated;
	}

	public function updateVector4(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var v = uniform.getValue();
		var offset = uniform.offset;
		if (a[offset + 0] != v.x || a[offset + 1] != v.y || a[offset + 2] != v.z || a[offset + 4] != v.w) {
			a[offset + 0] = v.x;
			a[offset + 1] = v.y;
			a[offset + 2] = v.z;
			a[offset + 3] = v.w;
			updated = true;
		}
		return updated;
	}

	public function updateColor(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var c = uniform.getValue();
		var offset = uniform.offset;
		if (a[offset + 0] != c.r || a[offset + 1] != c.g || a[offset + 2] != c.b) {
			a[offset + 0] = c.r;
			a[offset + 1] = c.g;
			a[offset + 2] = c.b;
			updated = true;
		}
		return updated;
	}

	public function updateMatrix3(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var e = uniform.getValue().elements;
		var offset = uniform.offset;
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

	public function updateMatrix4(uniform:Dynamic):Bool {
		var updated = false;
		var a = this.buffer;
		var e = uniform.getValue().elements;
		var offset = uniform.offset;
		if (!arraysEqual(a, e, offset)) {
			a.set(e, offset);
			updated = true;
		}
		return updated;
	}

	public static function arraysEqual(a:Float32Array, b:Float32Array, offset:Int):Bool {
		for (i in 0...b.length) {
			if (a[offset + i] != b[i]) return false;
		}
		return true;
	}

}