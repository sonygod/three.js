package three.js.src.renderers.webgl;

import three.constants.IntType;

class WebGLBindingStates {
    private var gl:WebGLRenderingContext;
    private var attributes:Dynamic;
    private var maxVertexAttributes:Int;
    private var bindingStates:Map<String, Dynamic>;
    private var defaultState:BindingState;
    private var currentState:BindingState;
    private var forceUpdate:Bool;

    public function new(gl:WebGLRenderingContext, attributes:Dynamic) {
        this.gl = gl;
        this.attributes = attributes;
        this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
        this.bindingStates = new Map<String, Dynamic>();
        this.defaultState = createBindingState(null);
        this.currentState = defaultState;
        this.forceUpdate = false;
    }

    public function setup(object:Dynamic, material:Dynamic, program:Dynamic, geometry:Dynamic, index:Null<Int>) {
        // ... (rest of the code remains the same)
    }

    // ... (rest of the code remains the same)

    private function createVertexArrayObject():WebGLVertexArrayObject {
        return gl.createVertexArray();
    }

    private function bindVertexArrayObject(vao:WebGLVertexArrayObject) {
        return gl.bindVertexArray(vao);
    }

    private function deleteVertexArrayObject(vao:WebGLVertexArrayObject) {
        return gl.deleteVertexArray(vao);
    }

    // ... (rest of the code remains the same)

    public function dispose() {
        reset();
        for (geometryId in bindingStates.keys()) {
            var programMap = bindingStates.get(geometryId);
            for (programId in programMap.keys()) {
                var stateMap = programMap.get(programId);
                for (wireframe in stateMap.keys()) {
                    deleteVertexArrayObject(stateMap.get(wireframe).object);
                    stateMap.remove(wireframe);
                }
                programMap.remove(programId);
            }
            bindingStates.remove(geometryId);
        }
    }

    public function releaseStatesOfGeometry(geometry:Dynamic) {
        if (!bindingStates.exists(geometry.id)) return;
        var programMap = bindingStates.get(geometry.id);
        for (programId in programMap.keys()) {
            var stateMap = programMap.get(programId);
            for (wireframe in stateMap.keys()) {
                deleteVertexArrayObject(stateMap.get(wireframe).object);
                stateMap.remove(wireframe);
            }
            programMap.remove(programId);
        }
        bindingStates.remove(geometry.id);
    }

    public function releaseStatesOfProgram(program:Dynamic) {
        for (geometryId in bindingStates.keys()) {
            var programMap = bindingStates.get(geometryId);
            if (!programMap.exists(program.id)) continue;
            var stateMap = programMap.get(program.id);
            for (wireframe in stateMap.keys()) {
                deleteVertexArrayObject(stateMap.get(wireframe).object);
                stateMap.remove(wireframe);
            }
            programMap.remove(program.id);
        }
    }

    public function reset() {
        resetDefaultState();
        forceUpdate = true;
        if (currentState == defaultState) return;
        currentState = defaultState;
        bindVertexArrayObject(currentState.object);
    }

    private function resetDefaultState() {
        defaultState.geometry = null;
        defaultState.program = null;
        defaultState.wireframe = false;
    }
}

typedef BindingState = {
    geometry:Null<Dynamic>,
    program:Null<Dynamic>,
    wireframe:Bool,
    newAttributes:Array<Int>,
    enabledAttributes:Array<Int>,
    attributeDivisors:Array<Int>,
    object:WebGLVertexArrayObject,
    attributes:Map<String, Dynamic>,
    index:Null<Int>,
    attributesNum:Int
}

// Export the class
#if js
extern class WebGLBindingStates {
#else
extern class WebGLBindingStates extends WebGLBindingStatesImpl {
#end
}