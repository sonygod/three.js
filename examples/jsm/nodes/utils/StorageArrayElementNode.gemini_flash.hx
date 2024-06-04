import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import ArrayElementNode from "./ArrayElementNode";

class StorageArrayElementNode extends ArrayElementNode {
  public var isStorageArrayElementNode:Bool = true;

  public function new(storageBufferNode:ShaderNode, indexNode:ShaderNode) {
    super(storageBufferNode, indexNode);
  }

  public var storageBufferNode(get, set):ShaderNode;

  private function get_storageBufferNode():ShaderNode {
    return this.node;
  }

  private function set_storageBufferNode(value:ShaderNode):Void {
    this.node = value;
  }

  public function setup(builder:ShaderNode.Builder):Bool {
    if (!builder.isAvailable("storageBuffer")) {
      if (!this.node.instanceIndex && this.node.bufferObject) {
        builder.setupPBO(this.node);
      }
    }
    return super.setup(builder);
  }

  public function generate(builder:ShaderNode.Builder, output:String):String {
    var snippet:String;
    var isAssignContext:Bool = builder.context.assign;

    if (!builder.isAvailable("storageBuffer")) {
      if (!this.node.instanceIndex && this.node.bufferObject && !isAssignContext) {
        snippet = builder.generatePBO(this);
      } else {
        snippet = this.node.build(builder);
      }
    } else {
      snippet = super.generate(builder);
    }

    if (!isAssignContext) {
      var type:String = this.getNodeType(builder);
      snippet = builder.format(snippet, type, output);
    }

    return snippet;
  }
}

class StorageElement extends ShaderNode.Proxy<StorageArrayElementNode> {
  public function new() {
    super(StorageArrayElementNode);
  }
}

var storageElement:ShaderNode.Proxy<StorageArrayElementNode> = new StorageElement();

ShaderNode.addNodeElement("storageElement", storageElement);
Node.addNodeClass("StorageArrayElementNode", StorageArrayElementNode);