import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class UVNode extends AttributeNode {

	public function new(index:Int = 0) {
		super(null, 'vec2');
		this.isUVNode = true;
		this.index = index;
	}

	public function getAttributeName(builder:Dynamic):String {
		var index = this.index;
		return 'uv' + (index > 0 ? index : '');
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.index = this.index;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.index = data.index;
	}

}

static function uv(params:Array<Dynamic>):ShaderNode {
	return ShaderNode.nodeObject(new UVNode(params));
}

Node.addNodeClass('UVNode', UVNode);