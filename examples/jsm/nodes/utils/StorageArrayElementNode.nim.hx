import three.js.examples.jsm.nodes.core.Node.addNodeClass;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeProxy;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.addNodeElement;
import three.js.examples.jsm.nodes.utils.ArrayElementNode;

class StorageArrayElementNode extends ArrayElementNode {

	public var isStorageArrayElementNode:Bool = true;

	public function new(storageBufferNode:Node, indexNode:Node) {
		super(storageBufferNode, indexNode);
	}

	public function set storageBufferNode(value:Node) {
		this.node = value;
	}

	public function get storageBufferNode():Node {
		return this.node;
	}

	public function setup(builder:ShaderBuilder):Void {
		if (builder.isAvailable('storageBuffer') === false) {
			if (!this.node.instanceIndex && this.node.bufferObject === true) {
				builder.setupPBO(this.node);
			}
		}
		super.setup(builder);
	}

	public function generate(builder:ShaderBuilder, output:String):String {
		var snippet:String;
		var isAssignContext:Bool = builder.context.assign;

		if (builder.isAvailable('storageBuffer') === false) {
			var node:Node = this.node;
			if (!node.instanceIndex && this.node.bufferObject === true && isAssignContext !== true) {
				snippet = builder.generatePBO(this);
			} else {
				snippet = node.build(builder);
			}
		} else {
			snippet = super.generate(builder);
		}

		if (isAssignContext !== true) {
			var type:String = this.getNodeType(builder);
			snippet = builder.format(snippet, type, output);
		}
		return snippet;
	}
}

@:native("StorageArrayElementNode")
class StorageArrayElementNodeHaxe extends StorageArrayElementNode {}

@:native("storageElement")
var storageElement = nodeProxy(StorageArrayElementNodeHaxe);

addNodeElement('storageElement', storageElement);

addNodeClass('StorageArrayElementNode', StorageArrayElementNodeHaxe);