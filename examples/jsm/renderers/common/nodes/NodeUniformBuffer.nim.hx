import UniformBuffer from '../UniformBuffer.hx';

class NodeUniformBuffer extends UniformBuffer {
    static var _id:Int = 0;

    var nodeUniform:Dynamic;

    public function new(nodeUniform:Dynamic) {
        super('UniformBuffer_' + (_id++).toString(), nodeUniform != null ? nodeUniform.value : null);
        this.nodeUniform = nodeUniform;
    }

    public function get buffer():Dynamic {
        return this.nodeUniform.value;
    }
}

export default NodeUniformBuffer;