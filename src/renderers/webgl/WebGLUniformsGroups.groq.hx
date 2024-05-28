package three.js.src.renderers.webgl;

import openfl.display3D.Context3D;
import openfl.display3D.Program3D;

class WebGLUniformsGroups {
    private var gl:Context3D;
    private var info:Any;
    private var capabilities:Any;
    private var state:Any;
    private var buffers:Map<String, Buffer>;
    private var updateList:Map<String, Int>;
    private var allocatedBindingPoints:Array<Int>;

    public function new(gl:Context3D, info:Any, capabilities:Any, state:Any) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;
        buffers = new Map<String, Buffer>();
        updateList = new Map<String, Int>();
        allocatedBindingPoints = [];

        var maxBindingPoints:Int = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS);
    }

    private function bind(uniformsGroup:Any, program:Program3D) {
        var webglProgram:Program3D = program.program;
        state.uniformBlockBinding(uniformsGroup, webglProgram);
    }

    private function update(uniformsGroup:Any, program:Program3D) {
        var buffer:Buffer = buffers[uniformsGroup.id];
        if (buffer == null) {
            prepareUniformsGroup(uniformsGroup);
            buffer = createBuffer(uniformsGroup);
            buffers[uniformsGroup.id] = buffer;
            uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);
        }

        var webglProgram:Program3D = program.program;
        state.updateUBOMapping(uniformsGroup, webglProgram);

        var frame:Int = info.render.frame;
        if (updateList[uniformsGroup.id] != frame) {
            updateBufferData(uniformsGroup);
            updateList[uniformsGroup.id] = frame;
        }
    }

    private function createBuffer(uniformsGroup:Any) {
        var bindingPointIndex:Int = allocateBindingPointIndex();
        uniformsGroup.__bindingPointIndex = bindingPointIndex;

        var buffer:Buffer = gl.createBuffer();
        var size:Int = uniformsGroup.__size;
        var usage:Int = uniformsGroup.usage;

        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);
        gl.bufferData(gl.UNIFORM_BUFFER, size, usage);
        gl.bindBuffer(gl.UNIFORM_BUFFER, null);
        gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingPointIndex, buffer);

        return buffer;
    }

    private function allocateBindingPointIndex():Int {
        for (i in 0...maxBindingPoints) {
            if (allocatedBindingPoints.indexOf(i) == -1) {
                allocatedBindingPoints.push(i);
                return i;
            }
        }
        // console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.");
        return 0;
    }

    private function updateBufferData(uniformsGroup:Any) {
        var buffer:Buffer = buffers[uniformsGroup.id];
        var uniforms:Array<Any> = uniformsGroup.uniforms;
        var cache:Any = uniformsGroup.__cache;

        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);

        for (i in 0...uniforms.length) {
            var uniformArray:Array<Any> = Std.is(uniforms[i], Array) ? uniforms[i] : [uniforms[i]];

            for (j in 0...uniformArray.length) {
                var uniform:Any = uniformArray[j];

                if (hasUniformChanged(uniform, i, j, cache)) {
                    var offset:Int = uniform.__offset;

                    var values:Array<Any> = Std.is(uniform.value, Array) ? uniform.value : [uniform.value];

                    var arrayOffset:Int = 0;

                    for (k in 0...values.length) {
                        var value:Any = values[k];

                        var info:Any = getUniformSize(value);

                        if (Std.is(value, Float) || Std.is(value, Bool)) {
                            uniform.__data[0] = value;
                            gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);
                        } else if (value.isMatrix3) {
                            // manually converting 3x3 to 3x4

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

                            gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);
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

    private function hasUniformChanged(uniform:Any, index:Int, indexArray:Int, cache:Any) {
        var value:Any = uniform.value;
        var indexString:String = '$index _$indexArray';

        if (!cache.exists(indexString)) {
            // cache entry does not exist so far

            if (Std.is(value, Float) || Std.is(value, Bool)) {
                cache.set(indexString, value);
            } else {
                cache.set(indexString, value.clone());
            }

            return true;
        } else {
            var cachedObject:Any = cache.get(indexString);

            // compare current value with cached entry

            if (Std.is(value, Float) || Std.is(value, Bool)) {
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

    private function prepareUniformsGroup(uniformsGroup:Any) {
        // determine total buffer size according to the STD140 layout
        // Hint: STD140 is the only supported layout in WebGL 2

        var uniforms:Array<Any> = uniformsGroup.uniforms;

        var offset:Int = 0; // global buffer offset in bytes
        var chunkSize:Int = 16; // size of a chunk in bytes

        for (i in 0...uniforms.length) {
            var uniformArray:Array<Any> = Std.is(uniforms[i], Array) ? uniforms[i] : [uniforms[i]];

            for (j in 0...uniformArray.length) {
                var uniform:Any = uniformArray[j];

                var values:Array<Any> = Std.is(uniform.value, Array) ? uniform.value : [uniform.value];

                for (k in 0...values.length) {
                    var value:Any = values[k];

                    var info:Any = getUniformSize(value);

                    // Calculate the chunk offset
                    var chunkOffsetUniform:Int = offset % chunkSize;

                    // Check for chunk overflow
                    if (chunkOffsetUniform != 0 && (chunkSize - chunkOffsetUniform) < info.boundary) {
                        // Add padding and adjust offset
                        offset += (chunkSize - chunkOffsetUniform);
                    }

                    // the following two properties will be used for partial buffer updates

                    uniform.__data = new Float32Array(info.storage / Float32Array.BYTES_PER_ELEMENT);
                    uniform.__offset = offset;

                    // Update the global offset
                    offset += info.storage;
                }
            }
        }

        // ensure correct final padding

        var chunkOffset:Int = offset % chunkSize;

        if (chunkOffset > 0) offset += (chunkSize - chunkOffset);

        uniformsGroup.__size = offset;
        uniformsGroup.__cache = {};
    }

    private function getUniformSize(value:Any) {
        var info:Any = {
            boundary: 0, // bytes
            storage: 0 // bytes
        };

        // determine sizes according to STD140

        if (Std.is(value, Float) || Std.is(value, Bool)) {
            // float/int/bool

            info.boundary = 4;
            info.storage = 4;
        } else if (value.isVector2) {
            // vec2

            info.boundary = 8;
            info.storage = 8;
        } else if (value.isVector3 || value.isColor) {
            // vec3

            info.boundary = 16;
            info.storage = 12; // evil: vec3 must start on a 16-byte boundary but it only consumes 12 bytes
        } else if (value.isVector4) {
            // vec4

            info.boundary = 16;
            info.storage = 16;
        } else if (value.isMatrix3) {
            // mat3 (in STD140 a 3x3 matrix is represented as 3x4)

            info.boundary = 48;
            info.storage = 48;
        } else if (value.isMatrix4) {
            // mat4

            info.boundary = 64;
            info.storage = 64;
        } else if (value.isTexture) {
            // console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.");
        } else {
            // console.warn("THREE.WebGLRenderer: Unsupported uniform value type.", value);
        }

        return info;
    }

    private function onUniformsGroupsDispose(event:Any) {
        var uniformsGroup:Any = event.target;

        uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);

        var index:Int = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
        allocatedBindingPoints.splice(index, 1);

        gl.deleteBuffer(buffers[uniformsGroup.id]);

        delete buffers[uniformsGroup.id];
        delete updateList[uniformsGroup.id];
    }

    public function dispose() {
        for (id in buffers.keys()) {
            gl.deleteBuffer(buffers[id]);
        }

        allocatedBindingPoints = [];
        buffers = new Map<String, Buffer>();
        updateList = new Map<String, Int>;
    }
}