import js.Browser.WebGLRenderingContext;
import js.html.WebGLBuffer;
import js.ArrayBufferView;

class DualAttributeData {
    public var buffers:Array<WebGLBuffer>;
    public var type:Dynamic;
    public var bufferType:Dynamic;
    public var pbo:Dynamic;
    public var byteLength:Int;
    public var bytesPerElement:Int;
    public var version:Int;
    public var isInteger:Bool;
    public var activeBufferIndex:Int;
    public var baseId:Int;

    public function new(attributeData:Dynamic, dualBuffer:WebGLBuffer) {
        this.buffers = [attributeData.bufferGPU, dualBuffer];
        this.type = attributeData.type;
        this.bufferType = attributeData.bufferType;
        this.pbo = attributeData.pbo;
        this.byteLength = attributeData.byteLength;
        this.bytesPerElement = attributeData.bytesPerElement;
        this.version = attributeData.version;
        this.isInteger = attributeData.isInteger;
        this.activeBufferIndex = 0;
        this.baseId = attributeData.id;
    }

    @:get public function get_id():String {
        return `${this.baseId}|${this.activeBufferIndex}`;
    }

    @:get public function get_bufferGPU():WebGLBuffer {
        return this.buffers[this.activeBufferIndex];
    }

    @:get public function get_transformBuffer():WebGLBuffer {
        return this.buffers[this.activeBufferIndex ^ 1];
    }

    public function switchBuffers():Void {
        this.activeBufferIndex ^= 1;
    }
}

class WebGLAttributeUtils {
    private var backend:Dynamic;
    private var _id:Int = 0;

    public function new(backend:Dynamic) {
        this.backend = backend;
    }

    public function createAttribute(attribute:Dynamic, bufferType:Dynamic):Void {
        var gl:WebGLRenderingContext = this.backend.gl;
        var array:ArrayBufferView<Float> = attribute.array;
        var usage:Dynamic = attribute.usage || gl.STATIC_DRAW;
        var bufferAttribute:Dynamic = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
        var bufferData:Dynamic = this.backend.get(bufferAttribute);
        var bufferGPU:WebGLBuffer = bufferData.bufferGPU;

        if (bufferGPU == null) {
            bufferGPU = this._createBuffer(gl, bufferType, array, usage);
            bufferData.bufferGPU = bufferGPU;
            bufferData.bufferType = bufferType;
            bufferData.version = bufferAttribute.version;
        }

        var type:Dynamic;
        switch (Type.getClass(array)) {
            case Float32Array:
                type = gl.FLOAT;
                break;
            case Uint16Array:
                if (attribute.isFloat16BufferAttribute) {
                    type = gl.HALF_FLOAT;
                } else {
                    type = gl.UNSIGNED_SHORT;
                }
                break;
            case Int16Array:
                type = gl.SHORT;
                break;
            case Uint32Array:
                type = gl.UNSIGNED_INT;
                break;
            case Int32Array:
                type = gl.INT;
                break;
            case Int8Array:
                type = gl.BYTE;
                break;
            case Uint8Array:
                type = gl.UNSIGNED_BYTE;
                break;
            case Uint8ClampedArray:
                type = gl.UNSIGNED_BYTE;
                break;
            default:
                throw new js.Error("THREE.WebGLBackend: Unsupported buffer data format: " + array);
        }

        var attributeData:Dynamic = {
            bufferGPU: bufferGPU,
            bufferType: bufferType,
            type: type,
            byteLength: array.byteLength,
            bytesPerElement: array.BYTES_PER_ELEMENT,
            version: attribute.version,
            pbo: attribute.pbo,
            isInteger: type == gl.INT || type == gl.UNSIGNED_INT || type == gl.UNSIGNED_SHORT || attribute.gpuType == IntType,
            id: this._id++
        };

        if (attribute.isStorageBufferAttribute || attribute.isStorageInstancedBufferAttribute) {
            var bufferGPUDual:WebGLBuffer = this._createBuffer(gl, bufferType, array, usage);
            attributeData = new DualAttributeData(attributeData, bufferGPUDual);
        }

        this.backend.set(attribute, attributeData);
    }

    public function updateAttribute(attribute:Dynamic):Void {
        var gl:WebGLRenderingContext = this.backend.gl;
        var array:ArrayBufferView<Float> = attribute.array;
        var bufferAttribute:Dynamic = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
        var bufferData:Dynamic = this.backend.get(bufferAttribute);
        var bufferType:Dynamic = bufferData.bufferType;
        var updateRanges:Array<Dynamic> = attribute.isInterleavedBufferAttribute ? attribute.data.updateRanges : attribute.updateRanges;

        gl.bindBuffer(bufferType, bufferData.bufferGPU);

        if (updateRanges.length == 0) {
            gl.bufferSubData(bufferType, 0, array);
        } else {
            for (var i:Int in 0...updateRanges.length) {
                var range:Dynamic = updateRanges[i];
                gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT, array, range.start, range.count);
            }
            bufferAttribute.clearUpdateRanges();
        }

        gl.bindBuffer(bufferType, null);
        bufferData.version = bufferAttribute.version;
    }

    public function destroyAttribute(attribute:Dynamic):Void {
        var gl:WebGLRenderingContext = this.backend.gl;

        if (attribute.isInterleavedBufferAttribute) {
            this.backend.delete(attribute.data);
        }

        var attributeData:Dynamic = this.backend.get(attribute);
        gl.deleteBuffer(attributeData.bufferGPU);
        this.backend.delete(attribute);
    }

    public async function getArrayBufferAsync(attribute:Dynamic):Promise<ArrayBuffer> {
        var gl:WebGLRenderingContext = this.backend.gl;
        var bufferAttribute:Dynamic = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
        var bufferGPU:WebGLBuffer = this.backend.get(bufferAttribute).bufferGPU;
        var array:ArrayBufferView<Float> = attribute.array;
        var byteLength:Int = array.byteLength;

        gl.bindBuffer(gl.COPY_READ_BUFFER, bufferGPU);

        var writeBuffer:WebGLBuffer = gl.createBuffer();
        gl.bindBuffer(gl.COPY_WRITE_BUFFER, writeBuffer);
        gl.bufferData(gl.COPY_WRITE_BUFFER, byteLength, gl.STREAM_READ);

        gl.copyBufferSubData(gl.COPY_READ_BUFFER, gl.COPY_WRITE_BUFFER, 0, 0, byteLength);

        await this.backend.utils._clientWaitAsync();

        var dstBuffer:ArrayBufferView<Float> = Type.createEmptyInstance(Type.getClass(array), [array.length]);
        gl.getBufferSubData(gl.COPY_WRITE_BUFFER, 0, dstBuffer);

        gl.deleteBuffer(writeBuffer);

        return dstBuffer.buffer;
    }

    private function _createBuffer(gl:WebGLRenderingContext, bufferType:Dynamic, array:ArrayBufferView<Float>, usage:Dynamic):WebGLBuffer {
        var bufferGPU:WebGLBuffer = gl.createBuffer();

        gl.bindBuffer(bufferType, bufferGPU);
        gl.bufferData(bufferType, array, usage);
        gl.bindBuffer(bufferType, null);

        return bufferGPU;
    }
}