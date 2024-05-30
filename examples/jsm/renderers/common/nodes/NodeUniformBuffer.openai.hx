package three.js.examples.jsm.renderers.common.nodes;

import UniformBuffer;

class NodeUniformBuffer extends UniformBuffer {
    static var _id:Int = 0;

    public var nodeUniform:Dynamic;

    public function new(nodeUniform:Dynamic) {
        super('UniformBuffer_' + _id++, nodeUniform != null ? nodeUniform.value : null);
        this.nodeUniform = nodeUniform;
    }

    public function get_buffer():Dynamic {
        return nodeUniform.value;
    }
}