import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class BufferNode extends UniformNode {

	public function new(value:Dynamic, bufferType:String, bufferCount:Int = 0) {
		super(value, bufferType);

		this.isBufferNode = true;

		this.bufferType = bufferType;
		this.bufferCount = bufferCount;
	}

	public function getInputType(/*builder*/) {
		return 'buffer';
	}

}

static function buffer(value:Dynamic, type:String, count:Int) {
	return ShaderNode.nodeObject(new BufferNode(value, type, count));
}

Node.addNodeClass('BufferNode', BufferNode);