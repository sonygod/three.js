package three.js.examples.jvm.renderers.common.nodes;

import three.js.examples.jvm.renderers.common.StorageBuffer;

class NodeStorageBuffer extends StorageBuffer {
    static var _id:Int = 0;

    var nodeUniform:Dynamic;

    public function new(nodeUniform:Dynamic) {
        super('StorageBuffer_' + _id++, nodeUniform != null ? nodeUniform.value : null);
        this.nodeUniform = nodeUniform;
    }

    public var buffer(get, never):Dynamic;

    function get_buffer():Dynamic {
        return nodeUniform.value;
    }
}