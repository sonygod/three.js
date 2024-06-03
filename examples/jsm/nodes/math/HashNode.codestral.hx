import js.Browser.document;
import three.nodes.core.Node;
import three.nodes.shadernode.ShaderNode;

class HashNode extends Node {
    private var seedNode: Node;

    public function new(seedNode: Node) {
        super();
        this.seedNode = seedNode;
    }

    public function setup(): Float {
        // Taken from https://www.shadertoy.com/view/XlGcRh, originally from pcg-random.org
        var state = this.seedNode.toUint().mul(747796405).add(2891336453);
        var word = state.shiftRight(state.shiftRight(28).add(4)).bitXor(state).mul(277803737);
        var result = word.shiftRight(22).bitXor(word);
        return result.toFloat().mul(1.0 / Math.pow(2, 32)); // Convert to range [0, 1)
    }
}

function hash(seedNode: Node): ShaderNode {
    return ShaderNode.nodeProxy(new HashNode(seedNode));
}

ShaderNode.addNodeElement("hash", hash);
Node.addNodeClass("HashNode", HashNode);