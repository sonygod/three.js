import js.html.WebGLRenderingContext;
import js.html.WebGLProgram;
import js.html.WebGLUniformLocation;

class WebGLUniformsGroups {
    private var gl: WebGLRenderingContext;
    private var info: Info;
    private var capabilities: Capabilities;
    private var state: State;

    private var buffers: haxe.ds.StringMap<WebGLBuffer> = new haxe.ds.StringMap<WebGLBuffer>();
    private var updateList: haxe.ds.StringMap<Int> = new haxe.ds.StringMap<Int>();
    private var allocatedBindingPoints: Array<Int> = [];

    private var maxBindingPoints: Int;

    public function new(gl: WebGLRenderingContext, info: Info, capabilities: Capabilities, state: State) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;
        this.maxBindingPoints = gl.getParameter(WebGLRenderingContext.MAX_UNIFORM_BUFFER_BINDINGS);
    }

    public function bind(uniformsGroup: UniformsGroup, program: Program): Void {
        var webglProgram: WebGLProgram = program.program;
        state.uniformBlockBinding(uniformsGroup, webglProgram);
    }

    public function update(uniformsGroup: UniformsGroup, program: Program): Void {
        var buffer: WebGLBuffer = buffers.get(uniformsGroup.id);

        if (buffer == null) {
            prepareUniformsGroup(uniformsGroup);
            buffer = createBuffer(uniformsGroup);
            buffers.set(uniformsGroup.id, buffer);
            uniformsGroup.addEventListener("dispose", onUniformsGroupsDispose);
        }

        var webglProgram: WebGLProgram = program.program;
        state.updateUBOMapping(uniformsGroup, webglProgram);

        var frame: Int = info.render.frame;

        if (updateList.get(uniformsGroup.id) != frame) {
            updateBufferData(uniformsGroup);
            updateList.set(uniformsGroup.id, frame);
        }
    }

    private function createBuffer(uniformsGroup: UniformsGroup): WebGLBuffer {
        var bindingPointIndex: Int = allocateBindingPointIndex();
        uniformsGroup.__bindingPointIndex = bindingPointIndex;

        var buffer: WebGLBuffer = gl.createBuffer();
        var size: Int = uniformsGroup.__size;
        var usage: Int = uniformsGroup.usage;

        gl.bindBuffer(WebGLRenderingContext.UNIFORM_BUFFER, buffer);
        gl.bufferData(WebGLRenderingContext.UNIFORM_BUFFER, size, usage);
        gl.bindBuffer(WebGLRenderingContext.UNIFORM_BUFFER, null);
        gl.bindBufferBase(WebGLRenderingContext.UNIFORM_BUFFER, bindingPointIndex, buffer);

        return buffer;
    }

    private function allocateBindingPointIndex(): Int {
        for (var i: Int = 0; i < maxBindingPoints; i++) {
            if (allocatedBindingPoints.indexOf(i) == -1) {
                allocatedBindingPoints.push(i);
                return i;
            }
        }

        js.Browser.console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.");
        return 0;
    }

    private function updateBufferData(uniformsGroup: UniformsGroup): Void {
        var buffer: WebGLBuffer = buffers.get(uniformsGroup.id);
        var uniforms: Array<Uniform> = uniformsGroup.uniforms;
        var cache: haxe.ds.StringMap<Dynamic> = uniformsGroup.__cache;

        gl.bindBuffer(WebGLRenderingContext.UNIFORM_BUFFER, buffer);

        for (var i: Int = 0; i < uniforms.length; i++) {
            var uniformArray: Array<Uniform> = Array.isArray(uniforms[i]) ? uniforms[i] : [uniforms[i]];

            for (var j: Int = 0; j < uniformArray.length; j++) {
                var uniform: Uniform = uniformArray[j];

                if (hasUniformChanged(uniform, i, j, cache)) {
                    var offset: Int = uniform.__offset;
                    var values: Array<Dynamic> = Array.isArray(uniform.value) ? uniform.value : [uniform.value];

                    var arrayOffset: Int = 0;

                    for (var k: Int = 0; k < values.length; k++) {
                        var value: Dynamic = values[k];
                        var info: Info = getUniformSize(value);

                        if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
                            uniform.__data[0] = value;
                            gl.bufferSubData(WebGLRenderingContext.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data);
                        } else if (Std.isOfType(value, Matrix3)) {
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
                            arrayOffset += info.storage / 4;
                        }
                    }

                    gl.bufferSubData(WebGLRenderingContext.UNIFORM_BUFFER, offset, uniform.__data);
                }
            }
        }

        gl.bindBuffer(WebGLRenderingContext.UNIFORM_BUFFER, null);
    }

    private function hasUniformChanged(uniform: Uniform, index: Int, indexArray: Int, cache: haxe.ds.StringMap<Dynamic>): Bool {
        var value: Dynamic = uniform.value;
        var indexString: String = index + "_" + indexArray;

        if (cache.get(indexString) == null) {
            if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
                cache.set(indexString, value);
            } else {
                cache.set(indexString, value.clone());
            }

            return true;
        } else {
            var cachedObject: Dynamic = cache.get(indexString);

            if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
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

    private function prepareUniformsGroup(uniformsGroup: UniformsGroup): Void {
        var uniforms: Array<Uniform> = uniformsGroup.uniforms;
        var offset: Int = 0;
        var chunkSize: Int = 16;

        for (var i: Int = 0; i < uniforms.length; i++) {
            var uniformArray: Array<Uniform> = Array.isArray(uniforms[i]) ? uniforms[i] : [uniforms[i]];

            for (var j: Int = 0; j < uniformArray.length; j++) {
                var uniform: Uniform = uniformArray[j];
                var values: Array<Dynamic> = Array.isArray(uniform.value) ? uniform.value : [uniform.value];

                for (var k: Int = 0; k < values.length; k++) {
                    var value: Dynamic = values[k];
                    var info: Info = getUniformSize(value);

                    var chunkOffsetUniform: Int = offset % chunkSize;

                    if (chunkOffsetUniform != 0 && (chunkSize - chunkOffsetUniform) < info.boundary) {
                        offset += (chunkSize - chunkOffsetUniform);
                    }

                    uniform.__data = new Float32Array(info.storage / 4);
                    uniform.__offset = offset;

                    offset += info.storage;
                }
            }
        }

        var chunkOffset: Int = offset % chunkSize;

        if (chunkOffset > 0) offset += (chunkSize - chunkOffset);

        uniformsGroup.__size = offset;
        uniformsGroup.__cache = new haxe.ds.StringMap<Dynamic>();
    }

    private function getUniformSize(value: Dynamic): Info {
        var info: Info = {boundary: 0, storage: 0};

        if (Std.isOfType(value, Int) || Std.isOfType(value, Bool)) {
            info.boundary = 4;
            info.storage = 4;
        } else if (Std.isOfType(value, Vector2)) {
            info.boundary = 8;
            info.storage = 8;
        } else if (Std.isOfType(value, Vector3) || Std.isOfType(value, Color)) {
            info.boundary = 16;
            info.storage = 12;
        } else if (Std.isOfType(value, Vector4)) {
            info.boundary = 16;
            info.storage = 16;
        } else if (Std.isOfType(value, Matrix3)) {
            info.boundary = 48;
            info.storage = 48;
        } else if (Std.isOfType(value, Matrix4)) {
            info.boundary = 64;
            info.storage = 64;
        } else if (Std.isOfType(value, Texture)) {
            js.Browser.console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.");
        } else {
            js.Browser.console.warn("THREE.WebGLRenderer: Unsupported uniform value type.", value);
        }

        return info;
    }

    private function onUniformsGroupsDispose(event: Event): Void {
        var uniformsGroup: UniformsGroup = event.target;
        uniformsGroup.removeEventListener("dispose", onUniformsGroupsDispose);

        var index: Int = allocatedBindingPoints.indexOf(uniformsGroup.__bindingPointIndex);
        allocatedBindingPoints.splice(index, 1);

        gl.deleteBuffer(buffers.get(uniformsGroup.id));

        buffers.remove(uniformsGroup.id);
        updateList.remove(uniformsGroup.id);
    }

    public function dispose(): Void {
        for (key in buffers.keys()) {
            gl.deleteBuffer(buffers.get(key));
        }

        allocatedBindingPoints = [];
        buffers = new haxe.ds.StringMap<WebGLBuffer>();
        updateList = new haxe.ds.StringMap<Int>();
    }
}