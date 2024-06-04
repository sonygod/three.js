import UniformBuffer from "../UniformBuffer";

class NodeUniformBuffer extends UniformBuffer {

  static _id:Int = 0;

  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super('UniformBuffer_' + NodeUniformBuffer._id++);
    this.nodeUniform = nodeUniform;
  }

  public function get buffer():Dynamic {
    return this.nodeUniform.value;
  }

}

export default NodeUniformBuffer;