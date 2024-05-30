class NodeUniformBuffer extends UniformBuffer {
    var _id:Int = 0;
    public nodeUniform:NodeUniform;

    public function new(nodeUniform:NodeUniform) {
        super('UniformBuffer_' ++ _id, nodeUniform != null ? nodeUniform.value : null);
        this.nodeUniform = nodeUniform;
    }

    public function get_buffer():Dynamic {
        return nodeUniform.value;
    }
}