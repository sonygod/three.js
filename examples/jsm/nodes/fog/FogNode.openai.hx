package three.js.nodes.fog;

import three.js.core.Node;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class FogNode extends Node {

    public var isFogNode:Bool = true;

    public var colorNode:Dynamic;
    public var factorNode:Dynamic;

    public function new(colorNode:Dynamic, factorNode:Dynamic) {
        super('float');

        this.colorNode = colorNode;
        this.factorNode = factorNode;
    }

    public function getViewZNode(builder:Dynamic):Dynamic {
        var viewZ:Dynamic = null;
        var getViewZ = builder.context.getViewZ;
        if (getViewZ != null) {
            viewZ = getViewZ(this);
        }
        return (viewZ != null ? viewZ : PositionNode.positionView.z).negate();
    }

    public function setup():Dynamic {
        return this.factorNode;
    }

}

typedef FogNodeProxy = {
    new(?colorNode:Dynamic, ?factorNode:Dynamic):FogNode;
}

var fog : FogNodeProxy = nodeProxy(FogNode);

ShaderNode.addNodeElement('fog', fog);
Node.addNodeClass('FogNode', FogNode);