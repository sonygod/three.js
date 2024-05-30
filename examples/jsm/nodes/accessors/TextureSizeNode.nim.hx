import Node from '../core/Node';
import { addNodeClass } from '../core/Node';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode';

class TextureSizeNode extends Node {

	public var isTextureSizeNode:Bool = true;
	public var textureNode:Node;
	public var levelNode:Node;

	public function new(textureNode:Node, levelNode:Node = null) {
		super('uvec2');

		this.textureNode = textureNode;
		this.levelNode = levelNode;
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var textureProperty:Dynamic = this.textureNode.build(builder, 'property');
		var levelNode:Dynamic = this.levelNode.build(builder, 'int');

		return builder.format('${builder.getMethod('textureDimensions')}(${textureProperty}, ${levelNode})', this.getNodeType(builder), output);
	}
}

export default TextureSizeNode;

export var textureSize:Dynamic = nodeProxy(TextureSizeNode);

addNodeElement('textureSize', textureSize);

addNodeClass('TextureSizeNode', TextureSizeNode);