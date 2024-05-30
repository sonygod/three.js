package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.AttributeNode;

class UVNode extends AttributeNode {
    public var isUVNode:Bool = true;
    public var index:Int;

    public function new(?index:Int = 0) {
        super(null, 'vec2');
        this.index = index;
    }

    public function getAttributeName(builder:Dynamic):String {
        return 'uv' + (index > 0 ? Std.string(index) : '');
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.index = index;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        index = data.index;
    }
}

// Export the UVNode class
export UVNode;

// Create a function to create a new UVNode instance
export var uv = function UVNodeFactory(?params:Array<Dynamic>) {
    return NodeObject(new UVNode(params));
}

// Register the UVNode class
Node.addNodeClass('UVNode', UVNode);