import ShaderNode.ShaderNodeElement;
import ShaderNode.FloatNode;
import ShaderNode.NodeProxy;
import ShaderNode.Node;
import ShaderNode.MathNode;

class RemapNode extends Node {
    public var node: MathNode;
    public var inLowNode: MathNode;
    public var inHighNode: MathNode;
    public var outLowNode: MathNode;
    public var outHighNode: MathNode;
    public var doClamp: Bool;

    public function new(node: MathNode, inLowNode: MathNode, inHighNode: MathNode, outLowNode: MathNode = new FloatNode(0), outHighNode: MathNode = new FloatNode(1)) {
        super();
        this.node = node;
        this.inLowNode = inLowNode;
        this.inHighNode = inHighNode;
        this.outLowNode = outLowNode;
        this.outHighNode = outHighNode;
        this.doClamp = true;
    }

    public function setup(): MathNode {
        var t: MathNode = node.sub(inLowNode).div(inHighNode.sub(inLowNode));
        if (doClamp == true) t = t.clamp();
        return t.mul(outHighNode.sub(outLowNode)).add(outLowNode);
    }
}

class RemapNodeUtils {
    public static var remap: NodeProxy = new NodeProxy(RemapNode, null, null, {doClamp: false});
    public static var remapClamp: NodeProxy = new NodeProxy(RemapNode);

    public static function addNodeElement(name: String, element: ShaderNodeElement) {
        // Implementation depends on the context
    }

    public static function addNodeClass(name: String, nodeClass: Class<Node>) {
        // Implementation depends on the context
    }
}

RemapNodeUtils.addNodeElement('remap', RemapNodeUtils.remap);
RemapNodeUtils.addNodeElement('remapClamp', RemapNodeUtils.remapClamp);
RemapNodeUtils.addNodeClass('RemapNode', RemapNode);