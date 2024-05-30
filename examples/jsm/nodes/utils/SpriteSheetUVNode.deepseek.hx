import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class SpriteSheetUVNode extends Node {

	public function new(countNode:ShaderNode, uvNode:UVNode = UVNode.uv(), frameNode:ShaderNode = ShaderNode.float(0)) {
		super('vec2');

		this.countNode = countNode;
		this.uvNode = uvNode;
		this.frameNode = frameNode;
	}

	public function setup():ShaderNode {
		var frameNum = this.frameNode.mod(this.countNode.width.mul(this.countNode.height)).floor();

		var column = frameNum.mod(this.countNode.width);
		var row = this.countNode.height.sub(frameNum.add(1).div(this.countNode.width).ceil());

		var scale = this.countNode.reciprocal();
		var uvFrameOffset = ShaderNode.vec2(column, row);

		return this.uvNode.add(uvFrameOffset).mul(scale);
	}

}

static function spritesheetUV(countNode:ShaderNode, uvNode:UVNode = UVNode.uv(), frameNode:ShaderNode = ShaderNode.float(0)):SpriteSheetUVNode {
	return new SpriteSheetUVNode(countNode, uvNode, frameNode);
}

Node.addNodeClass('SpriteSheetUVNode', SpriteSheetUVNode);