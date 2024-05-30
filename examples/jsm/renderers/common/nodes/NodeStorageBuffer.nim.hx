import StorageBuffer;

class NodeStorageBuffer extends StorageBuffer {
    static var _id:Int = 0;
    var nodeUniform:Dynamic;

    public function new(nodeUniform:Dynamic) {
        super('StorageBuffer_' + Std.string(_id++) + '_', nodeUniform != null ? nodeUniform.value : null);
        this.nodeUniform = nodeUniform;
    }

    public function get buffer():Dynamic {
        return this.nodeUniform.value;
    }
}