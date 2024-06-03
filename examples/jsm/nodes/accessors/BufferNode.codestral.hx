import UniformNode;
import Node;
import ShaderNode;

class BufferNode extends UniformNode {
    public var isBufferNode: Bool = true;
    public var bufferType: String;
    public var bufferCount: Int;

    public function new(value: Dynamic, bufferType: String, bufferCount: Int = 0) {
        super(value, bufferType);
        this.bufferType = bufferType;
        this.bufferCount = bufferCount;
    }

    public function getInputType(/*builder*/): String {
        return 'buffer';
    }
}

function buffer(value: Dynamic, type: String, count: Int): ShaderNode {
    return ShaderNode.nodeObject(new BufferNode(value, type, count));
}

Node.addNodeClass('BufferNode', typeof(BufferNode));