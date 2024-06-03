import js.html.WebGLRenderingContext;
import js.html.WebGLVertexArrayObject;
import js.html.WebGLBuffer;
import three.constants.IntType;

class WebGLBindingStates {
    var gl: WebGLRenderingContext;
    var attributes: Attributes; // Assuming Attributes is a defined class
    var maxVertexAttributes: Int;
    var bindingStates: haxe.ds.StringMap<haxe.ds.StringMap<haxe.ds.StringMap<BindingState>>>;
    var defaultState: BindingState;
    var currentState: BindingState;
    var forceUpdate: Bool;

    public function new(gl: WebGLRenderingContext, attributes: Attributes) {
        this.gl = gl;
        this.attributes = attributes;
        this.maxVertexAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
        this.bindingStates = new haxe.ds.StringMap();
        this.defaultState = createBindingState(null);
        this.currentState = this.defaultState;
        this.forceUpdate = false;
    }

    public function setup(object: Dynamic, material: Dynamic, program: Dynamic, geometry: Dynamic, index: Int) {
        var updateBuffers: Bool = false;
        var state: BindingState = getBindingState(geometry, program, material);

        if (this.currentState !== state) {
            this.currentState = state;
            bindVertexArrayObject(this.currentState.object);
        }

        updateBuffers = needsUpdate(object, geometry, program, index);

        if (updateBuffers) {
            saveCache(object, geometry, program, index);
        }

        if (index !== null) {
            this.attributes.update(index, this.gl.ELEMENT_ARRAY_BUFFER);
        }

        if (updateBuffers || this.forceUpdate) {
            this.forceUpdate = false;
            setupVertexAttributes(object, material, program, geometry);

            if (index !== null) {
                this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.attributes.get(index).buffer);
            }
        }
    }

    public function createVertexArrayObject(): WebGLVertexArrayObject {
        return this.gl.createVertexArray();
    }

    public function bindVertexArrayObject(vao: WebGLVertexArrayObject) {
        return this.gl.bindVertexArray(vao);
    }

    public function deleteVertexArrayObject(vao: WebGLVertexArrayObject) {
        return this.gl.deleteVertexArray(vao);
    }

    // Rest of the methods follow similar transformations

    // ...
}