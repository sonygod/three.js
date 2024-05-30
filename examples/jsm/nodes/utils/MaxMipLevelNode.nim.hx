import UniformNode from '../core/UniformNode.js';
import { NodeUpdateType } from '../core/constants.js';
import { nodeProxy } from '../shadernode/ShaderNode.js';
import { addNodeClass } from '../core/Node.js';

class MaxMipLevelNode extends UniformNode {

	public var textureNode:Dynamic;

	public function new(textureNode:Dynamic) {

		super(0);

		this.textureNode = textureNode;

		this.updateType = NodeUpdateType.FRAME;

	}

	public function get texture():Dynamic {

		return this.textureNode.value;

	}

	public function update():Void {

		var texture = this.texture;
		var images = texture.images;
		var image = (images && images.length > 0) ? ( (images[0] && images[0].image) || images[0] ) : texture.image;

		if (image && image.width !== null) {

			var width = image.width;
			var height = image.height;

			this.value = Math.log2(Math.max(width, height));

		}

	}

}

export default MaxMipLevelNode;

export const maxMipLevel = nodeProxy(MaxMipLevelNode);

addNodeClass('MaxMipLevelNode', MaxMipLevelNode);