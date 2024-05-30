import TempNode from '../core/TempNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class PosterizeNode extends TempNode {

	public var sourceNode:Dynamic;
	public var stepsNode:Dynamic;

	public function new(sourceNode:Dynamic, stepsNode:Dynamic) {
		super();

		this.sourceNode = sourceNode;
		this.stepsNode = stepsNode;
	}

	public function setup():Dynamic {
		const { sourceNode, stepsNode } = this;

		return sourceNode.mul(stepsNode).floor().div(stepsNode);
	}
}

export default PosterizeNode;

export const posterize = nodeProxy(PosterizeNode);

addNodeElement('posterize', posterize);

addNodeClass('PosterizeNode', PosterizeNode);