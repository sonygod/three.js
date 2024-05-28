class WebGLAttributes {
    var buffers = new WeakMap();

    public function new(gl : WebGLRenderer) {
        this.gl = gl;
    }

    function createBuffer(attribute : InterleavedBufferAttribute, bufferType : Int) : Void {
        var array = attribute.array;
        var usage = attribute.usage;
        var size = array.byteLength;

        var buffer = gl.createBuffer();

        gl.bindBuffer(bufferType, buffer);
        gl.bufferData(bufferType, array, usage);

        attribute.onUploadCallback();

        var type : Int;

        switch (true) {
            case array instanceof Float32Array:
                type = gl.FLOAT;
                break;
            case array instanceof Uint16Array:
                type = if (attribute.isFloat16BufferAttribute) gl.HALF_FLOAT else gl.UNSIGNED_SHORT;
                break;
            case array instanceof Int16Array:
                type = gl.SHORT;
                break;
            case array instanceof Uint32Array:
                type = gl.UNSIGNED_INT;
                break;
            case array instanceof Int32Array:
                type = gl.INT;
                break;
            case array instanceof Int8Array:
                type = gl.BYTE;
                break;
            case array instanceof Uint8Array:
                type = gl.UNSIGNED_BYTE;
                break;
            case array instanceof Uint8ClampedArray:
                type = gl.UNSIGNED_BYTE;
                break;
            default:
                throw new Error('Unsupported buffer data format: ' + Std.string(array));
        }

        buffers.set(attribute, { buffer: buffer, type: type, bytesPerElement: array.BYTES_PER_ELEMENT, version: attribute.version, size: size });
    }

    function updateBuffer(buffer : WebGLBuffer, attribute : InterleavedBufferAttribute, bufferType : Int) : Void {
        var array = attribute.array;
        var updateRange = attribute._updateRange;
        var updateRanges = attribute.updateRanges;

        gl.bindBuffer(bufferType, buffer);

        if (updateRange.count == -1 && updateRanges.length == 0) {
            gl.bufferSubData(bufferType, 0, array);
        }

        for (i in 0...updateRanges.length) {
            var range = updateRanges[i];
            gl.bufferSubData(bufferType, range.start * array.BYTES_PER_ELEMENT, array, range.start, range.count);
        }

        attribute.clearUpdateRanges();

        if (updateRange.count != -1) {
            gl.bufferSubData(bufferType, updateRange.offset * array.BYTES_PER_ELEMENT, array, updateRange.offset, updateRange.count);
            updateRange.count = -1;
        }

        attribute.onUploadCallback();
    }

    function get(attribute : InterleavedBufferAttribute) : Void {
        if (attribute.isInterleavedBufferAttribute)
            attribute = attribute.data;

        return buffers.get(attribute);
    }

    function remove(attribute : InterleavedBufferAttribute) : Void {
        if (attribute.isInterleavedBufferAttribute)
            attribute = attribute.data;

        var data = buffers.get(attribute);

        if (data != null) {
            gl.deleteBuffer(data.buffer);
            buffers.delete(attribute);
        }
    }

    function update(attribute : InterleavedBufferAttribute, bufferType : Int) : Void {
        if (attribute.isGLBufferAttribute) {
            var cached = buffers.get(attribute);

            if (cached == null || cached.version < attribute.version) {
                buffers.set(attribute, { buffer: attribute.buffer, type: attribute.type, bytesPerElement: attribute.elementSize, version: attribute.version });
            }

            return;
        }

        if (attribute.isInterleavedBufferAttribute)
            attribute = attribute.data;

        var data = buffers.get(attribute);

        if (data == null) {
            createBuffer(attribute, bufferType);
        } else if (data.version < attribute.version) {
            if (data.size != attribute.array.byteLength) {
                throw new Error('The size of the buffer attribute\'s array buffer does not match the original size. Resizing buffer attributes is not supported.');
            }

            updateBuffer(data.buffer, attribute, bufferType);
            data.version = attribute.version;
        }
    }
}