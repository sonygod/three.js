import Node from '../core/Node.hx';
import { uv } from '../accessors/UVNode.hx';
import { nodeProxy, float, vec2 } from '../shadernode/ShaderNode.hx';

class SpriteSheetUVNode extends Node {
    public function new(countNode:Node, uvNode:Node = uv(), frameNode:Node = float(0)) {
        super('vec2');
        this.countNode = countNode;
        this.uvNode = uvNode;
        this.frameNode = frameNode;
    }

    public function setup():Node {
        var frameNode = this.frameNode;
        var uvNode = this.uvNode;
        var countNode = this.countNode;

        var width = countNode.width;
        var height = countNode.height;

        var frameNum = frameNode.mod(width * height).floor();

        var column = frameNum % width;
        var row = height - (frameNum / width).ceil();

        var scale = countNode.reciprocal();
        var uvFrameOffset = vec2(column, row);

        return uvNode + uvFrameOffset * scale;
    }
}

function spritesheetUV(countNode:Node, uvNode:Node = uv(), frameNode:Node = float(0)) {
    return nodeProxy(SpriteSheetUVNode, countNode, uvNode, frameNode);
}

Node.addNodeClass('SpriteSheetUVNode', SpriteSheetUVNode);

export { SpriteSheetUVNode, spritesheetUV };