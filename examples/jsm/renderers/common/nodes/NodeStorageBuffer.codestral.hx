import jsm.renderers.common.StorageBuffer;

class NodeStorageBuffer extends StorageBuffer {

	private var _id: Int = 0;
	public var nodeUniform: Dynamic;

	public function new(nodeUniform: Dynamic = null) {
		super('StorageBuffer_' + _id++, nodeUniform != null ? nodeUniform.value : null);
		this.nodeUniform = nodeUniform;
	}

	public function get_buffer(): Dynamic {
		return this.nodeUniform.value;
	}

}