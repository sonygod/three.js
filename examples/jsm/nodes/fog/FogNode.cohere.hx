import Node from '../core/Node.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class FogNode extends Node {
	public isFogNode: Bool;
	public colorNode: Node;
	public factorNode: Node;

	public function new(colorNode: Node, factorNode: Node) {
		super('float');
		this.isFogNode = true;
		this.colorNode = colorNode;
		this.factorNode = factorNode;
	}

	public function getViewZNode(builder: Dynamic) : Node {
		var viewZ = null;
		var getViewZ = builder.context.getViewZ;
		if (getViewZ != null) {
			viewZ = getViewZ(this);
		}
		return (viewZ ?? positionView.z).negate();
	}

	public function setup() : Node {
		return this.factorNode;
	}
}

@:privateAccess
class Fog {
	public static function fog(colorNode: Node, factorNode: Node) : FogNode {
		return new FogNode(colorNode, factorNode);
	}
}

@:autoBuild
class FogAccess {
	public static inline var fog = Fog.fog;
}

addNodeElement('fog', FogAccess.fog);
addNodeClass('FogNode', FogNode);

export { FogAccess as default, FogAccess as fog };