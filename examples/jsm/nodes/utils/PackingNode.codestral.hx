import ShaderNode;
import Node;
import TempNode;

class PackingNode extends TempNode {
    public var scope: String;
    public var node: ShaderNode;

    public function new(scope: String, node: ShaderNode) {
        super();
        this.scope = scope;
        this.node = node;
    }

    public function getNodeType(builder: Builder): String {
        return this.node.getNodeType(builder);
    }

    public function setup(): ShaderNode {
        var result: ShaderNode = null;

        if (this.scope == PackingNode.DIRECTION_TO_COLOR) {
            result = this.node.mul(0.5).add(0.5);
        } else if (this.scope == PackingNode.COLOR_TO_DIRECTION) {
            result = this.node.mul(2.0).sub(1);
        }

        return result;
    }
}

class PackingNodeUtils {
    static public var DIRECTION_TO_COLOR: String = 'directionToColor';
    static public var COLOR_TO_DIRECTION: String = 'colorToDirection';

    static public function directionToColor(scope: String, node: ShaderNode): ShaderNode {
        return new PackingNode(scope, node);
    }

    static public function colorToDirection(scope: String, node: ShaderNode): ShaderNode {
        return new PackingNode(scope, node);
    }
}

Node.addNodeElement('directionToColor', PackingNodeUtils.directionToColor);
Node.addNodeElement('colorToDirection', PackingNodeUtils.colorToDirection);

Node.addNodeClass('PackingNode', PackingNode);