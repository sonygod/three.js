package three.js.examples.jsm.nodes.accessors;

import three.js.core.UniformNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class BufferNode extends UniformNode {

	public var isBufferNode:Bool = true;
	public var bufferType:Dynamic;
	public var bufferCount:Int;

	public function new(value:Dynamic, bufferType:Dynamic, ?bufferCount:Int = 0) {
		super(value, bufferType);
		this.bufferType = bufferType;
		this.bufferCount = bufferCount;
	}

	public function getInputType(builder:Dynamic):String {
		return 'buffer';
	}

}

// Export the BufferNode class
extern class BufferNode {
	@:native("default") public static var defaultNode:BufferNode;
}

// Export the buffer function
extern class BufferNode {
	public static function buffer(value:Dynamic, type:Dynamic, count:Int):ShaderNode {
		return nodeObject(new BufferNode(value, type, count));
	}
}

// Add the BufferNode class to the node registry
Node.addNodeClass('BufferNode', BufferNode);