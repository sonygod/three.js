import jsm.nodes.core.Node;
import jsm.nodes.accessors.PositionNode;
import jsm.nodes.shadernode.ShaderNode;

class FogNode extends Node {

    public var colorNode: Node;
    public var factorNode: Node;
    public var isFogNode: Bool = true;

    public function new(colorNode: Node, factorNode: Node) {
        super("float");
        this.colorNode = colorNode;
        this.factorNode = factorNode;
    }

    public function getViewZNode(builder: Builder): Node {
        var viewZ: Node = null;
        var getViewZ = builder.context.getViewZ;
        if (getViewZ != null) {
            viewZ = getViewZ(this);
        }
        return (viewZ != null ? viewZ : PositionNode.positionView.z).negate();
    }

    public function setup(): Node {
        return this.factorNode;
    }
}

class FogNodeAdapter extends ShaderNode {
    public function new() {
        super();
    }

    override function getNode(inputs: Array<Node>): Node {
        return new FogNode(inputs[0], inputs[1]);
    }

    override function getUsedNodes(usedNodes: HashSet<Node>): Void {
        super.getUsedNodes(usedNodes);
        usedNodes.add(this);
    }
}

var fog = new FogNodeAdapter();
ShaderNode.addNodeElement("fog", fog);
Node.addNodeClass("FogNode", FogNode);