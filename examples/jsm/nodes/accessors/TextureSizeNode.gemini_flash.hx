import Node from "../core/Node";
import {addNodeClass, addNodeElement} from "../core/Node";
import {nodeProxy} from "../shadernode/ShaderNode";

class TextureSizeNode extends Node {

	public var textureNode:Node;
	public var levelNode:Node;

	public function new(textureNode:Node, levelNode:Node = null) {
		super('uvec2');
		this.isTextureSizeNode = true;
		this.textureNode = textureNode;
		this.levelNode = levelNode;
	}

	override public function generate(builder:Dynamic, output:String):String {
		var textureProperty = this.textureNode.build(builder, 'property');
		var levelNode = this.levelNode != null ? this.levelNode.build(builder, 'int') : "0";
		return builder.format('${builder.getMethod("textureDimensions")}( ${textureProperty}, ${levelNode} )', this.getNodeType(builder), output);
	}

}

export var TextureSizeNode = TextureSizeNode;

export var textureSize = nodeProxy(TextureSizeNode);

addNodeElement('textureSize', textureSize);

addNodeClass('TextureSizeNode', TextureSizeNode);