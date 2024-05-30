package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import ArrayElementNode;

class StorageArrayElementNode extends ArrayElementNode {

  public var isStorageArrayElementNode:Bool = true;

  public function new(storageBufferNode:Node, indexNode:Node) {
    super(storageBufferNode, indexNode);
  }

  private var _storageBufferNode:Node;

  public var storageBufferNode(get, set):Node;

  private function get_storageBufferNode():Node {
    return _storageBufferNode;
  }

  private function set_storageBufferNode(value:Node):Node {
    _storageBufferNode = value;
    return value;
  }

  override public function setup(builder:Builder):Void {
    if (!builder.isAvailable('storageBuffer')) {
      if (!_storageBufferNode.instanceIndex && _storageBufferNode.bufferObject) {
        builder.setupPBO(_storageBufferNode);
      }
    }
    super.setup(builder);
  }

  override public function generate(builder:Builder, output:Dynamic):String {
    var snippet:String;

    if (!builder.isAvailable('storageBuffer')) {
      if (!_storageBufferNode.instanceIndex && _storageBufferNode.bufferObject && !builder.context.assign) {
        snippet = builder.generatePBO(this);
      } else {
        snippet = _storageBufferNode.build(builder);
      }
    } else {
      snippet = super.generate(builder);
    }

    if (!builder.context.assign) {
      var type = getNodeType(builder);
      snippet = builder.format(snippet, type, output);
    }

    return snippet;
  }
}

@:forward
abstract StorageElementNode(StorageArrayElementNode) {
  public function new() {
    this = new StorageArrayElementNode(null, null);
  }
}

ShaderNode.addNodeElement('storageElement', StorageElementNode);
ShaderNode.addNodeClass('StorageArrayElementNode', StorageArrayElementNode);