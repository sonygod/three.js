import Node from "./Node";
import VaryingNode from "./VaryingNode";
import ShaderNode from "../shadernode/ShaderNode";

class IndexNode extends Node {

	public static readonly VERTEX:String = "vertex";
	public static readonly INSTANCE:String = "instance";

	public scope:String;
	public isInstanceIndexNode:Bool;

	public function new(scope:String) {
		super("uint");
		this.scope = scope;
		this.isInstanceIndexNode = true;
	}

	public function generate(builder:ShaderNode.Builder):String {
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

		var output:String;

		if (builder.shaderStage == "vertex" || builder.shaderStage == "compute") {
			output = propertyName;
		} else {
			var nodeVarying = new VaryingNode(this);
			output = nodeVarying.build(builder, nodeType);
		}

		return output;
	}

}

var vertexIndex = ShaderNode.nodeImmutable(IndexNode, IndexNode.VERTEX);
var instanceIndex = ShaderNode.nodeImmutable(IndexNode, IndexNode.INSTANCE);

ShaderNode.addNodeClass("IndexNode", IndexNode);

export default IndexNode;
export { vertexIndex, instanceIndex };