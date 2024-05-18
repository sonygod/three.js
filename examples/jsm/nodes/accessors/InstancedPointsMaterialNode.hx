package three.js.examples.jm.nodes.accessors;

import three.js.examples.jm.nodes.MaterialNode;
import three.jsexamples.core.Node;
import three.js.shadernode.ShaderNode;

class InstancedPointsMaterialNode extends MaterialNode {
    public static inline var POINT_WIDTH:String = 'pointWidth';

    public function new() {
        super();
    }

    override public function setup(builder:Dynamic):Float {
        return getFloat(scope);
    }
}

class InstancedPointsMaterialNodeMeta {
    public static var materialPointWidth:InstancedPointsMaterialNode = nodeImmutable(new InstancedPointsMaterialNode(), InstancedPointsMaterialNode.POINT_WIDTH);
}

Node.addClass('InstancedPointsMaterialNode', InstancedPointsMaterialNode);