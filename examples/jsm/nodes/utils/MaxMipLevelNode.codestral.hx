import UniformNode from '../core/UniformNode';
import { NodeUpdateType } from '../core/constants';
import { nodeProxy } from '../shadernode/ShaderNode';
import { addNodeClass } from '../core/Node';

class MaxMipLevelNode extends UniformNode {

    public var textureNode: ShaderNode;

    public function new(textureNode: ShaderNode) {
        super(0);
        this.textureNode = textureNode;
        this.updateType = NodeUpdateType.FRAME;
    }

    public inline function get_texture(): Texture {
        return this.textureNode.value;
    }

    public function update(): Void {
        var texture = this.texture;
        var images = texture.images;
        var image = (images != null && images.length > 0) ? (((images[0] as any).image != null ? (images[0] as any).image : images[0])) : texture.image;

        if (image != null && Reflect.hasField(image, "width")) {
            var width = Reflect.field(image, "width");
            var height = Reflect.field(image, "height");

            this.value = Math.log2(Math.max(width, height));
        }
    }
}

class ShaderNode {
    public var value: Texture;
}

class Texture {
    public var images: Array<any>;
    public var image: any;
}

var maxMipLevel = nodeProxy(MaxMipLevelNode);
addNodeClass("MaxMipLevelNode", MaxMipLevelNode);