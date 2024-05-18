package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.accessors.UVNode;
import three.js.shadernode.ShaderNode;

class SpriteSheetUVNode extends Node {

    public var countNode:Node;
    public var uvNode:UVNode;
    public var frameNode:ShaderNode;

    public function new(countNode:Node, ?uvNode:UVNode = UVNode.create(), ?frameNode:ShaderNode = ShaderNode.float(0.0)) {
        super('vec2');

        this.countNode = countNode;
        this.uvNode = uvNode;
        this.frameNode = frameNode;
    }

    public function setup():ShaderNode {
        var frameNum:Int = Math.floor(frameNode.mod(countNode.width * countNode.height));
        var column:Int = frameNum % countNode.width;
        var row:Int = countNode.height - Math.ceil((frameNum + 1) / countNode.width);

        var scale:ShaderNode = countNode.reciprocal();
        var uvFrameOffset:ShaderNode = vec2(column, row);
        return uvNode.add(uvFrameOffset).mul(scale);
    }

}

typedef SpriteSheetUVNodeProxy = ShaderNode;

var spritesheetUV:SpriteSheetUVNodeProxy = nodeProxy(SpriteSheetUVNode);

Node.addNodeClass('SpriteSheetUVNode', SpriteSheetUVNode);