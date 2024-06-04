import Node from "./Node";
import VaryingNode from "./VaryingNode";
import ShaderNode from "../shadernode/ShaderNode";

class IndexNode extends Node {

	public var scope:String;

	public var isInstanceIndexNode:Bool = true;

	public function new(scope:String) {
		super("uint");
		this.scope = scope;
	}

	public function generate(builder:Dynamic):Dynamic {
		var nodeType = this.getNodeType(builder);
		var scope = this.scope;

		var propertyName:String;

		if (scope == IndexNode.VERTEX) {
			propertyName = builder.getVertexIndex();
		} else if (scope == IndexNode.INSTANCE) {
			propertyName = builder.getInstanceIndex();
		} else {
			throw new Error("THREE.IndexNode: Unknown scope: " + scope);
		}

		var output:Dynamic;

		if (builder.shaderStage == "vertex" || builder.shaderStage == "compute") {
			output = propertyName;
		} else {
			var nodeVarying = new VaryingNode(this);
			output = nodeVarying.build(builder, nodeType);
		}

		return output;
	}

	static public var VERTEX:String = "vertex";
	static public var INSTANCE:String = "instance";

}

var vertexIndex = ShaderNode.nodeImmutable(IndexNode, IndexNode.VERTEX);
var instanceIndex = ShaderNode.nodeImmutable(IndexNode, IndexNode.INSTANCE);

Node.addNodeClass("IndexNode", IndexNode);