import UniformBuffer from '../UniformBuffer.hx';

class NodeUniformBuffer extends UniformBuffer {
    private var _id:Int = 0;
    public var nodeUniform:Dynamic;

    public function new(nodeUniform:Dynamic) {
        super('UniformBuffer_' + _id++, (nodeUniform != null ? nodeUniform.value : null));
        this.nodeUniform = nodeUniform;
    }

    public function get_buffer():Dynamic {
        return this.nodeUniform.value;
    }
}