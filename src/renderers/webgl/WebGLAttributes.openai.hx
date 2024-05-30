package three.js.src.renderers.webgl;

import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;

class WebGLAttributes {
	// Note: WeakMap is not available in Haxe, so we use a Map instead
	private var buffers:Map<Attribute, BufferData>;

	public function new(gl:RenderingContext) {
		buffers = new Map();
	}

	private function createBuffer(attribute:Attribute, bufferType:Int):BufferData {
		var array:Array Like = attribute.array;
		var usage:Int = attribute.usage;
		var size:Int = array.byteLength;

		var buffer:Buffer = gl.createBuffer();
		gl.bindBuffer(bufferType, buffer);
		gl.bufferData(bufferType, array, usage);

		attribute.onUploadCallback();

		var type:Int;
		if (Std.is(array, Array<Float>) || Std.is(array, Float32Array)) {
			type = gl.FLOAT;
		} else if (Std.is(array, Array<Int>) || Std.is(array, Uint16Array)) {
			if (attribute.isFloat16BufferAttribute) {
				type = gl.HALF_FLOAT;
			} else {
				type = gl.UNSIGNED_SHORT;
			}
		} else if (Std.is(array, Array<Int>) || Std.is(array, Int16Array)) {
			type = gl.SHORT;
		} else if (Std.is(array, Array<Int>) || Std.is(array, Uint32Array)) {
			type = gl.UNSIGNED_INT;
		} else if (Std.is(array, Array<Int>) || Std.is(array, Int32Array)) {
			type = gl.INT;
		} else if (Std.is(array, Array<Int>) || Std.is(array, Int8Array)) {
			type = gl.BYTE;
		} else if (Std.is(array, Array<Int>) || Std.is(array, Uint8Array)) {
			type = gl.UNSIGNED_BYTE;
		} else if (Std.is(array, Array<Int>) || Std.is(array, Uint8ClampedArray)) {
			type = gl.UNSIGNED_BYTE;
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

	private function updateBuffer(buffer:Buffer, attribute:Attribute, bufferType:Int):Void {
		var array:Array Like = attribute.array;
		var updateRange:UpdateRange = attribute._updateRange; // @deprecated, r159
		var updateRanges:Array<UpdateRange> = attribute.updateRanges;

		gl.bindBuffer(bufferType, buffer);

		if (updateRange.count == -1 && updateRanges.length == 0) {
			// Not using update ranges
			gl.bufferSubData(bufferType, 0, array);
		}

		if (updateRanges.length != 0) {
			for (i in 0...updateRanges.length) {
				var range:UpdateRange = updateRanges[i];
				gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT, array, range.start, range.count);
			}
			attribute.clearUpdateRanges();
		}

		// @deprecated, r159
		if (updateRange.count != -1) {
			gl.bufferSubData(bufferType, updateRange.offset * array.BYTES_PER_ELEMENT, array, updateRange.offset, updateRange.count);
			updateRange.count = -1; // reset range
		}

		attribute.onUploadCallback();
	}

	public function get(attribute:Attribute):BufferData {
		if (attribute.isInterleavedBufferAttribute) {
			attribute = attribute.data;
		}
		return buffers.get(attribute);
	}

	public function remove(attribute:Attribute):Void {
		if (attribute.isInterleavedBufferAttribute) {
			attribute = attribute.data;
		}
		var data:BufferData = buffers.get(attribute);
		if (data != null) {
			gl.deleteBuffer(data.buffer);
			buffers.remove(attribute);
		}
	}

	public function update(attribute:Attribute, bufferType:Int):Void {
		if (attribute.isGLBufferAttribute) {
			var cached:BufferData = buffers.get(attribute);
			if (cached == null || cached.version < attribute.version) {
				buffers.set(attribute, {
					buffer: attribute.buffer,
					type: attribute.type,
					bytesPerElement: attribute.elementSize,
					version: attribute.version
				});
			}
			return;
		}

		if (attribute.isInterleavedBufferAttribute) {
			attribute = attribute.data;
		}

		var data:BufferData = buffers.get(attribute);

		if (data == null) {
			buffers.set(attribute, createBuffer(attribute, bufferType));
		} else if (data.version < attribute.version) {
			if (data.size != attribute.array.byteLength) {
				throw new Error('THREE.WebGLAttributes: The size of the buffer attribute\'s array buffer does not match the original size. Resizing buffer attributes is not supported.');
			}
			updateBuffer(data.buffer, attribute, bufferType);
			data.version = attribute.version;
		}
	}
}