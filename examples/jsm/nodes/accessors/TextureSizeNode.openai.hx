package three.js.nodes.accessors;

import three.js.nodes.Node;

class TextureSizeNode extends Node {

    public var isTextureSizeNode:Bool = true;

    public var textureNode:Node;
    public var levelNode:Node;

    public function new(textureNode:Node, ?levelNode:Node) {
        super('uvec2');

        this.textureNode = textureNode;
        this.levelNode = levelNode;
    }

    override public function generate(builder:Dynamic, output:Dynamic) {
        var textureProperty = textureNode.build(builder, 'property');
        var levelNodeValue = levelNode.build(builder, 'int');

        return builder.format('${builder.getMethod("textureDimensions")}( ${textureProperty}, ${levelNodeValue} )', getNodeType(builder), output);
    }

    public static function textureSize(?args:Dynamic):TextureSizeNode {
        return new TextureSizeNode(args.textureNode, args.levelNode);
    }
}

node Шardware(node:Dynamic) {
    node.addNodeElement('textureSize', TextureSizeNode.textureSize);
    node.addNodeClass('TextureSizeNode', TextureSizeNode);
}