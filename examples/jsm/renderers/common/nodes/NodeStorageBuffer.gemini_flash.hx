import StorageBuffer from "../StorageBuffer";

class NodeStorageBuffer extends StorageBuffer {
  static _id:Int = 0;

  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super('StorageBuffer_' + NodeStorageBuffer._id++, nodeUniform != null ? nodeUniform.value : null);
    this.nodeUniform = nodeUniform;
  }

  public function get buffer():Dynamic {
    return this.nodeUniform.value;
  }
}

class NodeStorageBuffer {
  public static function main():Void {
    // Example usage
    // Assuming you have a nodeUniform object available
    // var nodeUniform = ...;
    // var storageBuffer = new NodeStorageBuffer(nodeUniform);
    // var bufferData = storageBuffer.buffer;
  }
}