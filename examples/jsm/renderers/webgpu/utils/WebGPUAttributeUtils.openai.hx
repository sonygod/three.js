package three.js.examples.jsm.renderers.webgpu.utils;

import js.html.webgpu.GPU;
import js.html.webgpu.GPUBuffer;
import js.html.webgpu.GPUBufferUsage;
import js.html.webgpu.GPUCmdEncoder;
import js.html.webgpu.GPUCommandBuffer;
import js.html.webgpu.GPUMapMode;
import js.html.webgpu.GPUQueue;
import three.js.Float16BufferAttribute;
import WebGPUConstants;

class WebGPUAttributeUtils {
    private var backend:Dynamic;
    private var device:GPUDevice;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.device = backend.device;
    }

    public function createAttribute(attribute:Dynamic, usage:GPUBufferUsage):Void {
        var bufferAttribute:Dynamic = _getBufferAttribute(attribute);
        var bufferData:Dynamic = backend.get(bufferAttribute);

        var buffer:GPUBuffer = bufferData.buffer;

        if (buffer == null) {
            buffer = device.createBuffer({
                label: bufferAttribute.name,
                size: bufferAttribute.array.byteLength + ((4 - (bufferAttribute.array.byteLength % 4)) % 4), // ensure 4 byte alignment, see #20441
                usage: usage,
                mappedAtCreation: true
            });

            var array:Dynamic = bufferAttribute.array;

            // patch for INT16 and UINT16
            if (!bufferAttribute.normalized && (Std.isOfType(array, Int16Array) || Std.isOfType(array, Uint16Array))) {
                array = new Uint32Array(array.length);
                for (i in 0...array.length) {
                    array[i] = bufferAttribute.array[i];
                }
                bufferAttribute.array = array;
            }

            if ((bufferAttribute.isStorageBufferAttribute || bufferAttribute.isStorageInstancedBufferAttribute) && bufferAttribute.itemSize == 3) {
                array = new array.constructor(bufferAttribute.count * 4);

                for (i in 0...bufferAttribute.count) {
                    array.set(bufferAttribute.array.subarray(i * 3, i * 3 + 3), i * 4);
                }

                // Update BufferAttribute
                bufferAttribute.itemSize = 4;
                bufferAttribute.array = array;
            }

            var datos = buffer.getMappedRange();
            datos.set(array);
            buffer.unmap();

            bufferData.buffer = buffer;
        }
    }

    public function updateAttribute(attribute:Dynamic):Void {
        var bufferAttribute:Dynamic = _getBufferAttribute(attribute);
        var backend:Dynamic = this.backend;
        var device:GPUDevice = backend.device;
        var buffer:GPUBuffer = backend.get(bufferAttribute).buffer;
        var array:Dynamic = bufferAttribute.array;
        var updateRanges:Array<Dynamic> = bufferAttribute.updateRanges;

        if (updateRanges.length == 0) {
            // Not using update ranges
            device.queue.writeBuffer(buffer, 0, array, 0);
        } else {
            for (i in 0...updateRanges.length) {
                var range:Dynamic = updateRanges[i];
                device.queue.writeBuffer(buffer, 0, array, range.start * array.BYTES_PER_ELEMENT, range.count * array.BYTES_PER_ELEMENT);
            }

            bufferAttribute.clearUpdateRanges();
        }
    }

    public function createShaderVertexBuffers(renderObject:Dynamic):Array<Dynamic> {
        var attributes:Array<Dynamic> = renderObject.getAttributes();
        var vertexBuffers:Map<String, Dynamic> = new Map();

        for (slot in 0...attributes.length) {
            var geometryAttribute:Dynamic = attributes[slot];
            var bytesPerElement:Int = geometryAttribute.array.BYTES_PER_ELEMENT;
            var bufferAttribute:Dynamic = _getBufferAttribute(geometryAttribute);

            var vertexBufferLayout:Dynamic = vertexBuffers.get(bufferAttribute);

            if (vertexBufferLayout == null) {
                var arrayStride:Int;
                var stepMode:GPUInputStepMode;

                if (geometryAttribute.isInterleavedBufferAttribute) {
                    arrayStride = geometryAttribute.data.stride * bytesPerElement;
                    stepMode = geometryAttribute.data.isInstancedInterleavedBuffer ? GPUInputStepMode.Instance : GPUInputStepMode.Vertex;
                } else {
                    arrayStride = geometryAttribute.itemSize * bytesPerElement;
                    stepMode = geometryAttribute.isInstancedBufferAttribute ? GPUInputStepMode.Instance : GPUInputStepMode.Vertex;
                }

                // patch for INT16 and UINT16
                if (!geometryAttribute.normalized && (Std.isOfType(geometryAttribute.array, Int16Array) || Std.isOfType(geometryAttribute.array, Uint16Array))) {
                    arrayStride = 4;
                }

                vertexBufferLayout = {
                    arrayStride: arrayStride,
                    attributes: [],
                    stepMode: stepMode
                };

                vertexBuffers.set(bufferAttribute, vertexBufferLayout);
            }

            var offset:Int = geometryAttribute.isInterleavedBufferAttribute ? geometryAttribute.offset * bytesPerElement : 0;
            var format:String = _getVertexFormat(geometryAttribute);

            vertexBufferLayout.attributes.push({
                shaderLocation: slot,
                offset: offset,
                format: format
            });
        }

        return Lambda.array(vertexBuffers.values());
    }

    public function destroyAttribute(attribute:Dynamic):Void {
        var backend:Dynamic = this.backend;
        var data:Dynamic = backend.get(_getBufferAttribute(attribute));
        data.buffer.destroy();
        backend.delete(attribute);
    }

    public function getArrayBufferAsync(attribute:Dynamic):Promise<Dynamic> {
        var backend:Dynamic = this.backend;
        var device:GPUDevice = backend.device;

        var data:Dynamic = backend.get(_getBufferAttribute(attribute));
        var bufferGPU:GPUBuffer = data.buffer;
        var size:Int = bufferGPU.size;

        var readBufferGPU:GPUBuffer;
        var needsUnmap:Bool = true;

        if (data.readBuffer == null) {
            readBufferGPU = device.createBuffer({
                label: attribute.name,
                size: size,
                usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
            });

            needsUnmap = false;

            data.readBuffer = readBufferGPU;
        }

        var cmdEncoder:GPUCmdEncoder = device.createCommandEncoder({});
        cmdEncoder.copyBufferToBuffer(bufferGPU, 0, readBufferGPU, 0, size);

        if (needsUnmap) readBufferGPU.unmap();

        var gpuCommands:GPUCommandBuffer = cmdEncoder.finish();
        device.queue.submit([gpuCommands]);

        return Promise.create(function(resolve) {
            readBufferGPU.mapAsync(GPUMapMode.READ).then(function() {
                var arrayBuffer:Dynamic = readBufferGPU.getMappedRange();
                resolve(arrayBuffer);
            });
        });
    }

    private function _getVertexFormat(geometryAttribute:Dynamic):String {
        var itemSize:Int = geometryAttribute.itemSize;
        var arrayType:Dynamic = geometryAttribute.array.constructor;
        var attributeType:Dynamic = geometryAttribute.constructor;

        var format:String;

        if (itemSize == 1) {
            format = typeArraysToVertexFormatPrefixForItemSize1.get(arrayType);
        } else {
            var prefixOptions:Array<Dynamic> = typedAttributeToVertexFormatPrefix.get(attributeType) || typedArraysToVertexFormatPrefix.get(arrayType);
            var prefix:String = prefixOptions[geometryAttribute.normalized ? 1 : 0];

            if (prefix != null) {
                var bytesPerUnit:Int = arrayType.BYTES_PER_ELEMENT * itemSize;
                var paddedBytesPerUnit:Int = Math.floor((bytesPerUnit + 3) / 4) * 4;
                var paddedItemSize:Int = paddedBytesPerUnit / arrayType.BYTES_PER_ELEMENT;

                if (paddedItemSize % 1 != 0) {
                    throw new Error('THREE.WebGPUAttributeUtils: Bad vertex format item size.');
                }

                format = prefix + 'x' + paddedItemSize;
            }
        }

        if (format == null) {
            console.error('THREE.WebGPUAttributeUtils: Vertex format not supported yet.');
        }

        return format;
    }

    private function _getBufferAttribute(attribute:Dynamic):Dynamic {
        if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

        return attribute;
    }
}

// Maps
var typedArraysToVertexFormatPrefix:Map<Dynamic, Array<String>> = new Map([
    [Int8Array, ['sint8', 'snorm8']],
    [Uint8Array, ['uint8', 'unorm8']],
    [Int16Array, ['sint16', 'snorm16']],
    [Uint16Array, ['uint16', 'unorm16']],
    [Int32Array, ['sint32', 'snorm32']],
    [Uint32Array, ['uint32', 'unorm32']],
    [Float32Array, ['float32']]
]);

var typedAttributeToVertexFormatPrefix:Map<Dynamic, Array<String>> = new Map([
    [Float16BufferAttribute, ['float16']]
]);

var typeArraysToVertexFormatPrefixForItemSize1:Map<Dynamic, String> = new Map([
    [Int32Array, 'sint32'],
    [Int16Array, 'sint32'], // patch for INT16
    [Uint32Array, 'uint32'],
    [Uint16Array, 'uint32'], // patch for UINT16
    [Float32Array, 'float32']
]);