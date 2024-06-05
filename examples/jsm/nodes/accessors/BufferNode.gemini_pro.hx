import UniformNode from "../core/UniformNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class BufferNode extends UniformNode {
  public var isBufferNode:Bool = true;
  public var bufferType:String;
  public var bufferCount:Int;

  public function new(value:Dynamic, bufferType:String, bufferCount:Int = 0) {
    super(value, bufferType);
    this.bufferType = bufferType;
    this.bufferCount = bufferCount;
  }

  override public function getInputType(?builder:Dynamic):String {
    return "buffer";
  }
}

class BufferNodeBuilder {
  public static function buffer(value:Dynamic, type:String, count:Int):ShaderNode {
    return new BufferNode(value, type, count);
  }
}

Node.addNodeClass("BufferNode", BufferNode);
export {BufferNode, BufferNodeBuilder};