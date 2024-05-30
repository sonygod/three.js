import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.accessors.UVNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class CheckerNode extends TempNode {

    public var uvNode:UVNode;

    public function new(uvNode:UVNode = UVNode.uv()) {
        super('float');
        this.uvNode = uvNode;
    }

    public function setup():ShaderNode {
        var uv = this.uvNode.mul(2.0);
        var cx = uv.x.floor();
        var cy = uv.y.floor();
        var result = cx.add(cy).mod(2.0);
        return result.sign();
    }

}

static function checker(uvNode:UVNode = UVNode.uv()):CheckerNode {
    return new CheckerNode(uvNode);
}

ShaderNode.addNodeElement('checker', checker);
Node.addNodeClass('CheckerNode', CheckerNode);