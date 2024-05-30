import js.Node.ArrayElementNode;
import js.Node.Node;
import js.Node.ShaderNode.addNodeElement;
import js.Node.ShaderNode.nodeProxy;

class StorageArrayElementNode extends ArrayElementNode {
	public var storageBufferNode:Node;

	public function new(storageBufferNode:Node, indexNode:Node) {
		super(storageBufferNode, indexNode);
		this.isStorageArrayElementNode = true;
	}

	public function setup(builder:Node.Builder):Void {
		if (!builder.isAvailable('storageBuffer')) {
			if (!this.storageBufferNode.instanceIndex && this.storageBufferNode.bufferObject) {
				builder.setupPBO(this.storageBufferNode);
			}
		}
		super.setup(builder);
	}

	public function generate(builder:Node.Builder, output:String):String {
		var snippet:String;
		var isAssignContext = builder.context.assign;

		if (!builder.isAvailable('storageBuffer')) {
			if (!this.storageBufferNode.instanceIndex && this.storageBufferNode.bufferObject && !isAssignContext) {
				snippet = builder.generatePBO(this);
			} else {
				snippet = this.storageBufferNode.build(builder);
			}
		} else {
			snippet = super.generate(builder);
		}

		if (!isAssignContext) {
			var type = this.getNodeType(builder);
			snippet = builder.format(snippet, type, output);
		}

		return snippet;
	}
}

@:expose("storageElement")
var storageElement = nodeProxy(StorageArrayElementNode);

addNodeElement('storageElement', storageElement);

@:jsRequire("StorageArrayElementNode")
class StorageArrayElementNode_Class {
	public static function main() {
		addNodeClass('StorageArrayElementNode', StorageArrayElementNode);
	}
}