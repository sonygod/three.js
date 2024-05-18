import gltf.GLTF;
import gltf.GLTFResource;
import gltf.attribute.Attribute;
import gltf.attribute.AttributeType;
import gltf.attribute.InterleavedBufferAttribute;
import gltf.attribute.InstancedBufferAttribute;
import gltf.attribute.InstancedInterleavedBufferAttribute;
import gltf.attribute.StandardBufferAttribute;
import gltf.buffer.BufferView;
import gltf.math.Matrix4x4;
import gltf.math.Vector4;
import js.Js;
import js.html.CanvasRenderingContext2D;
import js.html.WebGLBuffer;
import js.html.WebGLProgram;
import js.html.WebGLRenderingContext;
import js.html.WebGLVertexArrayObject;

class WebGLBindingStates {

	private static const MAX_VERTEX_ATTRIBUTES:Int = 32;

	private var _gl:WebGLRenderingContext;
	private var _attributes:Map<Int, WebGLBuffer>;
	private var _bindingStates:Map<Int, Map<Int, Map<Bool, BindingState>>>;
	private var _currentState:BindingState;
	private var _defaultState:BindingState;
	private var _forceUpdate:Bool;

	public function new(gl:WebGLRenderingContext, attributes:Map<Int, WebGLBuffer>) {
		this._gl = gl;
		this._attributes = attributes;
		this._bindingStates = new Map();
		this._defaultState = createBindingState(null);
		this._currentState = this._defaultState;
		this._forceUpdate = false;
	}

	private function createBindingState(vao:WebGLVertexArrayObject):BindingState {
		return {
			geometry: null,
			program: null,
			wireframe: false,
			newAttributes: new Array<Int>(MAX_VERTEX_ATTRIBUTES),
			enabledAttributes: new Array<Int>(MAX_VERTEX_ATTRIBUTES),
			attributeDivisors: new Array<Int>(MAX_VERTEX_ATTRIBUTES),
			object: vao,
			attributes: new Map<String, Attribute>(),
			index: null
		};
	}

	private function getBindingState(geometry:GLTFResource, program:WebGLProgram, material:GLTF.Material):BindingState {
		// ... implementation of the getBindingState method
	}

	public function setup(object:Dynamic, material:GLTF.Material, program:WebGLProgram, geometry:GLTFResource, index:Int) {
		// ... implementation of the setup method
	}

	public function createVertexArrayObject():WebGLVertexArrayObject {
		return this._gl.createVertexArray();
	}

	public function bindVertexArrayObject(vao:WebGLVertexArrayObject) {
		this._gl.bindVertexArray(vao);
	}

	public function deleteVertexArrayObject(vao:WebGLVertexArrayObject) {
		this._gl.deleteVertexArray(vao);
	}

	// ... implementation of the other methods

}