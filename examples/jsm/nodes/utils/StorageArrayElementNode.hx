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

    public function setup(builder:Dynamic):Void {
        if (!builder.isAvailable('storageBuffer')) {
            if (!_storageBufferNode.instanceIndex && _storageBufferNode.bufferObject) {
                builder.setupPBO(_storageBufferNode);
            }
        }
        super.setup(builder);
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var snippet:String;
        var isAssignContext:Bool = builder.context.assign;

        if (!builder.isAvailable('storageBuffer')) {
            if (!_storageBufferNode.instanceIndex && _storageBufferNode.bufferObject && !isAssignContext) {
                snippet = builder.generatePBO(this);
            } else {
                snippet = _storageBufferNode.build(builder);
            }
        } else {
            snippet = super.generate(builder);
        }

        if (!isAssignContext) {
            var type:String = getNodeType(builder);
            snippet = builder.format(snippet, type, output);
        }

        return snippet;
    }
}

class StorageElementProxy {
    public static var storageElement(default, never):StorageArrayElementNode = nodeProxy(new StorageArrayElementNode(null, null));
}

ShaderNode.addNodeElement('storageElement', StorageElementProxy.storageElement);
Node.addNodeClass('StorageArrayElementNode', StorageArrayElementNode);