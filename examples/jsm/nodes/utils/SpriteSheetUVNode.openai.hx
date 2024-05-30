package three.js.jsm.nodes.utils;

import three.js.core.Node;
import three.js.accessors.UVNode;
import three.js.shadernode.ShaderNode;

class SpriteSheetUVNode extends Node {
    public var countNode:Node;
    public var uvNode:UVNode;
    public var frameNode:ShaderNode;

    public function new(countNode:Node, ?uvNode:UVNode = UVNode.create(), ?frameNode:ShaderNode = ShaderNode.float(0)) {
        super('vec2');
        this.countNode = countNode;
        this.uvNode = uvNode;
        this.frameNode = frameNode;
    }

    public function setup():ShaderNode {
        var frameNum:Int = Std.int(frameNode.mod(countNode.width * countNode.height).x);
        var column:Float = frameNum % countNode.width;
        var row:Float = countNode.height - Math.ceil((frameNum + 1) / countNode.width);
        var scale:ShaderNode = countNode.reciprocal();
        var uvFrameOffset:ShaderNode = new ShaderNode('vec2', [column, row]);
        return uvNode.add(uvFrameOffset).mul(scale);
    }
}

typedef spritesheetUV = SpriteSheetUVNode;

Node.addClass('SpriteSheetUVNode', SpriteSheetUVNode);