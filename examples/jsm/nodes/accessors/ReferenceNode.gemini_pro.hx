import Node from '../core/Node.hx';
import NodeUpdateType from '../core/constants.hx';
import UniformNode from '../core/UniformNode.hx';
import TextureNode from './TextureNode.hx';
import BufferNode from './BufferNode.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';
import UniformsNode from './UniformsNode.hx';
import ArrayElementNode from '../utils/ArrayElementNode.hx';

class ReferenceElementNode extends ArrayElementNode {

	public var referenceNode:ReferenceNode;

	public function new(referenceNode:ReferenceNode, indexNode:Node) {
		super(referenceNode, indexNode);
		this.referenceNode = referenceNode;
		this.isReferenceElementNode = true;
	}

	public function getNodeType():String {
		return this.referenceNode.uniformType;
	}

	public function generate(builder:Dynamic):String {
		var snippet = super.generate(builder);
		var arrayType = this.referenceNode.getNodeType();
		var elementType = this.getNodeType();
		return builder.format(snippet, arrayType, elementType);
	}

}

class ReferenceNode extends Node {

	public var property:String;
	public var uniformType:String;
	public var object:Dynamic;
	public var count:Null<Int>;
	public var properties:Array<String>;
	public var reference:Dynamic;
	public var node:Node;

	public function new(property:String, uniformType:String, object:Dynamic = null, count:Null<Int> = null) {
		super();
		this.property = property;
		this.uniformType = uniformType;
		this.object = object;
		this.count = count;
		this.properties = property.split('.');
		this.reference = null;
		this.node = null;
		this.updateType = NodeUpdateType.OBJECT;
	}

	public function element(indexNode:Node):Node {
		return nodeObject(new ReferenceElementNode(this, nodeObject(indexNode)));
	}

	public function setNodeType(uniformType:String):Void {
		var node:Node = null;
		if (this.count != null) {
			node = buffer(null, uniformType, this.count);
		} else if (Std.is(this.getValueFromReference(), Array)) {
			node = uniforms(null, uniformType);
		} else if (uniformType == "texture") {
			node = texture(null);
		} else {
			node = uniform(null, uniformType);
		}
		this.node = node;
	}

	public function getNodeType(builder:Dynamic):String {
		return this.node.getNodeType(builder);
	}

	public function getValueFromReference(object:Dynamic = this.reference):Dynamic {
		var properties = this.properties;
		var value = object[properties[0]];
		for (i in 1...properties.length) {
			value = value[properties[i]];
		}
		return value;
	}

	public function updateReference(state:Dynamic):Dynamic {
		this.reference = if (this.object != null) this.object else state.object;
		return this.reference;
	}

	public function setup():Node {
		this.updateValue();
		return this.node;
	}

	public function update(/*frame:Int*/):Void {
		this.updateValue();
	}

	public function updateValue():Void {
		if (this.node == null) this.setNodeType(this.uniformType);
		var value = this.getValueFromReference();
		if (Std.is(value, Array)) {
			this.node.array = value;
		} else {
			this.node.value = value;
		}
	}

}

class ReferenceNodeTools {
	public static function reference(name:String, type:String, object:Dynamic):Node {
		return nodeObject(new ReferenceNode(name, type, object));
	}
	public static function referenceBuffer(name:String, type:String, count:Int, object:Dynamic):Node {
		return nodeObject(new ReferenceNode(name, type, object, count));
	}
}

export var ReferenceNode = ReferenceNode;
export var reference = ReferenceNodeTools.reference;
export var referenceBuffer = ReferenceNodeTools.referenceBuffer;

addNodeClass("ReferenceNode", ReferenceNode);