import common.nodes.StorageBuffer;

class NodeStorageBuffer extends StorageBuffer {

    static var _id = 0;

    public function new(nodeUniform:Dynamic) {

        super('StorageBuffer_' + _id++, nodeUniform ? nodeUniform.value : null);

        this.nodeUniform = nodeUniform;

    }

    public function get_buffer():Dynamic {

        return this.nodeUniform.value;

    }

}

typedef NodeStorageBuffer = common.nodes.NodeStorageBuffer;