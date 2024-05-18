package three.js.examples.jsm.nodes.fog;

import three.js.core.Node;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class FogNode extends Node {

    public var isFogNode:Bool = true;

    public var colorNode:Node;
    public var factorNode:Node;

    public function new(colorNode:Node, factorNode:Node) {
        super('float');
        this.colorNode = colorNode;
        this.factorNode = factorNode;
    }

    public function getViewZNode(builder:Dynamic):Node {
        var viewZ:Node;
        var getViewZ:Dynamic = builder.context.getViewZ;
        if (getViewZ != null) {
            viewZ = getViewZ(this);
        }
        return (viewZ != null ? viewZ : positionView.z).negate();
    }

    public function setup():Node {
        return factorNode;
    }

}

class FogNodeProxy {
    public static function fog(node:FogNode):Node {
        return node;
    }
}

registerNodeElement('fog', FogNodeProxy.fog);
registerNodeClass('FogNode', FogNode);