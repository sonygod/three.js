import UniformBuffer from '../UniformBuffer.js';

static var _id = 0;

class NodeUniformBuffer extends UniformBuffer {

	public function new(nodeUniform:Dynamic) {

		super('UniformBuffer_' + (_id ++), nodeUniform ? nodeUniform.value : null);

		this.nodeUniform = nodeUniform;

	}

	public function get_buffer():Dynamic {

		return this.nodeUniform.value;

	}

}

typedef NodeUniformBuffer = NodeUniformBuffer;