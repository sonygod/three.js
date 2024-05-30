import js.Browser.WebGL.*;

class DualAttributeData {
    var buffers:Array<WebGLBuffer>;
    var type:Int;
    var bufferType:Int;
    var pbo:WebGLBuffer;
    var byteLength:Int;
    var bytesPerElement:Int;
    var version:Int;
    var isInteger:Bool;
    var activeBufferIndex:Int;
    var baseId:Int;

    public function new(attributeData:Dynamic, dualBuffer:WebGLBuffer) {
        buffers = [attributeData.bufferGPU, dualBuffer];
        type = attributeData.type;
        bufferType = attributeData.bufferType;
        pbo = attributeData.pbo;
        byteLength = attributeData.byteLength;
        bytesPerElement = attributeData.BYTES_PER_ELEMENT;
        version = attributeData.version;
        isInteger = attributeData.isInteger;
        activeBufferIndex = 0;
        baseId = attributeData.id;
    }

    public function get id():Int {
        return baseId | activeBufferIndex;
    }

    public function get bufferGPU():WebGLBuffer {
        return buffers[activeBufferIndex];
    }

    public function get transformBuffer():WebGLBuffer {
        return buffers[activeBufferIndex ^ 1];
    }

    public function switchBuffers() {
        activeBufferIndex ^= 1;
    }
}

class WebGLAttributeUtils {
    var backend:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
    }

    public function createAttribute(attribute:Dynamic, bufferType:Int) {
        var gl = backend.gl;
        var array = attribute.array;
        var usage = if (attribute.usage != null) attribute.usage else gl.STATIC_DRAW;

        var bufferAttribute = if (attribute.isInterleavedBufferAttribute) attribute.data else attribute;
        var bufferData = backend.get(bufferAttribute);

        var bufferGPU = bufferData.bufferGPU;
        if (bufferGPU == null) {
            bufferGPU = _createBuffer(gl, bufferType, array, usage);

            bufferData.bufferGPU = bufferGPU;
            bufferData.bufferType = bufferType;
            bufferData.version = bufferAttribute.version;
        }

        //attribute.onUploadCallback();

        var type:Int;
        if (js.Boot.instanceOf(array, Float32Array)) {
            type = gl.FLOAT;
        } else if (js.Boot.instanceOf(array, Uint16Array)) {
            if (attribute.isFloat16BufferAttribute) {
                type = gl.HALF_FLOAT;
            } else {
                type = gl.UNSIGNED_SHORT;
            }
        } else if (js.Boot.instanceOf(array, Int16Array)) {
            type = gl.SHORT;
        } else if (js.Boot.instanceOf(array, Uint32Array)) {
            type = gl.UNSIGNED_INT;
        } else if (js.Boot.instanceOf(array, Int32Array)) {
            type = gl.INT;
        } else if (js.Boot.instanceOf(array, Int8Array)) {
            type = gl.BYTE;
        } else if (js.Boot.instanceOf(array, Uint8Array)) {
            type = gl.UNSIGNED_BYTE;
        } else if (js.Boot.instanceOf(array, Uint8ClampedArray)) {
            type = gl.UNSIGNED_BYTE;
        } else {
            throw haxe.Exception.thrown("THREE.WebGLBackend: Unsupported buffer data format: " + Std.string(array));
        }

        var attributeData = {
            bufferGPU: bufferGPU,
            bufferType: bufferType,
            type: type,
            byteLength: array.byteLength,
            bytesPerElement: array.BYTES_PER_ELEMENT,
            version: attribute.version,
            pbo: attribute.pbo,
            isInteger: type == gl.INT || type == gl.UNSIGNED_INT || type == gl.UNSIGNED_SHORT || attribute.gpuType == IntType.Int,
            id: _id++
        };

        if (attribute.isStorageBufferAttribute || attribute.isStorageInstancedBufferAttribute) {
            // create buffer for tranform feedback use
            var bufferGPUDual = _createBuffer(gl, bufferType, array, usage);
            attributeData = new DualAttributeData(attributeData, bufferGPUDual);
        }

        backend.set(attribute, attributeData);
    }

    public function updateAttribute(attribute:Dynamic) {
        var backend = this.backend;
        var gl = backend.gl;

        var array = attribute.array;
        var bufferAttribute = if (attribute.isInterleavedBufferAttribute) attribute.data else attribute;
        var bufferData = backend.get(bufferAttribute);
        var bufferType = bufferData.bufferType;
        var updateRanges = if (attribute.isInterleavedBufferAttribute) attribute.data.updateRanges else attribute.updateRanges;

        gl.bindBuffer(bufferType, bufferData.bufferGPU);

        if (updateRanges.length == 0) {
            // Not using update ranges
            gl.bufferSubData(bufferType, 0, array);
        } else {
            var i = 0;
            while (i < updateRanges.length) {
                var range = updateRanges[i];
                gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT, array, range.start, range.count);
                i++;
            }

            bufferAttribute.clearUpdateRanges();
        }

        gl.bindBuffer(bufferType, null);

        bufferData.version = bufferAttribute.version;
    }

    public function destroyAttribute(attribute:Dynamic) {
        var backend = this.backend;
        var gl = backend.gl;

        if (attribute.isInterleavedBufferAttribute) {
            backend.delete(attribute.data);
        }

        var attributeData = backend.get(attribute);

        gl.deleteBuffer(attributeData.bufferGPU);

        backend.delete(attribute);
    }

    public async function getArrayBufferAsync(attribute:Dynamic):Async<ArrayBuffer> {
        var backend = this.backend;
        var gl = backend.gl;

        var bufferAttribute = if (attribute.isInterleavedBufferAttribute) attribute.data else attribute;
        var bufferGPU = backend.get(bufferAttribute).bufferGPU;

        var array = attribute.array;
        var byteLength = array.byteLength;

        gl.bindBuffer(gl.COPY_READ_BUFFER, bufferGPU);

        var writeBuffer = gl.createBuffer();

        gl.bindBuffer(gl.COPY_WRITE_BUFFER, writeBuffer);
        gl.bufferData(gl.COPY_WRITE_BUFFER, byteLength, gl.STREAM_READ);

        gl.copyBufferSubData(gl.COPY_READ_BUFFER, gl.COPY_WRITE_BUFFER, 0, 0, byteLength);

        await backend.utils._clientWaitAsync();

        var dstBuffer = new array.constructor(array.length);

        gl.getBufferSubData(gl.COPY_WRITE_BUFFER, 0, dstBuffer);

        gl.deleteBuffer(writeBuffer);

        return dstBuffer.buffer;
    }

    function _createBuffer(gl:WebGLRenderingContext, bufferType:Int, array:Dynamic, usage:Int):WebGLBuffer {
        var bufferGPU = gl.createBuffer();

        gl.bindBuffer(bufferType, bufferGPU);
        gl.bufferData(bufferType, array, usage);
        gl.bindBuffer(bufferType, null);

        return bufferGPU;
    }
}

var _id:Int = 0;