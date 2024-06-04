import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.Float32Array;
import haxe.io.UInt8Array;
import core.constants.NodeUpdateType;
import core.Node;
import core.NodeUtils;
import core.NodeObject;
import utils.ArrayElementNode;
import shadernode.ShaderNode;
import BufferNode;

class UniformsElementNode extends ArrayElementNode {
	public var isArrayBufferElementNode:Bool = true;

	public function new(arrayBuffer:NodeObject, indexNode:NodeObject) {
		super(arrayBuffer, indexNode);
	}

	public function getNodeType(builder:Dynamic):String {
		return this.node.getElementType(builder);
	}

	public function generate(builder:Dynamic):String {
		var snippet = super.generate(builder);
		var type = this.getNodeType();
		return builder.format(snippet, 'vec4', type);
	}
}

class UniformsNode extends BufferNode {

	public var array:Vector<Dynamic>;
	public var elementType:String;

	public var _elementType:String;
	public var _elementLength:Int;

	public function new(value:Vector<Dynamic>, elementType:String = null) {
		super(null, 'vec4');
		this.array = value;
		this.elementType = elementType;
		this._elementType = null;
		this._elementLength = 0;
		this.updateType = NodeUpdateType.RENDER;
		this.isArrayBufferNode = true;
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
				var index = i * 4;
				value[index] = array[i];
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

	public function setup(builder:Dynamic):Dynamic {
		var length = this.array.length;
		this._elementType = this.elementType == null ? NodeUtils.getValueType(this.array[0]) : this.elementType;
		this._elementLength = builder.getTypeLength(this._elementType);
		this.value = new Float32Array(length * 4);
		this.bufferCount = length;
		return super.setup(builder);
	}

	public function element(indexNode:NodeObject):NodeObject {
		return ShaderNode.nodeObject(new UniformsElementNode(this, ShaderNode.nodeObject(indexNode)));
	}
}

function uniforms(values:Vector<Dynamic>, nodeType:String):NodeObject {
	return ShaderNode.nodeObject(new UniformsNode(values, nodeType));
}

Node.addNodeClass('UniformsNode', UniformsNode);