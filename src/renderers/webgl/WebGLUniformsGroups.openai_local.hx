package three.renderers.webgl;

import js.html.WebGLRenderingContext;
import js.html.WebGLProgram;
import js.html.WebGLBuffer;
import js.Browser;
import three.renderers.WebGLState;
import three.core.Event;
import three.core.EventDispatcher;
import three.utils.Info;

class WebGLUniformsGroups {
    
    var gl:WebGLRenderingContext;
    var info:Info;
    var capabilities:Dynamic;
    var state:WebGLState;
    
    var buffers:Map<Int, WebGLBuffer> = new Map();
    var updateList:Map<Int, Int> = new Map();
    var allocatedBindingPoints:Array<Int> = [];
    
    var maxBindingPoints:Int;

    public function new(gl:WebGLRenderingContext, info:Info, capabilities:Dynamic, state:WebGLState) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;

        this.maxBindingPoints = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS);
    }

    public function bind(uniformsGroup:Dynamic, program:Dynamic):Void {
        var webglProgram:WebGLProgram = program.program;
        state.uniformBlockBinding(uniformsGroup, webglProgram);
    }

    public function update(uniformsGroup:Dynamic, program:Dynamic):Void {
        var buffer:WebGLBuffer = buffers.get(uniformsGroup.id);

        if (buffer == null) {
            prepareUniformsGroup(uniformsGroup);
            buffer = createBuffer(uniformsGroup);
            buffers.set(uniformsGroup.id, buffer);
            uniformsGroup.addEventListener("dispose", onUniformsGroupsDispose);
        }

        var webglProgram:WebGLProgram = program.program;
        state.updateUBOMapping(uniformsGroup, webglProgram);

        var frame:Int = info.render.frame;
        if (updateList.get(uniformsGroup.id) != frame) {
            updateBufferData(uniformsGroup);
            updateList.set(uniformsGroup.id, frame);
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
        trace("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.");
        return 0;
    }

    private function updateBufferData(uniformsGroup:Dynamic):Void {
        var buffer:WebGLBuffer = buffers.get(uniformsGroup.id);
        var uniforms:Array<Dynamic> = uniformsGroup.uniforms;
        var cache:Map<String, Dynamic> = uniformsGroup.__cache;

        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);

        for (i in 0...uniforms.length) {
            var uniformArray:Array<Dynamic> = if (Std.is(uniforms[i], Array)) uniforms[i] else [uniforms[i]];

            for (j in 0...uniformArray.length) {
                var uniform:Dynamic = uniformArray[j];

                if (hasUniformChanged(uniform, i, j, cache)) {
                    var offset:Int = uniform.__offset;
                    var values:Array<Dynamic> = if (Std.is(uniform.value, Array)) uniform.value else [uniform.value];
                    var arrayOffset:Int = 0;

                    for (k in 0...values.length) {
                        var value:Dynamic = values[k];
                        var info:Dynamic = getUniformSize(value);

                        if (Std.is(value, Int) || Std.is(value, Bool)) {
                            uniform.__data[0] = value;
                            gl.bufferSubData(gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);
                        } else if (value.isMatrix3) {
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

    private function hasUniformChanged(uniform:Dynamic, index:Int, indexArray:Int, cache:Map<String, Dynamic>):Bool {
        var value:Dynamic = uniform.value;
        var indexString:String = index + "_" + indexArray;

        if (cache.get(indexString) == null) {
            if (Std.is(value, Int) || Std.is(value, Bool)) {
                cache.set(indexString, value);
            } else {
                cache.set(indexString, value.clone());
            }
            return true;
        } else {
            var cachedObject:Dynamic = cache.get(indexString);
            if (Std.is(value, Int) || Std.is(value, Bool)) {
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

    private function prepareUniformsGroup(uniformsGroup:Dynamic):Void {
        var uniforms:Array<Dynamic> = uniformsGroup.uniforms;

        var offset:Int = 0;
        var chunkSize:Int = 16;

        for (i in 0...uniforms.length) {
            var uniformArray:Array<Dynamic> = if (Std.is(uniforms[i], Array)) uniforms[i] else [uniforms[i]];

            for (j in 0...uniformArray.length) {
                var uniform:Dynamic = uniformArray[j];
                var values:Array<Dynamic> = if (Std.is(uniform.value, Array)) uniform.value else [uniform.value];

                for (k in 0...values.length) {
                    var value:Dynamic = values[k];
                    var info:Dynamic = getUniformSize(value);
                    var chunkOffsetUniform:Int = offset % chunkSize;

                    if (chunkOffsetUniform != 0 && (chunkSize - chunkOffsetUniform) < info.boundary) {
                        offset += (chunkSize - chunkOffsetUniform);
                    }

                    uniform.__data = new Float32Array(info.storage / Float32Array.BYTES_PER_ELEMENT);
                    uniform.__offset = offset;
                    offset += info.storage;
                }
            }
        }

        var chunkOffset:Int = offset % chunkSize;
        if (chunkOffset > 0) offset += (chunkSize - chunkOffset);

        uniformsGroup.__size = offset;
        uniformsGroup.__cache = new Map<String, Dynamic>();
    }

    private function getUniformSize(value:Dynamic):Dynamic {
        var info:Dynamic = {
            boundary: 0,
            storage: 0
        };

        if (Std.is(value, Int) || Std.is(value, Bool)) {
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
            trace("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.");
        } else {
            trace("THREE.WebGLRenderer: Unsupported uniform value type.", value);
        }

        return info;
    }

    private function onUniformsGroupsDispose(event:Event):Void {
        var uniformsGroup:Dynamic = event.target;
        uniformsGroup.removeEventListener("dispose", onUniformsGroupsDispose);
        var index:Int = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
        allocatedBindingPoints.splice(index, 1);
        gl.deleteBuffer(buffers.get(uniformsGroup.id));
        buffers.remove(uniformsGroup.id);
        updateList.remove(uniformsGroup.id);
    }

    public function dispose():Void {
        for (id in buffers.keys()) {
            gl.deleteBuffer(buffers.get(id));
        }
        allocatedBindingPoints = [];
        buffers = new Map();
        updateList = new Map();
    }
}