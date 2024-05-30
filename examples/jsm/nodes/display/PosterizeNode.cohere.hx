import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class PosterizeNode extends TempNode {
	public var sourceNode:Dynamic;
	public var stepsNode:Dynamic;

	public function new(sourceNode:Dynamic, stepsNode:Dynamic) {
		super();
		this.sourceNode = sourceNode;
		this.stepsNode = stepsNode;
	}

	public function setup():Dynamic {
		return this.sourceNode.mul(this.stepsNode).floor().div(this.stepsNode);
	}
}

@:shim("PosterizeNode")
class PosterizeNodeShim extends PosterizeNode {
}

static function posterize() {
	return nodeProxy(PosterizeNode);
}

addNodeElement('posterize', posterize);
addNodeClass('PosterizeNode', PosterizeNodeShim);