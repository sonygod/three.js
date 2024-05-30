import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.Node;

class MaxMipLevelNode extends UniformNode {

	public function new(textureNode:UniformNode) {
		super(0);
		this.textureNode = textureNode;
		this.updateType = NodeUpdateType.FRAME;
	}

	public function get_texture():Dynamic {
		return this.textureNode.value;
	}

	public function update():Void {
		var texture = this.texture;
		var images = texture.images;
		var image = (images && images.length > 0) ? ((images[0] && images[0].image) || images[0]) : texture.image;

		if (image && image.width !== undefined) {
			var width = image.width;
			var height = image.height;
			this.value = Math.log2(Math.max(width, height));
		}
	}

}

class MaxMipLevelNodeProxy extends ShaderNode {
	public static inline function new(textureNode:UniformNode):MaxMipLevelNode {
		return new MaxMipLevelNode(textureNode);
	}
}

class MaxMipLevelNodeHelper {
	public static function addNodeClass(name:String, node:MaxMipLevelNode):Void {
		Node.addNodeClass(name, node);
	}
}

MaxMipLevelNodeHelper.addNodeClass('MaxMipLevelNode', MaxMipLevelNode);