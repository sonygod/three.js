import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class FogNode extends Node {

	public var isFogNode:Bool;
	public var colorNode:Dynamic;
	public var factorNode:Dynamic;

	public function new(colorNode:Dynamic, factorNode:Dynamic) {
		super('float');

		this.isFogNode = true;
		this.colorNode = colorNode;
		this.factorNode = factorNode;
	}

	public function getViewZNode(builder:Dynamic):Dynamic {
		var viewZ:Dynamic = null;
		var getViewZ:Dynamic = builder.context.getViewZ;

		if (getViewZ !== undefined) {
			viewZ = getViewZ(this);
		}

		return (viewZ || PositionNode.positionView.z).negate();
	}

	public function setup():Dynamic {
		return this.factorNode;
	}

}

class FogNodeProxy extends ShaderNode.NodeProxy {
	public function new() {
		super(FogNode);
	}
}

ShaderNode.addNodeElement('fog', new FogNodeProxy());
Node.addNodeClass('FogNode', FogNode);