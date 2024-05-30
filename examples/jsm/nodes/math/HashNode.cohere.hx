import Node from '../core/Node.hx';
import { addNodeClass, addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class HashNode extends Node {
	public var seedNode:Node;

	public function new(seedNode:Node) {
		super();
		this.seedNode = seedNode;
	}

	override function setup(/*builder*/) {
		// Taken from https://www.shadertoy.com/view/XlGcRh, originally from pcg-random.org
		var state = this.seedNode.toUint().mul(747796405).add(2891336453);
		var word = state.shr(state.shr(28).addInt(4)).xor(state).mul(277803737);
		var result = word.shr(22).xor(word);

		return result.toFloat().mul(1.0 / 2 ** 32); // Convert to range [0, 1)
	}
}

@:enumField
class HashNodeFields {
	public static var seedNode:String = "seedNode";
}

var HashNode_proto = HashNode.prototype;

addNodeClass('HashNode', HashNode);

var hash = nodeProxy(HashNode);
addNodeElement('hash', hash);

Class.register(HashNode);
Class.registerEnum(HashNodeFields);