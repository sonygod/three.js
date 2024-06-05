import core.Node;
import core.AttributeNode;
import shadernode.ShaderNode;

class UVNode extends AttributeNode {

	public var isUVNode:Bool = true;
	public var index:Int;

	public function new(index:Int = 0) {
		super(null, "vec2");
		this.index = index;
	}

	public function getAttributeName(builder:Dynamic):String {
		return "uv" + (index > 0 ? index : "");
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.index = index;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.index = data.index;
	}

}

class UVNodeHelper {

	public static function uv(params:Array<Dynamic>):ShaderNode {
		return ShaderNode.nodeObject(new UVNode(params[0]));
	}

}

Node.addNodeClass("UVNode", UVNode);

export { UVNode, UVNodeHelper };