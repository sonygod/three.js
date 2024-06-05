import Node, { addNodeClass } from '../core/Node.js';
import { positionView } from '../accessors/PositionNode.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

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
		var viewZ:Dynamic;

		var getViewZ:Dynamic = builder.context.getViewZ;

		if (getViewZ != null) {
			viewZ = getViewZ(this);
		}

		return (viewZ != null ? viewZ : positionView.z).negate();
	}

	public function setup():Dynamic {
		return this.factorNode;
	}
}

@:build(macro $v{FogNode})
extern class FogNodeProxy extends FogNode {}

addNodeElement('fog', FogNodeProxy);
addNodeClass('FogNode', FogNode);