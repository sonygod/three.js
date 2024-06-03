import haxe.io.Bytes;

class WebGLAttributes {

	private var buffers:WeakMap<Dynamic, {buffer:Dynamic, type:Int, bytesPerElement:Int, version:Int, size:Int}> = new WeakMap();

	public function new(gl:Dynamic) {
		this.gl = gl;
	}

	private var gl:Dynamic;

	private function createBuffer(attribute:Dynamic, bufferType:Int):{buffer:Dynamic, type:Int, bytesPerElement:Int, version:Int, size:Int} {

		var array = attribute.array;
		var usage = attribute.usage;
		var size = array.byteLength;

		var buffer = this.gl.createBuffer();

		this.gl.bindBuffer(bufferType, buffer);
		this.gl.bufferData(bufferType, array, usage);

		attribute.onUploadCallback();

		var type:Int;

		if (Std.is(array, Float32Array)) {

			type = this.gl.FLOAT;

		} else if (Std.is(array, Uint16Array)) {

			if (attribute.isFloat16BufferAttribute) {

				type = this.gl.HALF_FLOAT;

			} else {

				type = this.gl.UNSIGNED_SHORT;

			}

		} else if (Std.is(array, Int16Array)) {

			type = this.gl.SHORT;

		} else if (Std.is(array, Uint32Array)) {

			type = this.gl.UNSIGNED_INT;

		} else if (Std.is(array, Int32Array)) {

			type = this.gl.INT;

		} else if (Std.is(array, Int8Array)) {

			type = this.gl.BYTE;

		} else if (Std.is(array, Uint8Array)) {

			type = this.gl.UNSIGNED_BYTE;

		} else if (Std.is(array, Uint8ClampedArray)) {

			type = this.gl.UNSIGNED_BYTE;

		} else {

			throw new Error('THREE.WebGLAttributes: Unsupported buffer data format: ' + array);

		}

		return {
			buffer: buffer,
			type: type,
			bytesPerElement: array.BYTES_PER_ELEMENT,
			version: attribute.version,
			size: size
		};

	}

	private function updateBuffer(buffer:Dynamic, attribute:Dynamic, bufferType:Int) {

		var array = attribute.array;
		var updateRange = attribute._updateRange; // @deprecated, r159
		var updateRanges = attribute.updateRanges;

		this.gl.bindBuffer(bufferType, buffer);

		if (updateRange.count == -1 && updateRanges.length == 0) {

			// Not using update ranges
			this.gl.bufferSubData(bufferType, 0, array);

		}

		if (updateRanges.length != 0) {

			for (i in 0...updateRanges.length) {

				var range = updateRanges[i];

				this.gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT,
					array, range.start, range.count);

			}

			attribute.clearUpdateRanges();

		}

		// @deprecated, r159
		if (updateRange.count != -1) {

			this.gl.bufferSubData(bufferType, updateRange.offset * array.BYTES_PER_ELEMENT,
				array, updateRange.offset, updateRange.count);

			updateRange.count = -1; // reset range

		}

		attribute.onUploadCallback();

	}

	//

	public function get(attribute:Dynamic):{buffer:Dynamic, type:Int, bytesPerElement:Int, version:Int, size:Int} {

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		return this.buffers.get(attribute);

	}

	public function remove(attribute:Dynamic) {

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		var data = this.buffers.get(attribute);

		if (data != null) {

			this.gl.deleteBuffer(data.buffer);

			this.buffers.delete(attribute);

		}

	}

	public function update(attribute:Dynamic, bufferType:Int) {

		if (attribute.isGLBufferAttribute) {

			var cached = this.buffers.get(attribute);

			if (cached == null || cached.version < attribute.version) {

				this.buffers.set(attribute, {
					buffer: attribute.buffer,
					type: attribute.type,
					bytesPerElement: attribute.elementSize,
					version: attribute.version
				});

			}

			return;

		}

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		var data = this.buffers.get(attribute);

		if (data == null) {

			this.buffers.set(attribute, this.createBuffer(attribute, bufferType));

		} else if (data.version < attribute.version) {

			if (data.size != attribute.array.byteLength) {

				throw new Error('THREE.WebGLAttributes: The size of the buffer attribute\'s array buffer does not match the original size. Resizing buffer attributes is not supported.');

			}

			this.updateBuffer(data.buffer, attribute, bufferType);

			data.version = attribute.version;

		}

	}

}