import js.html.Node;
import js.html.Element;
import js.html.HTMLDocument;
import js.html.HTMLUnknownElement;
import js.html.Window;

import js.Browser.window;

import nodes.core.Node;
import nodes.shadernode.ShaderNode;
import nodes.utils.ArrayElementNode;

class StorageArrayElementNode extends ArrayElementNode {
    public var isStorageArrayElementNode:Bool = true;

    public function new(storageBufferNode:Node, indexNode:Node) {
        super(storageBufferNode, indexNode);
    }

    public function set storageBufferNode(value:Node):Void {
        this.node = value;
    }

    public function get storageBufferNode():Node {
        return this.node;
    }

    public function setup(builder:Builder):Bool {
        if (builder.isAvailable('storageBuffer') === false) {
            if (!this.node.instanceIndex && this.node.bufferObject === true) {
                builder.setupPBO(this.node);
            }
        }

        return super.setup(builder);
    }

    public function generate(builder:Builder, output:Output):Dynamic {
        var snippet;
        var isAssignContext = builder.context.assign;

        if (builder.isAvailable('storageBuffer') === false) {
            var node = this.node;

            if (!node.instanceIndex && this.node.bufferObject === true && isAssignContext !== true) {
                snippet = builder.generatePBO(this);
            } else {
                snippet = node.build(builder);
            }
        } else {
            snippet = super.generate(builder);
        }

        if (isAssignContext !== true) {
            var type = this.getNodeType(builder);
            snippet = builder.format(snippet, type, output);
        }

        return snippet;
    }
}

function nodeProxy(node:Class<Node>):Node {
    return Type.createEmptyInstance(node, []);
}

function addNodeElement(name:String, node:Node):Void {
    // Implementation depends on the context.
}

function addNodeClass(name:String, node:Class<Node>):Void {
    // Implementation depends on the context.
}

var storageElement = nodeProxy(StorageArrayElementNode);
addNodeElement('storageElement', storageElement);
addNodeClass('StorageArrayElementNode', StorageArrayElementNode);