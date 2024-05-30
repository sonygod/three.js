import haxe.io.Bytes;

class TypedArraysToVertexFormatPrefix {
    public static get(arrayType:Dynamic):Array<String> {
        if (arrayType == Int8Array) {
            return ["sint8", "snorm8"];
        } else if (arrayType == Uint8Array) {
            return ["uint8", "unorm8"];
        } else if (arrayType == Int16Array) {
            return ["sint16", "snorm16"];
        } else if (arrayType == Uint16Array) {
            return ["uint16", "unorm16"];
        } else if (arrayType == Int32Array) {
            return ["sint32", "snorm32"];
        } else if (arrayType == Uint32Array) {
            return ["uint32", "unorm32"];
        } else if (arrayType == Float32Array) {
            return ["float32"];
        }
        return [];
    }
}

class TypedAttributeToVertexFormatPrefix {
    public static get(attributeType:Dynamic):Array<String> {
        if (attributeType == Float16BufferAttribute) {
            return ["float16"];
        }
        return [];
    }
}

class TypeArraysToVertexFormatPrefixForItemSize1 {
    public static get(arrayType:Dynamic):String {
        if (arrayType == Int32Array) {
            return "sint32";
        } else if (arrayType == Int16Array) {
            return "sint32"; // patch for INT16
        } else if (arrayType == Uint32Array) {
            return "uint32";
        } else if (arrayType == Uint16Array) {
            return "uint32"; // patch for UINT16
        } else if (arrayType == Float32Array) {
            return "float32";
        }
        return "";
    }
}

