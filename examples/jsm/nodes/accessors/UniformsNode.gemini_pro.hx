import core.Node;
import shadernode.ShaderNode;
import core.constants.NodeUpdateType;
import core.NodeUtils;
import utils.ArrayElementNode;
import BufferNode;

class UniformsElementNode extends ArrayElementNode {

	public var isArrayBufferElementNode:Bool = true;

	public function new(arrayBuffer:BufferNode, indexNode:ShaderNode) {
		super(arrayBuffer, indexNode);
	}

	public function getNodeType(builder:ShaderNode):String {
		return this.node.getElementType(builder);
	}

	public function generate(builder:ShaderNode):String {
		var snippet = super.generate(builder);
		var type = this.getNodeType(builder);
		return builder.format(snippet, 'vec4', type);
	}

}

class UniformsNode extends BufferNode {

	public var array:Array<Dynamic>;
	public var elementType:String;

	private var _elementType:String;
	private var _elementLength:Int;

	public var updateType:NodeUpdateType = NodeUpdateType.RENDER;

	public var isArrayBufferNode:Bool = true;

	public function new(value:Array<Dynamic>, elementType:String = null) {
		super(null, 'vec4');
		this.array = value;
		this.elementType = elementType;
	}

	public function getElementType():String {
		return this.elementType != null ? this.elementType : this._elementType;
	}

	public function getElementLength():Int {
		return this._elementLength;
	}

	public function update(frame:Dynamic) {
		var array = this.array;
		var value = this.value;
		var elementLength = this.getElementLength();
		var elementType = this.getElementType();

		if (elementLength == 1) {
			for (i in 0...array.length) {
				value[i * 4] = array[i];
			}
		} else if (elementType == 'color') {
			for (i in 0...array.length) {
				var index = i * 4;
				var vector = array[i];
				value[index] = vector.r;
				value[index + 1] = vector.g;
				value[index + 2] = vector.b != null ? vector.b : 0;
				//value[index + 3] = vector.a != null ? vector.a : 0;
			}
		} else {
			for (i in 0...array.length) {
				var index = i * 4;
				var vector = array[i];
				value[index] = vector.x;
				value[index + 1] = vector.y;
				value[index + 2] = vector.z != null ? vector.z : 0;
				value[index + 3] = vector.w != null ? vector.w : 0;
			}
		}
	}

	public function setup(builder:ShaderNode):ShaderNode {
		var length = this.array.length;

		this._elementType = this.elementType == null ? NodeUtils.getValueType(this.array[0]) : this.elementType;
		this._elementLength = builder.getTypeLength(this._elementType);

		this.value = new Float32Array(length * 4);
		this.bufferCount = length;

		return super.setup(builder);
	}

	public function element(indexNode:ShaderNode):ShaderNode {
		return ShaderNode.nodeObject(new UniformsElementNode(this, ShaderNode.nodeObject(indexNode)));
	}

}

class UniformsNodeStatic {
	public static function uniforms(values:Array<Dynamic>, nodeType:String):ShaderNode {
		return ShaderNode.nodeObject(new UniformsNode(values, nodeType));
	}
}

Node.addNodeClass('UniformsNode', UniformsNode);

export { UniformsNode, UniformsNodeStatic };