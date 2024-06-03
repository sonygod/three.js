import three.Float16BufferAttribute;
import three.webgpu.GPUInputStepMode;

class WebGPUAttributeUtils {

    private var backend:Backend;

    public function new(backend:Backend) {
        this.backend = backend;
    }

    public function createAttribute(attribute:Attribute, usage:Int) {
        var bufferAttribute = _getBufferAttribute(attribute);
        var bufferData = backend.get(bufferAttribute);
        var buffer = bufferData.buffer;

        if (buffer == null) {
            var device = backend.device;
            var array = bufferAttribute.array;

            // patch for INT16 and UINT16
            if (attribute.normalized == false && (Std.is(array, Int16Array) || Std.is(array, Uint16Array))) {
                var tempArray = new Uint32Array(array.length);
                for (i in 0...array.length) {
                    tempArray[i] = array[i];
                }
                array = tempArray;
            }

            bufferAttribute.array = array;

            if ((bufferAttribute.isStorageBufferAttribute || bufferAttribute.isStorageInstancedBufferAttribute) && bufferAttribute.itemSize == 3) {
                array = Type.createInstance(Type.getClass(array), bufferAttribute.count * 4);

                for (i in 0...bufferAttribute.count) {
                    array.set(array.subarray(i * 3, i * 3 + 3), i * 4);
                }

                // Update BufferAttribute
                bufferAttribute.itemSize = 4;
                bufferAttribute.array = array;
            }

            var size = array.byteLength + ((4 - (array.byteLength % 4)) % 4); // ensure 4 byte alignment, see #20441

            buffer = device.createBuffer({
                label: bufferAttribute.name,
                size: size,
                usage: usage,
                mappedAtCreation: true
            });

            Type.createInstance(Type.getClass(array), buffer.getMappedRange()).set(array);
            buffer.unmap();
            bufferData.buffer = buffer;
        }
    }

    public function updateAttribute(attribute:Attribute) {
        var bufferAttribute = _getBufferAttribute(attribute);
        var device = backend.device;
        var buffer = backend.get(bufferAttribute).buffer;
        var array = bufferAttribute.array;
        var updateRanges = bufferAttribute.updateRanges;

        if (updateRanges.length == 0) {
            device.queue.writeBuffer(
                buffer,
                0,
                array,
                0
            );
        } else {
            for (i in 0...updateRanges.length) {
                var range = updateRanges[i];
                device.queue.writeBuffer(
                    buffer,
                    0,
                    array,
                    range.start * array.BYTES_PER_ELEMENT,
                    range.count * array.BYTES_PER_ELEMENT
                );
            }
            bufferAttribute.clearUpdateRanges();
        }
    }

    public function createShaderVertexBuffers(renderObject:RenderObject):Array<VertexBufferLayout> {
        var attributes = renderObject.getAttributes();
        var vertexBuffers = new Map<BufferAttribute, VertexBufferLayout>();

        for (slot in 0...attributes.length) {
            var geometryAttribute = attributes[slot];
            var bytesPerElement = geometryAttribute.array.BYTES_PER_ELEMENT;
            var bufferAttribute = _getBufferAttribute(geometryAttribute);

            var vertexBufferLayout = vertexBuffers.get(bufferAttribute);

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
                if (geometryAttribute.normalized == false && (Std.is(geometryAttribute.array, Int16Array) || Std.is(geometryAttribute.array, Uint16Array))) {
                    arrayStride = 4;
                }

                vertexBufferLayout = {
                    arrayStride: arrayStride,
                    attributes: [],
                    stepMode: stepMode
                };

                vertexBuffers.set(bufferAttribute, vertexBufferLayout);
            }

            var format = _getVertexFormat(geometryAttribute);
            var offset = (geometryAttribute.isInterleavedBufferAttribute) ? geometryAttribute.offset * bytesPerElement : 0;

            vertexBufferLayout.attributes.push({
                shaderLocation: slot,
                offset: offset,
                format: format
            });
        }

        return Array<VertexBufferLayout>(vertexBuffers.values());
    }

    public function destroyAttribute(attribute:Attribute) {
        var data = backend.get(_getBufferAttribute(attribute));
        data.buffer.destroy();
        backend.delete(attribute);
    }

    public async function getArrayBufferAsync(attribute:Attribute):Promise<ArrayBuffer> {
        var device = backend.device;
        var data = backend.get(_getBufferAttribute(attribute));
        var bufferGPU = data.buffer;
        var size = bufferGPU.size;
        var readBufferGPU = data.readBuffer;
        var needsUnmap = true;

        if (readBufferGPU == null) {
            readBufferGPU = device.createBuffer({
                label: attribute.name,
                size: size,
                usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
            });

            needsUnmap = false;
            data.readBuffer = readBufferGPU;
        }

        var cmdEncoder = device.createCommandEncoder({});
        cmdEncoder.copyBufferToBuffer(
            bufferGPU,
            0,
            readBufferGPU,
            0,
            size
        );

        if (needsUnmap) readBufferGPU.unmap();

        var gpuCommands = cmdEncoder.finish();
        device.queue.submit([gpuCommands]);

        await readBufferGPU.mapAsync(GPUMapMode.READ);

        var arrayBuffer = readBufferGPU.getMappedRange();

        return arrayBuffer;
    }

    private function _getVertexFormat(geometryAttribute:Attribute):String {
        var itemSize = geometryAttribute.itemSize;
        var normalized = geometryAttribute.normalized;
        var ArrayType = Type.getClass(geometryAttribute.array);
        var AttributeType = Type.getClass(geometryAttribute);

        var format:String;

        if (itemSize == 1) {
            format = typeArraysToVertexFormatPrefixForItemSize1.get(ArrayType);
        } else {
            var prefixOptions = typedAttributeToVertexFormatPrefix.get(AttributeType) ?? typedArraysToVertexFormatPrefix.get(ArrayType);
            var prefix = prefixOptions[normalized ? 1 : 0];

            if (prefix != null) {
                var bytesPerUnit = ArrayType.BYTES_PER_ELEMENT * itemSize;
                var paddedBytesPerUnit = Math.floor((bytesPerUnit + 3) / 4) * 4;
                var paddedItemSize = paddedBytesPerUnit / ArrayType.BYTES_PER_ELEMENT;

                if (paddedItemSize % 1 != 0) {
                    throw new Error('THREE.WebGPUAttributeUtils: Bad vertex format item size.');
                }

                format = `${prefix}x${paddedItemSize}`;
            }
        }

        if (format == null) {
            trace('THREE.WebGPUAttributeUtils: Vertex format not supported yet.');
        }

        return format;
    }

    private function _getBufferAttribute(attribute:Attribute):Attribute {
        if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;
        return attribute;
    }
}