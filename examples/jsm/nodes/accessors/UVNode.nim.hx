import three.js.examples.jsm.nodes.core.Node.addNodeClass;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeObject;

class UVNode extends AttributeNode {

	public var isUVNode:Bool = true;

	public var index:Int;

	public function new(index:Int = 0) {
		super(null, 'vec2');
		this.index = index;
	}

	public function getAttributeName(/*builder*/) {
		var index = this.index;
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

export default UVNode;

export function uv(params:Array<Dynamic>) {
	return nodeObject(new UVNode(ArrayTools.unshift(params)));
}

addNodeClass('UVNode', UVNode);