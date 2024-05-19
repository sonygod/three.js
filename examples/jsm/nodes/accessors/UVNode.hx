package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.AttributeNode;
import three.js.shadernode.ShaderNode;

class UVNode extends AttributeNode {
    public var isUVNode:Bool = true;
    public var index:Int;

    public function new(?index:Int = 0) {
        super(null, 'vec2');
        this.index = index;
    }

    public function getAttributeName(?builder:Dynamic):String {
        var index:Int = this.index;
        return 'uv' + (index > 0 ? Std.string(index) : '');
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.index = this.index;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.index = data.index;
    }
}

private function uv(params:Array<Dynamic>):ShaderNode {
    return nodeObject(new UVNode(params));
}

addNodeClass('UVNode', UVNode);