package three.js.examples.jsm.nodes.accessors;

import three.js.core.UniformNode;
import three.js.core.Node;
import three.js.shadernode.ShADER_NODE;

class BufferNode extends UniformNode {

    public var isBufferNode:Bool = true;
    public var bufferType:String;
    public var bufferCount:Int;

    public function new(value:Dynamic, bufferType:String, bufferCount:Int = 0) {
        super(value, bufferType);
        this.bufferType = bufferType;
        this.bufferCount = bufferCount;
    }

    override public function getInputType(builder:Dynamic) {
        return 'buffer';
    }
}

// export default BufferNode;
// export const buffer = (value, type, count) => nodeObject(new BufferNode(value, type, count));

// Haxe does not support default exports, so we'll use a static function instead
class BufferNodeTools {
    public static function buffer(value:Dynamic, type:String, count:Int) {
        return nodeObject(new BufferNode(value, type, count));
    }
}

// Register the node class
Node.addNodeClass('BufferNode', BufferNode);