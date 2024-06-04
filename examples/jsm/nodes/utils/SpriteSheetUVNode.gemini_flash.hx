import Node from "../core/Node";
import UVNode from "../accessors/UVNode";
import { nodeProxy, float, vec2 } from "../shadernode/ShaderNode";

class SpriteSheetUVNode extends Node {

	public countNode:Node;
	public uvNode:Node;
	public frameNode:Node;

	public function new(countNode:Node, uvNode:Node = new UVNode(), frameNode:Node = float(0)) {
		super('vec2');
		this.countNode = countNode;
		this.uvNode = uvNode;
		this.frameNode = frameNode;
	}

	override public function setup():Node {
		var frameNode = this.frameNode;
		var uvNode = this.uvNode;
		var countNode = this.countNode;

		var width = countNode.getField('width');
		var height = countNode.getField('height');

		var frameNum = frameNode.mod(width.mul(height)).floor();

		var column = frameNum.mod(width);
		var row = height.sub(frameNum.add(1).div(width).ceil());

		var scale = countNode.reciprocal();
		var uvFrameOffset = vec2(column, row);

		return uvNode.add(uvFrameOffset).mul(scale);
	}

}

export var SpriteSheetUVNode = SpriteSheetUVNode;

export var spritesheetUV = nodeProxy(SpriteSheetUVNode);

Node.addNodeClass('SpriteSheetUVNode', SpriteSheetUVNode);