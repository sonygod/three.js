import Node from '../core/Node';
import { uv } from '../accessors/UVNode';
import { nodeProxy, float, vec2 } from '../shadernode/ShaderNode';

class SpriteSheetUVNode extends Node {

	public var countNode: Node;
	public var uvNode: Node;
	public var frameNode: Node;

	public function new(countNode: Node, uvNode: Node = uv(), frameNode: Node = float(0)) {

		super('vec2');

		this.countNode = countNode;
		this.uvNode = uvNode;
		this.frameNode = frameNode;
	}

	public function setup(): Node {

		const width: Node = this.countNode.width;
		const height: Node = this.countNode.height;

		const frameNum: Node = this.frameNode.mod(width.mul(height)).floor();

		const column: Node = frameNum.mod(width);
		const row: Node = height.sub(frameNum.add(1).div(width).ceil());

		const scale: Node = this.countNode.reciprocal();
		const uvFrameOffset: Node = vec2(column, row);

		return this.uvNode.add(uvFrameOffset).mul(scale);
	}
}

class SpriteSheetUV {
	public static function call(countNode: Node, uvNode: Node = uv(), frameNode: Node = float(0)): Node {
		return nodeProxy(new SpriteSheetUVNode(countNode, uvNode, frameNode));
	}
}

Node.addNodeClass('SpriteSheetUVNode', SpriteSheetUVNode);