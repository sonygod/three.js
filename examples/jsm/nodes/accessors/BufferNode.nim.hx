import UniformNode from '../core/UniformNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class BufferNode extends UniformNode {

	public var isBufferNode:Bool = true;
	public var bufferType:String;
	public var bufferCount:Int;

	public function new(value:Dynamic, bufferType:String, bufferCount:Int = 0) {
		super(value, bufferType);

		this.bufferType = bufferType;
		this.bufferCount = bufferCount;
	}

	public function getInputType():String {
		return 'buffer';
	}

}

using Three.examples.jsm.nodes.accessors;

export default BufferNode;

export function buffer(value:Dynamic, type:String, count:Int):Node {
	return nodeObject(new BufferNode(value, type, count));
}

addNodeClass('BufferNode', BufferNode);