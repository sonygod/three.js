import Node, { addNodeClass } from '../core/Node.js';
import { uv } from '../accessors/UVNode.js';
import { nodeProxy, float, vec2 } from '../shadernode/ShaderNode.js';

class SpriteSheetUVNode extends Node {

	public var countNode:Dynamic;
	public var uvNode:Dynamic;
	public var frameNode:Dynamic;

	public function new( countNode:Dynamic, uvNode:Dynamic = uv(), frameNode:Dynamic = float( 0 ) ) {

		super('vec2');

		this.countNode = countNode;
		this.uvNode = uvNode;
		this.frameNode = frameNode;

	}

	public function setup():Dynamic {

		var frameNode = this.frameNode;
		var uvNode = this.uvNode;
		var countNode = this.countNode;

		var width = countNode.width;
		var height = countNode.height;

		var frameNum = frameNode.mod( width * height ).floor();

		var column = frameNum.mod( width );
		var row = height - (frameNum + 1).div( width ).ceil();

		var scale = countNode.reciprocal();
		var uvFrameOffset = vec2( column, row );

		return uvNode.add( uvFrameOffset ).mul( scale );

	}

}

export default SpriteSheetUVNode;

export var spritesheetUV = nodeProxy( SpriteSheetUVNode );

addNodeClass( 'SpriteSheetUVNode', SpriteSheetUVNode );