class WebGPUAttributeUtils {
    private backend:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
    }

    public function createAttribute(attribute:Dynamic, usage:Dynamic) {
        var bufferAttribute = this->_getBufferAttribute(attribute);
        var bufferData = this.backend.get(bufferAttribute);
        var buffer = bufferData.buffer;
        if (buffer == null) {
            var device = this.backend.device;
            var array = bufferAttribute.array;
            // patch for INT16 and UINT16
            if (!attribute.normalized && (Type.enumEq(array, Int16Array) || Type.enumEq(array, Uint16Array))) {
                var tempArray = new Uint32Array(array.length);
                for (i in 0...array.length) {
                    tempArray[i] = array[i];
                }
                array = tempArray;
            }
            bufferAttribute.array = array;
            if ((bufferAttribute.isStorageBufferAttribute || bufferAttribute.isStorageInstancedBufferAttribute) && bufferAttribute.itemSize == 3) {
                array = new array.constructor(bufferAttribute.count * 4);
                for (i in 0...bufferAttribute.count) {
                    array.set(bufferAttribute.array.subarray(i * 3, i * 3 + 3), i * 4);
                }
                // Update BufferAttribute
                bufferAttribute.itemSize = 4;
                bufferAttribute.array = array;
            }
            var size = array.byteLength + ((4 - (array.byteLength % 4)) % 4); // ensure 4 byte alignment, see #20441
            buffer = device.createBuffer({ label : bufferAttribute.name, size : size, usage : usage, mappedAtCreation : true });
            new array.constructor(buffer.getMappedRange()).set(array);
            buffer.unmap();
            bufferData.buffer = buffer;
        }
    }

    public function updateAttribute(attribute:Dynamic) {
        var bufferAttribute = this->_getBufferAttribute(attribute);
        var backend = this.backend;
        var device = backend.device;
        var buffer = backend.get(bufferAttribute).buffer;
        var array = bufferAttribute.array;
        var updateRanges = bufferAttribute.updateRanges;
        if (updateRanges.length == 0) {
            // Not using update ranges
            device.queue.writeBuffer(buffer, 0, array, 0);
        } else {
            for (i in 0...updateRanges.length) {
                var range = updateRanges[i];
                device.queue.writeBuffer(buffer, 0, array, range.start * array.BYTES_PER_ELEMENT, range.count * array.BYTES_PER_ELEMENT);
            }
            bufferAttribute.clearUpdateRanges();
        }
    }

    public function createShaderVertexBuffers(renderObject:Dynamic):Array<Dynamic> {
        var attributes = renderObject.getAttributes();
        var vertexBuffers = new Map();
        for (slot in 0...attributes.length) {
            var geometryAttribute = attributes[slot];
            var bytesPerElement = geometryAttribute.array.BYTES_PER_ELEMENT;
            var bufferAttribute = this->_getBufferAttribute(geometryAttribute);
            var vertexBufferLayout = vertexBuffers.get(bufferAttribute);
            if (vertexBufferLayout == null) {
                var arrayStride:Int, stepMode:Dynamic;
                if (geometryAttribute.isInterleavedBufferAttribute) {
                    arrayStride = geometryAttribute.data.stride * bytesPerElement;
                    stepMode = geometryAttribute.data.isInstancedInterleavedBuffer ? GPUInputStepMode.Instance : GPUInputStepMode.Vertex;
                } else {
                    arrayStride = geometryAttribute.itemSize * bytesPerElement;
                    stepMode = geometryAttribute.isInstancedBufferAttribute ? GPUInputStepMode.Instance : GPUInputStepMode.Vertex;
                }
                // patch for INT16 and UINT16
                if (!geometryAttribute.normalized && (Type.enumEq(geometryAttribute.array, Int16Array) || Type.enumEq(geometryAttribute.array, Uint16Array))) {
                    arrayStride = 4;
                }
                vertexBufferLayout = { arrayStride : arrayStride, attributes : [], stepMode : stepMode };
                vertexBuffers.set(bufferAttribute, vertexBufferLayout);
            }
            var format = this->_getVertexFormat(geometryAttribute);
            var offset = (geometryAttribute.isInterleavedBufferAttribute) ? geometryAttribute.offset * bytesPerElement : 0;
            vertexBufferLayout.attributes.push({ shaderLocation : slot, offset : offset, format : format });
        }
        return vertexBuffers.values().toArray();
    }

    public function destroyAttribute(attribute:Dynamic) {
        var backend = this.backend;
        var data = backend.get(this->_getBufferAttribute(attribute));
        data.buffer.destroy();
        backend.delete(attribute);
    }

    public function getArrayBufferAsync(attribute:Dynamic):Future<Bytes> {
        var backend = this.backend;
        var device = backend.device;
        var data = backend.get(this->_getBufferAttribute(attribute));
        var bufferGPU = data.buffer;
        var size = bufferGPU.size;
        var readBufferGPU = data.readBuffer;
        var needsUnmap = true;
        if (readBufferGPU == null) {
            readBufferGPU = device.createBuffer({ label : attribute.name, size : size, usage : GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
            needsUnmap = false;
            data.readBuffer = readBufferGPU;
        }
        var cmdEncoder = device.createCommandEncoder();
        cmdEncoder.copyBufferToBuffer(bufferGPU, 0, readBufferGPU, 0, size);
        if (needsUnmap) {
            readBufferGPU.unmap();
        }
        var gpuCommands = cmdEncoder.finish();
        device.queue.submit([gpuCommands]);
        return readBufferGPU.mapAsync(GPUMapMode.READ).then(($return) -> Bytes.ofData($return));
    }

    private function _getVertexFormat(geometryAttribute:Dynamic):String {
        var itemSize = geometryAttribute.itemSize;
        var normalized = geometryAttribute.normalized;
        var arrayType = Type.getClass(geometryAttribute.array);
        var attributeType = Type.getClass(geometryAttribute);
        var format:String;
        if (itemSize == 1) {
            format = TypeArraysToVertexFormatPrefixForItemSize1.get(arrayType);
        } else {
            var prefixOptions = TypedAttributeToVertexFormatPrefix.get(attributeType) || TypedArraysToVertexFormatPrefix.get(arrayType);
            var prefix = prefixOptions[normalized ? 1 : 0];
            if (prefix) {
                var bytesPerUnit = arrayType.BYTES_PER_ELEMENT * itemSize;
                var paddedBytesPerUnit = Std.int(Std.ceil(bytesPerUnit / 4.0) * 4);
                var paddedItemSize = paddedBytesPerUnit / arrayType.BYTES_PER_ELEMENT;
                if (paddedItemSize % 1 != 0) {
                    throw "THREE.WebGPUAttributeUtils: Bad vertex format item size.";
                }
                format = prefix + "x" + paddedItemSize;
            }
        }
        if (format == null) {
            trace("THREE.WebGPUAttributeUtils: Vertex format not supported yet.");
        }
        return format;
    }

    private function _getBufferAttribute(attribute:Dynamic):Dynamic {
        if (attribute.isInterleavedBufferAttribute) {
            attribute = attribute.data;
        }
        return attribute;
    }
}