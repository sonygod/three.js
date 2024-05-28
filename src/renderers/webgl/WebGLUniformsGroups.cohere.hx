class WebGLUniformsGroups {
    public var buffers:Map<Int,OpenFLWebGLBuffer>;
    public var updateList:Map<Int,Int>;
    public var allocatedBindingPoints:Array<Int>;
    public var maxBindingPoints:Int;
    public var gl:OpenFLWebGLContext;
    public var info:WebGLInfo;
    public var capabilities:WebGLCapabilities;
    public var state:WebGLState;

    public function new(gl:OpenFLWebGLContext, info:WebGLInfo, capabilities:WebGLCapabilities, state:WebGLState) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;
        this.buffers = Map_Impl_.<Int,OpenFLWebGLBuffer> {};
        this.updateList = Map_Impl_.<Int,Int> {};
        this.allocatedBindingPoints = [];
        this.maxBindingPoints = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS);
    }

    public function bind(uniformsGroup:WebGLUniformsGroup, program:WebGLProgram) {
        state.uniformBlockBinding(uniformsGroup, program.program);
    }

    public function update(uniformsGroup:WebGLUniformsGroup, program:WebGLProgram) {
        var buffer = buffers.get(uniformsGroup.id);
        if (buffer == null) {
            prepareUniformsGroup(uniformsGroup);
            buffer = createBuffer(uniformsGroup);
            buffers.set(uniformsGroup.id, buffer);
            uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);
        }
        state.updateUBOMapping(uniformsGroup, program.program);
        var frame = info.render.frame;
        if (updateList.get(uniformsGroup.id) != frame) {
            updateBufferData(uniformsGroup);
            updateList.set(uniformsGroup.id, frame);
        }
    }

    public function createBuffer(uniformsGroup:WebGLUniformsGroup):OpenFLWebGLBuffer {
        var bindingPointIndex = allocateBindingPointIndex();
        uniformsGroup.__bindingPointIndex = bindingPointIndex;
        var buffer = gl.createBuffer();
        var size = uniformsGroup.__size;
        var usage = uniformsGroup.usage;
        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);
        gl.bufferData(gl.UNIFORM_BUFFER, size, usage);
        gl.bindBuffer(gl.UNIFORM_BUFFER, null);
        gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingPointIndex, buffer);
        return buffer;
    }

    public function allocateBindingPointIndex():Int {
        for (i in 0...maxBindingPoints) {
            if (allocatedBindingPoints.indexOf(i) == -1) {
                allocatedBindingPoints.push(i);
                return i;
            }
        }
        trace('THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.');
        return 0;
    }

    public function updateBufferData(uniformsGroup:WebGLUniformsGroup) {
        var buffer = buffers.get(uniformsGroup.id);
        var uniforms = uniformsGroup.uniforms;
        var cache = uniformsGroup.__cache;
        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);
        for (i in 0...uniforms.length) {
            var uniformArray = if (Array.isArray(uniforms[i])) uniforms[i] else [uniforms[i]];
            for (j in 0...uniformArray.length) {
                var uniform = uniformArray[j];
                if (hasUniformChanged(uniform, i, j, cache)) {
                    var offset = uniform.__offset;
                    var values = if (Array.isArray(uniform.value)) uniform.value else [uniform.value];
                    var arrayOffset = 0;
                    for (k in 0...values.length) {
                        var value = values[k];
                        var info = getUniformSize(value);
                        if (typeof value == 'Number' || typeof value == 'Bool') {
                            uniform.__data[0] = value;
                            gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);
                        } else if (value is Matrix3) {
                            uniform.__data[0] = value.elements[0];
                            uniform.__data[1] = value.elements[1];
                            uniform.__data[2] = value.elements[2];
                            uniform.__data[3] = 0;
                            uniform.__data[4] = value.elements[3];
                            uniform.__data[5] = value.elements[4];
                            uniform.__data[6] = value.elements[5];
                            uniform.__data[7] = 0;
                            uniform.__data[8] = value.elements[6];
                            uniform.__data[9] = value.elements[7];
                            uniform.__data[10] = value.elements[8];
                            uniform.__data[11] = 0;
                        } else {
                            value.toArray(uniform.__data, arrayOffset);
                            arrayOffset += info.storage / Float32Array.BYTES_PER_ELEMENT;
                        }
                    }
                    gl.bufferSubData(gl.UNIFORM_BUFFER, offset, uniform.__data);
                }
            }
        }
        gl.bindBuffer(gl.UNIFORM_BUFFER, null);
    }

    public function hasUniformChanged(uniform, index:Int, indexArray:Int, cache:Map<String,Dynamic>):Bool {
        var value = uniform.value;
        var indexString = index + '_' + indexArray;
        if (!cache.exists(indexString)) {
            if (typeof value == 'Number' || typeof value == 'Bool') {
                cache.set(indexString, value);
            } else {
                cache.set(indexString, value.clone());
            }
            return true;
        } else {
            var cachedObject = cache.get(indexString);
            if (typeof value == 'Number' || typeof value == 'Bool') {
                if (cachedObject != value) {
                    cache.set(indexString, value);
                    return true;
                }
            } else {
                if (!cachedObject.equals(value)) {
                    cachedObject.copy(value);
                    return true;
                }
            }
        }
        return false;
    }

    public function prepareUniformsGroup(uniformsGroup:WebGLUniformsGroup) {
        var uniforms = uniformsGroup.uniforms;
        var offset:Int = 0;
        var chunkSize:Int = 16;
        for (i in 0...uniforms.length) {
            var uniformArray = if (Array.isArray(uniforms[i])) uniforms[i] else [uniforms[i]];
            for (j in 0...uniformArray.length) {
                var uniform = uniformArray[j];
                var values = if (Array.isArray(uniform.value)) uniform.value else [uniform.value];
                for (k in 0...values.length) {
                    var value = values[k];
                    var info = getUniformSize(value);
                    var chunkOffsetUniform = offset % chunkSize;
                    if (chunkOffsetUniform != 0 && (chunkSize - chunkOffsetUniform) < info.boundary) {
                        offset += (chunkSize - chunkOffsetUniform);
                    }
                    uniform.__data = new Float32Array(info.storage / Float32Array.BYTES_PER_ELEMENT);
                    uniform.__offset = offset;
                    offset += info.storage;
                }
            }
        }
        var chunkOffset = offset % chunkSize;
        if (chunkOffset > 0) offset += (chunkSize - chunkOffset);
        uniformsGroup.__size = offset;
        uniformsGroup.__cache = Map_Impl_.<String,Dynamic> {};
    }

    public function getUniformSize(value):{boundary:Int, storage:Int} {
        var info = {boundary: 0, storage: 0};
        if (typeof value == 'Number' || typeof value == 'Bool') {
            info.boundary = 4;
            info.storage = 4;
        } else if (value is Vector2) {
            info.boundary = 8;
            info.storage = 8;
        } else if (value is Vector3 || value is Color) {
            info.boundary = 16;
            info.storage = 12;
        } else if (value is Vector4) {
            info.boundary = 16;
            info.storage = 16;
        } else if (value is Matrix3) {
            info.boundary = 48;
            info.storage = 48;
        } else if (value is Matrix4) {
            info.boundary = 64;
            info.storage = 64;
        } else if (value is Texture) {
            trace('THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.');
        } else {
            trace('THREE.WebGLRenderer: Unsupported uniform value type: ' + Std.string(value));
        }
        return info;
    }

    public function onUniformsGroupsDispose(event:Event) {
        var uniformsGroup = cast(event.target, WebGLUniformsGroup);
        uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);
        var index = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
        allocatedBindingPoints.splice(index, 1);
        gl.deleteBuffer(buffers.get(uniformsGroup.id));
        buffers.remove(uniformsGroup.id);
        updateList.remove(uniformsGroup.id);
    }

    public function dispose() {
        for (id in buffers.keys()) {
            gl.deleteBuffer(buffers.get(id));
        }
        allocatedBindingPoints = [];
        buffers = Map_Impl_.<Int,OpenFLWebGLBuffer> {};
        updateList = Map_Impl_.<Int,Int> {};
    }

    public function toMap():Map<String,Function> {
        return {
            'bind': bind,
            'update': update,
            'dispose': dispose
        };
    }
}