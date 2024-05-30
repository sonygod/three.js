package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.utils.ArrayElementNode;
import three.js.examples.jsm.nodes.core.TextureNode;
import three.js.examples.jsm.nodes.core.BufferNode;
import three.js.examples.jsm.nodes.core.UniformsNode;

class ReferenceElementNode extends ArrayElementNode {

	public var referenceNode:ReferenceNode;
	public var isReferenceElementNode:Bool = true;

	public function new(referenceNode:ReferenceNode, indexNode:Dynamic) {
		super(referenceNode, indexNode);
		this.referenceNode = referenceNode;
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
	public var count:Int;
	public var properties:Array<String>;
	public var reference:Dynamic;
	public var node:Dynamic;
	public var updateType:NodeUpdateType = NodeUpdateType.OBJECT;

	public function new(property:String, uniformType:String, object:Dynamic = null, count:Int = null) {
		super();
		this.property = property;
		this.uniformType = uniformType;
		this.object = object;
		this.count = count;
		this.properties = property.split('.');
	}

	public function element(indexNode:Dynamic):Dynamic {
		return ShaderNode.nodeObject(new ReferenceElementNode(this, ShaderNode.nodeObject(indexNode)));
	}

	public function setNodeType(uniformType:String):Void {
		var node:Dynamic = null;
		if (this.count !== null) {
			node = BufferNode.buffer(null, uniformType, this.count);
		} else if (Std.is(this.getValueFromReference(), Array)) {
			node = UniformsNode.uniforms(null, uniformType);
		} else if (uniformType == 'texture') {
			node = TextureNode.texture(null);
		} else {
			node = UniformNode.uniform(null, uniformType);
		}
		this.node = node;
	}

	public function getNodeType(builder:Dynamic):String {
		return this.node.getNodeType(builder);
	}

	public function getValueFromReference(object:Dynamic = this.reference):Dynamic {
		var value = object[this.properties[0]];
		for (i in 1...this.properties.length) {
			value = value[this.properties[i]];
		}
		return value;
	}

	public function updateReference(state:Dynamic):Dynamic {
		this.reference = this.object !== null ? this.object : state.object;
		return this.reference;
	}

	public function setup():Dynamic {
		this.updateValue();
		return this.node;
	}

	public function update(frame:Dynamic):Void {
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

class ReferenceNodeHelper {

	public static function reference(name:String, type:String, object:Dynamic):Dynamic {
		return ShaderNode.nodeObject(new ReferenceNode(name, type, object));
	}

	public static function referenceBuffer(name:String, type:String, count:Int, object:Dynamic):Dynamic {
		return ShaderNode.nodeObject(new ReferenceNode(name, type, object, count));
	}

}

Node.addNodeClass('ReferenceNode', ReferenceNode);