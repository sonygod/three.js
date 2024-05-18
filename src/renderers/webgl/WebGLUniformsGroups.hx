package renderers.webgl;

import openfl.display.GLBuffer;
import openfl.display.GLProgram;
import openfl.display.GL;
import openfl.display3D.Context3D;
import openfl.events.EventDispatcher;

class WebGLUniformsGroups {
    private var gl:GL;
    private var info:Dynamic;
    private var capabilities:Dynamic;
    private var state:Dynamic;
    private var buffers:Map<String, GLBuffer>;
    private var updateList:Map<String, Int>;
    private var allocatedBindingPoints:Array<Int>;
    private var maxBindingPoints:Int;

    public function new(gl:GL, info:Dynamic, capabilities:Dynamic, state:Dynamic) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;
        this.buffers = new Map<String, GLBuffer>();
        this.updateList = new Map<String, Int>();
        this.allocatedBindingPoints = [];
        this.maxBindingPoints = gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS);
    }

    private function bind(uniformsGroup:Dynamic, program:Dynamic):Void {
        const webglProgram:GLProgram = program.program;
        state.uniformBlockBinding(uniformsGroup, webglProgram);
    }

    private function update(uniformsGroup:Dynamic, program:Dynamic):Void {
        var buffer:GLBuffer = buffers[uniformsGroup.id];
        if (buffer == null) {
            prepareUniformsGroup(uniformsGroup);
            buffer = createBuffer(uniformsGroup);
            buffers[uniformsGroup.id] = buffer;
            uniformsGroup.addEventListener('dispose', onUniformsGroupsDispose);
        }
        const webglProgram:GLProgram = program.program;
        state.updateUBOMapping(uniformsGroup, webglProgram);
        const frame:Int = info.render.frame;
        if (updateList[uniformsGroup.id] != frame) {
            updateBufferData(uniformsGroup);
            updateList[uniformsGroup.id] = frame;
        }
    }

    private function createBuffer(uniformsGroup:Dynamic):GLBuffer {
        const bindingPointIndex:Int = allocateBindingPointIndex();
        uniformsGroup.__bindingPointIndex = bindingPointIndex;
        const buffer:GLBuffer = gl.createBuffer();
        const size:Int = uniformsGroup.__size;
        const usage:Int = uniformsGroup.usage;
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
        const buffer:GLBuffer = buffers[uniformsGroup.id];
        const uniforms:Array<Dynamic> = uniformsGroup.uniforms;
        const cache:Dynamic = uniformsGroup.__cache;
        gl.bindBuffer(gl.UNIFORM_BUFFER, buffer);
        for (i in 0...uniforms.length) {
            const uniformArray:Array<Dynamic> = uniforms[i];
            for (j in 0...uniformArray.length) {
                const uniform:Dynamic = uniformArray[j];
                if (hasUniformChanged(uniform, i, j, cache)) {
                    const offset:Int = uniform.__offset;
                    const values:Array<Dynamic> = uniform.value;
                    let arrayOffset:Int = 0;
                    for (k in 0...values.length) {
                        const value:Dynamic = values[k];
                        const info:Dynamic = getUniformSize(value);
                        if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
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
        const value:Dynamic = uniform.value;
        const indexString:String = index + '_' + indexArray;
        if (!cache.exists(indexString)) {
            // cache entry does not exist so far
            if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
                cache[indexString] = value;
            } else {
                cache[indexString] = value.clone();
            }
            return true;
        } else {
            const cachedObject:Dynamic = cache[indexString];
            // compare current value with cached entry
            if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
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
        }
        return false;
    }

    private function prepareUniformsGroup(uniformsGroup:Dynamic):Void {
        const uniforms:Array<Dynamic> = uniformsGroup.uniforms;
        var offset:Int = 0; // global buffer offset in bytes
        const chunkSize:Int = 16; // size of a chunk in bytes
        for (i in 0...uniforms.length) {
            const uniformArray:Array<Dynamic> = uniforms[i];
            for (j in 0...uniformArray.length) {
                const uniform:Dynamic = uniformArray[j];
                const values:Array<Dynamic> = uniform.value;
                for (k in 0...values.length) {
                    const value:Dynamic = values[k];
                    const info:Dynamic = getUniformSize(value);
                    // Calculate the chunk offset
                    const chunkOffsetUniform:Int = offset % chunkSize;
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
        const chunkOffset:Int = offset % chunkSize;
        if (chunkOffset > 0) offset += (chunkSize - chunkOffset);
        uniformsGroup.__size = offset;
        uniformsGroup.__cache = {};
    }

    private function getUniformSize(value:Dynamic):Dynamic {
        const info:Dynamic = {
            boundary: 0, // bytes
            storage: 0 // bytes
        };
        if (Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
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
            trace('THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.');
        } else {
            trace('THREE.WebGLRenderer: Unsupported uniform value type.', value);
        }
        return info;
    }

    private function onUniformsGroupsDispose(event:Event):Void {
        const uniformsGroup:Dynamic = event.target;
        uniformsGroup.removeEventListener('dispose', onUniformsGroupsDispose);
        const index:Int = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
        allocatedBindingPoints.splice(index, 1);
        gl.deleteBuffer(buffers[uniformsGroup.id]);
        delete buffers[uniformsGroup.id];
        delete updateList[uniformsGroup.id];
    }

    public function dispose():Void {
        for (id in buffers.keys()) {
            gl.deleteBuffer(buffers[id]);
        }
        allocatedBindingPoints = [];
        buffers = {};
        updateList = {};
    }
}