import three.js.examples.jsm.core.Node;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.core.constants;
import three.js.examples.jsm.core.NodeUtils;
import three.js.examples.jsm.utils.ArrayElementNode;
import three.js.examples.jsm.nodes.accessors.BufferNode;

class UniformsElementNode extends ArrayElementNode {

	public var isArrayBufferElementNode:Bool = true;

	public function new(arrayBuffer:BufferNode, indexNode:ShaderNode) {
		super(arrayBuffer, indexNode);
	}

	public function getNodeType(builder:ShaderNode):String {
		return node.getElementType(builder);
	}

	public function generate(builder:ShaderNode):String {
		var snippet = super.generate(builder);
		var type = getNodeType();
		return builder.format(snippet, 'vec4', type);
	}
}

class UniformsNode extends BufferNode {

	public var array:Array<Dynamic>;
	public var elementType:String;
	public var _elementType:String;
	public var _elementLength:Int;
	public var updateType:NodeUpdateType = NodeUpdateType.RENDER;
	public var isArrayBufferNode:Bool = true;

	public function new(value:Array<Dynamic>, elementType:String = null) {
		super(null, 'vec4');

		this.array = value;
		this.elementType = elementType;

		this._elementType = null;
		this._elementLength = 0;

		this.updateType = NodeUpdateType.RENDER;

		this.isArrayBufferNode = true;
	}

	public function getElementType():String {
		return this.elementType || this._elementType;
	}

	public function getElementLength():Int {
		return this._elementLength;
	}

	public function update(frame:ShaderNode) {
		var { array, value } = this;

		var elementLength = this.getElementLength();
		var elementType = this.getElementType();

		if (elementLength === 1) {
			for (i in 0...array.length) {
				var index = i * 4;
				value[index] = array[i];
			}
		} else if (elementType === 'color') {
			for (i in 0...array.length) {
				var index = i * 4;
				var vector = array[i];
				value[index] = vector.r;
				value[index + 1] = vector.g;
				value[index + 2] = vector.b || 0;
				//value[ index + 3 ] = vector.a || 0;
			}
		} else {
			for (i in 0...array.length) {
				var index = i * 4;
				var vector = array[i];
				value[index] = vector.x;
				value[index + 1] = vector.y;
				value[index + 2] = vector.z || 0;
				value[index + 3] = vector.w || 0;
			}
		}
	}

	public function setup(builder:ShaderNode) {
		var length = this.array.length;

		this._elementType = this.elementType === null ? NodeUtils.getValueType(this.array[0]) : this.elementType;
		this._elementLength = builder.getTypeLength(this._elementType);

		this.value = new Float32Array(length * 4);
		this.bufferCount = length;

		return super.setup(builder);
	}

	public function element(indexNode:ShaderNode):ShaderNode {
		return new UniformsElementNode(this, indexNode);
	}
}

Node.addNodeClass('UniformsNode', UniformsNode);