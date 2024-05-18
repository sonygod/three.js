package three.js.examples.jsm.nodes.utils;

import three.js.core.UniformNode;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;

class MaxMipLevelNode extends UniformNode {
    public var textureNode:Dynamic;

    public function new(textureNode:Dynamic) {
        super(0);
        this.textureNode = textureNode;
        this.updateType = NodeUpdateType.FRAME;
    }

    public var texture(get, null):Dynamic;

    private function get_texture():Dynamic {
        return this.textureNode.value;
    }

    public function update():Void {
        var texture:Dynamic = this.texture;
        var images:Array<Dynamic> = texture.images;
        var image:Dynamic = (images != null && images.length > 0) ? ((images[0] != null && images[0].image != null) ? images[0].image : images[0]) : texture.image;

        if (image != null && image.width != null) {
            var width:Int = image.width;
            var height:Int = image.height;
            this.value = Math.log2(Math.max(width, height));
        }
    }
}

class MaxMipLevelNodeProxy {
    public static function nodeProxy(node:MaxMipLevelNode):Dynamic {
        return node;
    }
}

addNodeClass('MaxMipLevelNode', MaxMipLevelNode);

// Export the class
#if haxe3
@:expose
#end
class MaxMipLevelNodeDefault {
    public static var maxMipLevel:Dynamic = MaxMipLevelNodeProxy.nodeProxy(new MaxMipLevelNode(null));
}