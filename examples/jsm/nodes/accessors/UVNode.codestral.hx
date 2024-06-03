import three.nodes.core.Node;
import three.nodes.core.AttributeNode;
import three.nodes.shadernode.ShaderNode;

class UVNode extends AttributeNode {

    public var isUVNode:Bool = true;
    public var index:Int;

    public function new(index:Int = 0) {
        super(null, 'vec2');
        this.index = index;
    }

    public function getAttributeName():String {
        return 'uv' + (if (this.index > 0) this.index else '');
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

Node.addNodeClass('UVNode', haxe.rtti.Type.getClass<UVNode>());

function uv(params:Dynamic...):ShaderNode {
    return ShaderNode.nodeObject(new UVNode(params[0]));
}