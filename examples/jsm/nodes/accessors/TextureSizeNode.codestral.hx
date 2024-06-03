import Node from '../core/Node';
import { addNodeClass } from '../core/Node';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode';

class TextureSizeNode extends Node {

    public var textureNode: Node;
    public var levelNode: Node;

    public function new(textureNode: Node, levelNode: Node = null) {
        super("uvec2");

        this.isTextureSizeNode = true;

        this.textureNode = textureNode;
        this.levelNode = levelNode;
    }

    public function generate(builder: Builder, output: String): String {
        var textureProperty = this.textureNode.build(builder, "property");
        var levelNode = this.levelNode.build(builder, "int");

        return builder.format(builder.getMethod('textureDimensions') + "(" + textureProperty + ", " + levelNode + ")", this.getNodeType(builder), output);
    }

}

class TextureSize {
    public static function call(textureNode: Node, levelNode: Node = null): TextureSizeNode {
        return new TextureSizeNode(textureNode, levelNode);
    }
}

addNodeElement("textureSize", TextureSize.call);

addNodeClass("TextureSizeNode", TextureSizeNode);