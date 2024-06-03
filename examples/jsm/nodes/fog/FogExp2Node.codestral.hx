import js.Browser.document;
import three.js.nodes.fog.FogNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class FogExp2Node extends FogNode {

    public var isFogExp2Node:Bool = true;
    public var densityNode:ShaderNode;

    public function new(colorNode:ShaderNode, densityNode:ShaderNode) {
        super(colorNode);
        this.densityNode = densityNode;
    }

    public function setup(builder:Node):ShaderNode {
        var viewZ:ShaderNode = this.getViewZNode(builder);
        var density:ShaderNode = this.densityNode;

        return density.mul(density, viewZ, viewZ).negate().exp().oneMinus();
    }
}

var densityFog:ShaderNode = ShaderNode.nodeProxy(FogExp2Node);
ShaderNode.addNodeElement("densityFog", densityFog);
Node.addNodeClass("FogExp2Node", FogExp2Node);