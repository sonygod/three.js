import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.PropertyNode;

class ParameterNode extends PropertyNode {

	public function new(nodeType:String, name:String = null) {
		super(nodeType, name);
		this.isParameterNode = true;
	}

	public function getHash():String {
		return this.uuid;
	}

	public function generate():String {
		return this.name;
	}

}

static function parameter(type:String, name:String):ShaderNode {
	return ShaderNode.nodeObject(new ParameterNode(type, name));
}

Node.addNodeClass('ParameterNode', ParameterNode);