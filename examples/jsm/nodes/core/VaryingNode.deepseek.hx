import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeShaderStage;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class VaryingNode extends Node {

	public function new(node:Node, name:String = null) {
		super();
		this.node = node;
		this.name = name;
		this.isVaryingNode = true;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:ShaderNode.Builder):String {
		return this.name ? this.name : super.getHash(builder);
	}

	public function getNodeType(builder:ShaderNode.Builder):String {
		return this.node.getNodeType(builder);
	}

	public function setupVarying(builder:ShaderNode.Builder):ShaderNode.Varying {
		var properties = builder.getNodeProperties(this);
		var varying = properties.varying;
		if (varying == null) {
			var name = this.name;
			var type = this.getNodeType(builder);
			properties.varying = varying = builder.getVaryingFromNode(this, name, type);
			properties.node = this.node;
		}
		varying.needsInterpolation || (varying.needsInterpolation = (builder.shaderStage == 'fragment'));
		return varying;
	}

	public function setup(builder:ShaderNode.Builder):Void {
		this.setupVarying(builder);
	}

	public function generate(builder:ShaderNode.Builder):String {
		var type = this.getNodeType(builder);
		var varying = this.setupVarying(builder);
		var propertyName = builder.getPropertyName(varying, NodeShaderStage.VERTEX);
		builder.flowNodeFromShaderStage(NodeShaderStage.VERTEX, this.node, type, propertyName);
		return builder.getPropertyName(varying);
	}

}

var varying = ShaderNode.nodeProxy(VaryingNode);
ShaderNode.addNodeElement('varying', varying);
Node.addNodeClass('VaryingNode', VaryingNode);