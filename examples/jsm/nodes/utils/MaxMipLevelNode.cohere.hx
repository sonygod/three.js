import UniformNode from '../core/UniformNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { nodeProxy } from '../shadernode/ShaderNode.hx';
import { addNodeClass } from '../core/Node.hx';

class MaxMipLevelNode extends UniformNode {
	public constructor(textureNode: Dynamic) {
		super(0);
		this.textureNode = textureNode;
		this.updateType = NodeUpdateType.FRAME;
	}

	public get texture(): Dynamic {
		return this.textureNode.value;
	}

	public function update(): Void {
		var texture = this.texture;
		var images = texture.images;
		var image = null;
		if (images != null && images.length > 0) {
			image = images[0].image != null ? images[0].image : images[0];
		} else {
			image = texture.image;
		}

		if (image != null && Std.is(image.width, Int)) {
			var width = image.width;
			var height = image.height;
			this.value = Math.log2(Math.max(width, height));
		}
	}
}

static function $register(): Void {
	addNodeClass('MaxMipLevelNode', MaxMipLevelNode);
}

@:autoBuildNode
export default nodeProxy(MaxMipLevelNode, '$register');