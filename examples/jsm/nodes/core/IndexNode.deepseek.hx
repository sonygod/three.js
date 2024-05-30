import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.VaryingNode.varying;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeImmutable;

class IndexNode extends Node {

	public static var VERTEX:String = 'vertex';
	public static var INSTANCE:String = 'instance';

	public var scope:String;
	public var isInstanceIndexNode:Bool = true;

	public function new(scope:String) {
		super('uint');
		this.scope = scope;
	}

	public function generate(builder:Dynamic):Dynamic {
		var nodeType = this.getNodeType(builder);
		var scope = this.scope;
		var propertyName:Dynamic;

		if (scope == IndexNode.VERTEX) {
			propertyName = builder.getVertexIndex();
		} else if (scope == IndexNode.INSTANCE) {
			propertyName = builder.getInstanceIndex();
		} else {
			throw 'THREE.IndexNode: Unknown scope: ' + scope;
		}

		var output:Dynamic;

		if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
			output = propertyName;
		} else {
			var nodeVarying = varying(this);
			output = nodeVarying.build(builder, nodeType);
		}

		return output;
	}

}

var vertexIndex = nodeImmutable(IndexNode, IndexNode.VERTEX);
var instanceIndex = nodeImmutable(IndexNode, IndexNode.INSTANCE);

Node.addNodeClass('IndexNode', IndexNode);