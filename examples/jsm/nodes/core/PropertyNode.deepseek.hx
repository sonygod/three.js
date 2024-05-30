import Node;
import ShaderNode;

class PropertyNode extends Node {

	public function new(nodeType:String, name:String = null, varying:Bool = false) {
		super(nodeType);

		this.name = name;
		this.varying = varying;

		this.isPropertyNode = true;
	}

	public function getHash(builder:ShaderNode.Builder):String {
		return this.name ? this.name : super.getHash(builder);
	}

	public function isGlobal(builder:ShaderNode.Builder):Bool {
		return true;
	}

	public function generate(builder:ShaderNode.Builder):String {
		var nodeVar:ShaderNode.Var;

		if (this.varying) {
			nodeVar = builder.getVaryingFromNode(this, this.name);
			nodeVar.needsInterpolation = true;
		} else {
			nodeVar = builder.getVarFromNode(this, this.name);
		}

		return builder.getPropertyName(nodeVar);
	}
}

static function property(type:String, name:String):ShaderNode.Object {
	return ShaderNode.nodeObject(new PropertyNode(type, name));
}

static function varyingProperty(type:String, name:String):ShaderNode.Object {
	return ShaderNode.nodeObject(new PropertyNode(type, name, true));
}

static function diffuseColor():ShaderNode.Object {
	return ShaderNode.nodeImmutable(PropertyNode, 'vec4', 'DiffuseColor');
}

// ... 其他的静态函数，与JavaScript代码中的类似

Node.addNodeClass('PropertyNode', PropertyNode);