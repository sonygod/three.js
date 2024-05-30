class NodeStorageBuffer extends StorageBuffer {
	public var nodeUniform: NodeUniform;
	public var _id: Int;

	public function new(nodeUniform: NodeUniform) {
		super('StorageBuffer_' ++ _id, nodeUniform.value);
		this.nodeUniform = nodeUniform;
	}

	public function get_buffer(): StorageBuffer {
		return this.nodeUniform.value;
	}
}