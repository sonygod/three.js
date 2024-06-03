import jsm.nodes.core.Node;
import jsm.nodes.accessors.MaterialNode;
import jsm.nodes.shadernode.ShaderNode;

class InstancedPointsMaterialNode extends MaterialNode {
    public function new() {
        super();
    }

    public function setup(/*builder: Dynamic*/): Float {
        return this.getFloat(this.scope);
    }

    public static var POINT_WIDTH: String = 'pointWidth';
}

var materialPointWidth = ShaderNode.nodeImmutable(InstancedPointsMaterialNode, InstancedPointsMaterialNode.POINT_WIDTH);

Node.addNodeClass('InstancedPointsMaterialNode', InstancedPointsMaterialNode);