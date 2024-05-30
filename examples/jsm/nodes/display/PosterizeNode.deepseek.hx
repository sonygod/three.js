import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class PosterizeNode extends TempNode {

	public function new(sourceNode:Dynamic, stepsNode:Dynamic) {
		super();

		this.sourceNode = sourceNode;
		this.stepsNode = stepsNode;
	}

	public function setup():Dynamic {
		var sourceNode = this.sourceNode;
		var stepsNode = this.stepsNode;

		return sourceNode.mul(stepsNode).floor().div(stepsNode);
	}

}

static function posterize(sourceNode:Dynamic, stepsNode:Dynamic):Dynamic {
	return new PosterizeNode(sourceNode, stepsNode);
}

ShaderNode.addNodeElement('posterize', posterize);

Node.addNodeClass('PosterizeNode', PosterizeNode);