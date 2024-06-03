import core.TempNode;
import core.Node;
import shadernode.ShaderNode;

class PosterizeNode extends TempNode {

	public var sourceNode: Dynamic;
	public var stepsNode: Dynamic;

	public function new(sourceNode: Dynamic, stepsNode: Dynamic) {
		super();

		this.sourceNode = sourceNode;
		this.stepsNode = stepsNode;
	}

	public function setup(): Dynamic {
		return this.sourceNode.mul(this.stepsNode).floor().div(this.stepsNode);
	}
}

var posterize = ShaderNode.nodeProxy(PosterizeNode);

ShaderNode.addNodeElement('posterize', posterize);

Node.addNodeClass('PosterizeNode', Type.getClassName(PosterizeNode));