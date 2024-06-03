import TempNode from '../core/TempNode.hx';
import UVNode from '../accessors/UVNode.hx';
import Node from '../core/Node.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

class CheckerNode extends TempNode {
    public var uvNode:UVNode;

    public function new(uvNode:UVNode = null) {
        if (uvNode == null) uvNode = new UVNode();
        super('Float');
        this.uvNode = uvNode;
    }

    public function setup():Float {
        return checkerShaderNode({uv: this.uvNode});
    }
}

function checkerShaderNode(inputs:Dynamic):Float {
    var uv = inputs.uv.mul(2.0);

    var cx = Math.floor(uv.x);
    var cy = Math.floor(uv.y);
    var result = (cx + cy) % 2.0;

    return Math.sign(result);
}

var checker = ShaderNode.nodeProxy(CheckerNode);

ShaderNode.addNodeElement('checker', checker);

Node.addNodeClass('CheckerNode', CheckerNode);