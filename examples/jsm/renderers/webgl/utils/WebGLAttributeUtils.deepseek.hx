import three.IntType;

var _id = 0;

class DualAttributeData {

	public var buffers:Array<Dynamic>;
	public var type:Int;
	public var bufferType:Int;
	public var pbo:Dynamic;
	public var byteLength:Int;
	public var bytesPerElement:Int;
	public var version:Int;
	public var isInteger:Bool;
	public var activeBufferIndex:Int;
	public var baseId:Int;

	public function new(attributeData:Dynamic, dualBuffer:Dynamic) {

		this.buffers = [attributeData.bufferGPU, dualBuffer];
		this.type = attributeData.type;
		this.bufferType = attributeData.bufferType;
		this.pbo = attributeData.pbo;
		this.byteLength = attributeData.byteLength;
		this.bytesPerElement = attributeData.BYTES_PER_ELEMENT;
		this.version = attributeData.version;
		this.isInteger = attributeData.isInteger;
		this.activeBufferIndex = 0;
		this.baseId = attributeData.id;

	}

	public function get_id():String {

		return `${this.baseId}|${this.activeBufferIndex}`;

	}

	public function get_bufferGPU():Dynamic {

		return this.buffers[this.activeBufferIndex];

	}

	public function get_transformBuffer():Dynamic {

		return this.buffers[this.activeBufferIndex ^ 1];

	}

	public function switchBuffers():Void {

		this.activeBufferIndex ^= 1;

	}

}

class WebGLAttributeUtils {

	public var backend:Dynamic;

	public function new(backend:Dynamic) {

		this.backend = backend;

	}

	public function createAttribute(attribute:Dynamic, bufferType:Int):Void {

		var backend = this.backend;
		var gl = backend.gl;

		var array = attribute.array;
		var usage = attribute.usage || gl.STATIC_DRAW;

		var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
		var bufferData = backend.get(bufferAttribute);

		var bufferGPU = bufferData.bufferGPU;

		if (bufferGPU == undefined) {

			bufferGPU = this._createBuffer(gl, bufferType, array, usage);

			bufferData.bufferGPU = bufferGPU;
			bufferData.bufferType = bufferType;
			bufferData.version = bufferAttribute.version;

		}

		//attribute.onUploadCallback();

		var type:Int;

		if (array instanceof Float32Array) {

			type = gl.FLOAT;

		} else if (array instanceof Uint16Array) {

			if (attribute.isFloat16BufferAttribute) {

				type = gl.HALF_FLOAT;

			} else {

				type = gl.UNSIGNED_SHORT;

			}

		} else if (array instanceof Int16Array) {

			type = gl.SHORT;

		} else if (array instanceof Uint32Array) {

			type = gl.UNSIGNED_INT;

		} else if (array instanceof Int32Array) {

			type = gl.INT;

		} else if (array instanceof Int8Array) {

			type = gl.BYTE;

		} else if (array instanceof Uint8Array) {

			type = gl.UNSIGNED_BYTE;

		} else if (array instanceof Uint8ClampedArray) {

			type = gl.UNSIGNED_BYTE;

		} else {

			throw 'THREE.WebGLBackend: Unsupported buffer data format: ' + array;

		}

		var attributeData = {
			bufferGPU:bufferGPU,
			bufferType:bufferType,
			type:type,
			byteLength:array.byteLength,
			bytesPerElement:array.BYTES_PER_ELEMENT,
			version:attribute.version,
			pbo:attribute.pbo,
			isInteger:type == gl.INT || type == gl.UNSIGNED_INT || type == gl.UNSIGNED_SHORT || attribute.gpuType == IntType,
			id:_id++
		};

		if (attribute.isStorageBufferAttribute || attribute.isStorageInstancedBufferAttribute) {

			// create buffer for tranform feedback use
			var bufferGPUDual = this._createBuffer(gl, bufferType, array, usage);
			attributeData = new DualAttributeData(attributeData, bufferGPUDual);

		}

		backend.set(attribute, attributeData);

	}

	public function updateAttribute(attribute:Dynamic):Void {

		var backend = this.backend;
		var gl = backend.gl;

		var array = attribute.array;
		var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
		var bufferData = backend.get(bufferAttribute);
		var bufferType = bufferData.bufferType;
		var updateRanges = attribute.isInterleavedBufferAttribute ? attribute.data.updateRanges : attribute.updateRanges;

		gl.bindBuffer(bufferType, bufferData.bufferGPU);

		if (updateRanges.length == 0) {

			// Not using update ranges

			gl.bufferSubData(bufferType, 0, array);

		} else {

			for (i in updateRanges) {

				var range = updateRanges[i];
				gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT,
					array, range.start, range.count);

			}

			bufferAttribute.clearUpdateRanges();

		}

		gl.bindBuffer(bufferType, null);

		bufferData.version = bufferAttribute.version;

	}

	public function destroyAttribute(attribute:Dynamic):Void {

		var backend = this.backend;
		var gl = backend.gl;

		if (attribute.isInterleavedBufferAttribute) {

			backend.delete(attribute.data);

		}

		var attributeData = backend.get(attribute);

		gl.deleteBuffer(attributeData.bufferGPU);

		backend.delete(attribute);

	}

	public async function getArrayBufferAsync(attribute:Dynamic):Promise<Dynamic> {

		var backend = this.backend;
		var gl = backend.gl;

		var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
		var bufferData = backend.get(bufferAttribute);
		var bufferGPU = bufferData.bufferGPU;

		var array = attribute.array;
		var byteLength = array.byteLength;

		gl.bindBuffer(gl.COPY_READ_BUFFER, bufferGPU);

		var writeBuffer = gl.createBuffer();

		gl.bindBuffer(gl.COPY_WRITE_BUFFER, writeBuffer);
		gl.bufferData(gl.COPY_WRITE_BUFFER, byteLength, gl.STREAM_READ);

		gl.copyBufferSubData(gl.COPY_READ_BUFFER, gl.COPY_WRITE_BUFFER, 0, 0, byteLength);

		await backend.utils._clientWaitAsync();

		var dstBuffer = new attribute.array.constructor(array.length);

		gl.getBufferSubData(gl.COPY_WRITE_BUFFER, 0, dstBuffer);

		gl.deleteBuffer(writeBuffer);

		return dstBuffer.buffer;

	}

	private function _createBuffer(gl:Dynamic, bufferType:Int, array:Dynamic, usage:Int):Dynamic {

		var bufferGPU = gl.createBuffer();

		gl.bindBuffer(bufferType, bufferGPU);
		gl.bufferData(bufferType, array, usage);
		gl.bindBuffer(bufferType, null);

		return bufferGPU;

	}

}

typedef WebGLAttributeUtilsType = {

	var backend:Dynamic;

	function new(backend:Dynamic):Void;

	function createAttribute(attribute:Dynamic, bufferType:Int):Void;

	function updateAttribute(attribute:Dynamic):Void;

	function destroyAttribute(attribute:Dynamic):Void;

	function getArrayBufferAsync(attribute:Dynamic):Promise<Dynamic>;

	private function _createBuffer(gl:Dynamic, bufferType:Int, array:Dynamic, usage:Int):Dynamic;

}

var WebGLAttributeUtils:WebGLAttributeUtilsType = new WebGLAttributeUtils(null);