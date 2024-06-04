import core.Node;
import core.AttributeNode;
import shadernode.ShaderNode;

class UVNode extends AttributeNode {

	public var isUVNode:Bool;
	public var index:Int;

	public function new(index:Int = 0) {
		super(null, "vec2");
		this.isUVNode = true;
		this.index = index;
	}

	public function getAttributeName(?builder:Dynamic):String {
		return "uv" + (index > 0 ? index : "");
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.index = index;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.index = data.index;
	}

}

var uv = function(...params:Array<Dynamic>):ShaderNode {
	return ShaderNode.nodeObject(new UVNode(...params));
}

Node.addNodeClass("UVNode", UVNode);