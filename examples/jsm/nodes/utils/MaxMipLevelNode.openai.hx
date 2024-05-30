package three.js.examples.jsm.nodes.utils;

import three.js.core.UniformNode;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;
import three.js.core.Node;

class MaxMipLevelNode extends UniformNode {

    public var textureNode:Dynamic;

    public function new(textureNode:Dynamic) {
        super(0);
        this.textureNode = textureNode;
        this.updateType = NodeUpdateType.FRAME;
    }

    public var texture(get, never):Dynamic;

    function get_texture():Dynamic {
        return textureNode.value;
    }

    override public function update():Void {
        var texture:Dynamic = this.texture;
        var images:Dynamic = texture.images;
        var image:Dynamic = (images && images.length > 0) ? ((images[0] && images[0].image) || images[0]) : texture.image;

        if (image && image.width != null) {
            var width:Int = image.width;
            var height:Int = image.height;
            this.value = Math.log2(Math.max(width, height));
        }
    }

}

// Exports
@:native("maxMipLevel")
private function maxMipLevelProxy():MaxMipLevelNode {
    return new MaxMipLevelNode(null);
}

// Register the node class
Node.addNodeClass("MaxMipLevelNode", MaxMipLevelNode);