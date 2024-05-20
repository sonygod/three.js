class WebGLAttributes {

	var buffers:WeakMap<Dynamic, Dynamic>;
	var gl:Dynamic;

	public function new(gl:Dynamic) {
		this.gl = gl;
		this.buffers = new WeakMap();
	}

	function createBuffer(attribute:Dynamic, bufferType:Dynamic):Dynamic {

		var array = attribute.array;
		var usage = attribute.usage;
		var size = array.byteLength;

		var buffer = gl.createBuffer();

		gl.bindBuffer(bufferType, buffer);
		gl.bufferData(bufferType, array, usage);

		attribute.onUploadCallback();

		var type;

		if (array instanceof js.html.Float32Array) {

			type = gl.FLOAT;

		} else if (array instanceof js.html.Uint16Array) {

			if (attribute.isFloat16BufferAttribute) {

				type = gl.HALF_FLOAT;

			} else {

				type = gl.UNSIGNED_SHORT;

			}

		} else if (array instanceof js.html.Int16Array) {

			type = gl.SHORT;

		} else if (array instanceof js.html.Uint32Array) {

			type = gl.UNSIGNED_INT;

		} else if (array instanceof js.html.Int32Array) {

			type = gl.INT;

		} else if (array instanceof js.html.Int8Array) {

			type = gl.BYTE;

		} else if (array instanceof js.html.Uint8Array) {

			type = gl.UNSIGNED_BYTE;

		} else if (array instanceof js.html.Uint8ClampedArray) {

			type = gl.UNSIGNED_BYTE;

		} else {

			throw 'THREE.WebGLAttributes: Unsupported buffer data format: ' + array;

		}

		return {
			buffer: buffer,
			type: type,
			bytesPerElement: array.BYTES_PER_ELEMENT,
			version: attribute.version,
			size: size
		};

	}

	function updateBuffer(buffer:Dynamic, attribute:Dynamic, bufferType:Dynamic):Void {

		var array = attribute.array;
		var updateRange = attribute._updateRange; // @deprecated, r159
		var updateRanges = attribute.updateRanges;

		gl.bindBuffer(bufferType, buffer);

		if (updateRange.count == -1 && updateRanges.length == 0) {

			// Not using update ranges
			gl.bufferSubData(bufferType, 0, array);

		}

		if (updateRanges.length != 0) {

			for (i in 0...updateRanges.length) {

				var range = updateRanges[i];

				gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT,
					array, range.start, range.count);

			}

			attribute.clearUpdateRanges();

		}

		// @deprecated, r159
		if (updateRange.count != -1) {

			gl.bufferSubData(bufferType, updateRange.offset * array.BYTES_PER_ELEMENT,
				array, updateRange.offset, updateRange.count);

			updateRange.count = -1; // reset range

		}

		attribute.onUploadCallback();

	}

	function get(attribute:Dynamic):Dynamic {

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		return buffers.get(attribute);

	}

	function remove(attribute:Dynamic):Void {

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		var data = buffers.get(attribute);

		if (data) {

			gl.deleteBuffer(data.buffer);

			buffers.delete(attribute);

		}

	}

	function update(attribute:Dynamic, bufferType:Dynamic):Void {

		if (attribute.isGLBufferAttribute) {

			var cached = buffers.get(attribute);

			if (!cached || cached.version < attribute.version) {

				buffers.set(attribute, {
					buffer: attribute.buffer,
					type: attribute.type,
					bytesPerElement: attribute.elementSize,
					version: attribute.version
				});

			}

			return;

		}

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		var data = buffers.get(attribute);

		if (data == null) {

			buffers.set(attribute, createBuffer(attribute, bufferType));

		} else if (data.version < attribute.version) {

			if (data.size != attribute.array.byteLength) {

				throw 'THREE.WebGLAttributes: The size of the buffer attribute\'s array buffer does not match the original size. Resizing buffer attributes is not supported.';

			}

			updateBuffer(data.buffer, attribute, bufferType);

			data.version = attribute.version;

		}

	}

}