import haxe.io.Bytes;
import three.extras.BufferAttribute;
import three.extras.InterleavedBufferAttribute;
import three.renderers.WebGLRenderer;

class WebGLAttributes {

	private var _gl:WebGLRenderer;
	private var _buffers:Map<BufferAttribute, { buffer:haxe.io.Bytes; type:Int; bytesPerElement:Int; version:Int; size:Int; }>;

	public function new(gl:WebGLRenderer) {
		this._gl = gl;
		this._buffers = new Map();
	}

	private function _createBuffer(attribute:BufferAttribute, bufferType:Int):{ buffer:haxe.io.Bytes; type:Int; bytesPerElement:Int; version:Int; size:Int; } {
		var array = attribute.array;
		var usage = attribute.usage;
		var size = array.byteLength;

		var buffer = _gl.createBuffer();
		_gl.bindBuffer(bufferType, buffer);
		_gl.bufferData(bufferType, array, usage);

		attribute.onUploadCallback();

		var type:Int;

		if (Std.is(array, Float32Array)) {
			type = _gl.FLOAT;
		} else if (Std.is(array, Uint16Array)) {
			if (attribute.isFloat16BufferAttribute) {
				type = _gl.HALF_FLOAT;
			} else {
				type = _gl.UNSIGNED_SHORT;
			}
		} else if (Std.is(array, Int16Array)) {
			type = _gl.SHORT;
		} else if (Std.is(array, Uint32Array)) {
			type = _gl.UNSIGNED_INT;
		} else if (Std.is(array, Int32Array)) {
			type = _gl.INT;
		} else if (Std.is(array, Int8Array)) {
			type = _gl.BYTE;
		} else if (Std.is(array, Uint8Array)) {
			type = _gl.UNSIGNED_BYTE;
		} else if (Std.is(array, Uint8ClampedArray)) {
			type = _gl.UNSIGNED_BYTE;
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

	private function _updateBuffer(buffer:haxe.io.Bytes, attribute:BufferAttribute, bufferType:Int) {
		var array = attribute.array;
		var updateRange = attribute._updateRange; // @deprecated, r159
		var updateRanges = attribute.updateRanges;

		_gl.bindBuffer(bufferType, buffer);

		if (updateRange.count == - 1 && updateRanges.length == 0) {
			// Not using update ranges
			_gl.bufferSubData(bufferType, 0, array);
		}

		if (updateRanges.length != 0) {
			for (i in 0...updateRanges.length) {
				var range = updateRanges[i];

				_gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT,
					array, range.start, range.count);
			}

			attribute.clearUpdateRanges();
		}

		// @deprecated, r159
		if (updateRange.count != - 1) {
			_gl.bufferSubData(bufferType, updateRange.offset * array.BYTES_PER_ELEMENT,
				array, updateRange.offset, updateRange.count);

			updateRange.count = - 1; // reset range
		}

		attribute.onUploadCallback();
	}

	//

	public function get(attribute:BufferAttribute):{ buffer:haxe.io.Bytes; type:Int; bytesPerElement:Int; version:Int; size:Int; } {
		if (Std.is(attribute, InterleavedBufferAttribute)) {
			attribute = attribute.data;
		}

		return _buffers.get(attribute);
	}

	public function remove(attribute:BufferAttribute) {
		if (Std.is(attribute, InterleavedBufferAttribute)) {
			attribute = attribute.data;
		}

		var data = _buffers.get(attribute);

		if (data != null) {
			_gl.deleteBuffer(data.buffer);
			_buffers.remove(attribute);
		}
	}

	public function update(attribute:BufferAttribute, bufferType:Int) {
		if (Std.is(attribute, BufferAttribute)) {
			var cached = _buffers.get(attribute);

			if (cached == null || cached.version < attribute.version) {
				_buffers.set(attribute, {
					buffer: attribute.buffer,
					type: attribute.type,
					bytesPerElement: attribute.elementSize,
					version: attribute.version
				});
			}

			return;
		}

		if (Std.is(attribute, InterleavedBufferAttribute)) {
			attribute = attribute.data;
		}

		var data = _buffers.get(attribute);

		if (data == null) {
			_buffers.set(attribute, _createBuffer(attribute, bufferType));
		} else if (data.version < attribute.version) {
			if (data.size != attribute.array.byteLength) {
				throw new Error('THREE.WebGLAttributes: The size of the buffer attribute\'s array buffer does not match the original size. Resizing buffer attributes is not supported.');
			}

			_updateBuffer(data.buffer, attribute, bufferType);

			data.version = attribute.version;
		}
	}
}