package three.js.src.renderers.webgl;

import three.js.src.renderers.webgl.WebGLRenderer;

class WebGLUniformsGroups {
    private var gl:WebGLRenderingContext;
    private var info:Dynamic;
    private var capabilities:Dynamic;
    private var state:Dynamic;
    private var buffers:Map<String, WebGLBuffer>;
    private var updateList:Map<String, Int>;
    private var allocatedBindingPoints:Array<Int>;

    public function new(gl:WebGLRenderingContext, info:Dynamic, capabilities:Dynamic, state:Dynamic) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;
        this.buffers = new Map<String, WebGLBuffer>();
        this.updateList = new Map<String, Int>();
        this.allocatedBindingPoints = new Array<Int>();

        var maxBindingPoints:Int = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS);
    }

    public function bind(uniformsGroup:Dynamic, program:Dynamic):Void {
        var webglProgram:WebGLProgram = program.program;
        state.uniformBlockBinding(uniformsGroup, webglProgram);
    }

    public function update(uniformsGroup:Dynamic, program:Dynamic):Void {
        var buffer:WebGLBuffer = buffers[uniformsGroup.id];
        if (buffer == null) {
            prepareUniformsGroup(uniformsGroup);
            buffer = createBuffer(uniformsGroup);
            buffers[uniformsGroup.id] = buffer;
            uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);
        }

        var webglProgram:WebGLProgram = program.program;
        state.updateUBOMapping(uniformsGroup, webglProgram);

        var frame:Int = info.render.frame;
        if (updateList[uniformsGroup.id] != frame) {
            updateBufferData(uniformsGroup);
            updateList[uniformsGroup.id] = frame;
        }
    }

    private function createBuffer(uniformsGroup:Dynamic):WebGLBuffer {
        var bindingPointIndex:Int = allocateBindingPointIndex();
        uniformsGroup.__bindingPointIndex = bindingPointIndex;

        var buffer:WebGLBuffer = gl.createBuffer();
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
        trace('THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.');
        return 0;
    }

    private function updateBufferData(uniformsGroup:Dynamic):Void {
        var buffer:WebGLBuffer = buffers[uniformsGroup.id];
        var uniforms:Array<Dynamic> = uniformsGroup.uniforms;
        var cache:Dynamic = uniformsGroup.__cache;

        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);

        for (i in 0...uniforms.length) {
            var uniformArray:Array<Dynamic> = uniforms[i];
            for (j in 0...uniformArray.length) {
                var uniform:Dynamic = uniformArray[j];
                if (hasUniformChanged(uniform, i, j, cache)) {
                    var offset:Int = uniform.__offset;

                    var values:Array<Dynamic> = uniform.value;
                    var arrayOffset:Int = 0;

                    for (k in 0...values.length) {
                        var value:Dynamic = values[k];
                        var info:Dynamic = getUniformSize(value);

                        if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
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

    private function hasUniformChanged(uniform:Dynamic, index:Int, indexArray:Int, cache:Dynamic):Bool {
        var value:Dynamic = uniform.value;
        var indexString:String = index + '_' + indexArray;

        if (!cache.exists(indexString)) {
            if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
                cache[indexString] = value;
            } else {
                cache[indexString] = value.clone();
            }

            return true;
        } else {
            var cachedObject:Dynamic = cache[indexString];

            if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
                if (cachedObject != value) {
                    cache[indexString] = value;
                    return true;
                }
            } else {
                if (!cachedObject.equals(value)) {
                    cachedObject.copy(value);
                    return true;
                }
            }

            return false;
        }
    }

    private function prepareUniformsGroup(uniformsGroup:Dynamic):Void {
        var uniforms:Array<Dynamic> = uniformsGroup.uniforms;
        var offset:Int = 0;

        for (i in 0...uniforms.length) {
            var uniformArray:Array<Dynamic> = uniforms[i];
            for (j in 0...uniformArray.length) {
                var uniform:Dynamic = uniformArray[j];
                var values:Array<Dynamic> = uniform.value;
                for (k in 0...values.length) {
                    var value:Dynamic = values[k];
                    var info:Dynamic = getUniformSize(value);

                    // Calculate the chunk offset
                    var chunkOffsetUniform:Int = offset % 16;

                    // Check for chunk overflow
                    if (chunkOffsetUniform != 0 && (16 - chunkOffsetUniform) < info.boundary) {
                        offset += (16 - chunkOffsetUniform);
                    }

                    uniform.__data = new Float32Array(info.storage / Float32Array.BYTES_PER_ELEMENT);
                    uniform.__offset = offset;

                    offset += info.storage;
                }
            }
        }

        // ensure correct final padding
        var chunkOffset:Int = offset % 16;
        if (chunkOffset > 0) offset += (16 - chunkOffset);

        uniformsGroup.__size = offset;
        uniformsGroup.__cache = {};
    }

    private function getUniformSize(value:Dynamic):Dynamic {
        var info:Dynamic = {
            boundary: 0, // bytes
            storage: 0 // bytes
        };

        if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
            info.boundary = 4;
            info.storage = 4;
        } else if (value.isVector2) {
            info.boundary = 8;
            info.storage = 8;
        } else if (value.isVector3 || value.isColor) {
            info.boundary = 16;
            info.storage = 12;
        } else if (value.isVector4) {
            info.boundary = 16;
            info.storage = 16;
        } else if (value.isMatrix3) {
            info.boundary = 48;
            info.storage = 48;
        } else if (value.isMatrix4) {
            info.boundary = 64;
            info.storage = 64;
        } else if (value.isTexture) {
            trace('THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.');
        } else {
            trace('THREE.WebGLRenderer: Unsupported uniform value type.', value);
        }

        return info;
    }

    private function onUniformsGroupsDispose(event:Dynamic):Void {
        var uniformsGroup:Dynamic = event.target;
        uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);

        var index:Int = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
        allocatedBindingPoints.splice(index, 1);

        gl.deleteBuffer(buffers[uniformsGroup.id]);

        delete buffers[uniformsGroup.id];
        delete updateList[uniformsGroup.id];
    }

    public function dispose():Void {
        for (id in buffers.keys()) {
            gl.deleteBuffer(buffers[id]);
        }

        allocatedBindingPoints = new Array<Int>();
        buffers = new Map<String, WebGLBuffer>();
        updateList = new Map<String, Int>();
    }
}