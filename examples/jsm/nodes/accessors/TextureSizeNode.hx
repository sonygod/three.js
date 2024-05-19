package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;

class TextureSizeNode extends Node {
    public var isTextureSizeNode:Bool = true;

    public var textureNode:Dynamic;
    public var levelNode:Dynamic;

    public function new(textureNode:Dynamic, ?levelNode:Dynamic) {
        super('uvec2');

        this.textureNode = textureNode;
        this.levelNode = levelNode;
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var textureProperty:String = textureNode.build(builder, 'property');
        var levelNodeValue:String = levelNode.build(builder, 'int');

        return builder.format('${builder.getMethod("textureDimensions")}($textureProperty, $levelNodeValue)', getNodeType(builder), output);
    }
}

// Export the class
@:keep
@:expose('TextureSizeNode')
class __TextureSizeNode__ extends TextureSizeNode {
    public function new(textureNode:Dynamic, ?levelNode:Dynamic) {
        super(textureNode, levelNode);
    }
}

// Create a node proxy
var textureSize:Dynamic = nodeProxy(__TextureSizeNode__);

// Add the node element
addNodeElement('textureSize', textureSize);

// Add the node class
addNodeClass('TextureSizeNode', __TextureSizeNode__);