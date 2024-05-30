import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.core.NodeUtils;
import three.js.examples.jsm.nodes.utils.ArrayElementNode;
import three.js.examples.jsm.nodes.nodes.BufferNode;

class UniformsElementNode extends ArrayElementNode {

	public function new(arrayBuffer:ArrayBuffer, indexNode:IndexNode) {
		super(arrayBuffer, indexNode);
		this.isArrayBufferElementNode = true;
	}

	public function getNodeType(builder:Builder):String {
		return this.node.getElementType(builder);
	}

	public function generate(builder:Builder):String {
		var snippet = super.generate(builder);
		var type = this.getNodeType();
		return builder.format(snippet, 'vec4', type);
	}

}

class UniformsNode extends BufferNode {

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

	public function update(frame:Frame) {
		var array = this.array;
		var value = this.value;
		var elementLength = this.getElementLength();
		var elementType = this.getElementType();
		if (elementLength == 1) {
			for (i in 0...array.length) {
				var index = i * 4;
				value[index] = array[i];
			}
		} else if (elementType == 'color') {
			for (i in 0...array.length) {
				var index = i * 4;
				var vector = array[i];
				value[index] = vector.r;
				value[index + 1] = vector.g;
				value[index + 2] = vector.b || 0;
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

	public function setup(builder:Builder):Dynamic {
		var length = this.array.length;
		this._elementType = this.elementType == null ? NodeUtils.getValueType(this.array[0]) : this.elementType;
		this._elementLength = builder.getTypeLength(this._elementType);
		this.value = new Float32Array(length * 4);
		this.bufferCount = length;
		return super.setup(builder);
	}

	public function element(indexNode:IndexNode):Dynamic {
		return Node.nodeObject(new UniformsElementNode(this, Node.nodeObject(indexNode)));
	}

}

static function uniforms(values:Array<Dynamic>, nodeType:String):Dynamic {
	return Node.nodeObject(new UniformsNode(values, nodeType));
}

Node.addNodeClass('UniformsNode', UniformsNode);