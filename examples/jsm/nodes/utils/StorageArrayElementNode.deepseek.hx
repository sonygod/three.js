import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import ArrayElementNode from './ArrayElementNode';

class StorageArrayElementNode extends ArrayElementNode {

	public function new(storageBufferNode:Dynamic, indexNode:Dynamic) {
		super(storageBufferNode, indexNode);
		this.isStorageArrayElementNode = true;
	}

	public function set storageBufferNode(value:Dynamic) {
		this.node = value;
	}

	public function get_storageBufferNode():Dynamic {
		return this.node;
	}

	public function setup(builder:Dynamic):Dynamic {
		if (builder.isAvailable('storageBuffer') === false) {
			if (!this.node.instanceIndex && this.node.bufferObject === true) {
				builder.setupPBO(this.node);
			}
		}
		return super.setup(builder);
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var snippet:Dynamic;
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

var storageElement = ShaderNode.nodeProxy(StorageArrayElementNode);
ShaderNode.addNodeElement('storageElement', storageElement);
Node.addNodeClass('StorageArrayElementNode', StorageArrayElementNode);