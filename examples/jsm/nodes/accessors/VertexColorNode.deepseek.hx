import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.Vector4;

class VertexColorNode extends AttributeNode {

	public function new(index:Int = 0) {
		super(null, 'vec4');
		this.isVertexColorNode = true;
		this.index = index;
	}

	public function getAttributeName(builder:ShaderNode.Builder):String {
		var index = this.index;
		return 'color' + (index > 0 ? index : '');
	}

	public function generate(builder:ShaderNode.Builder):ShaderNode {
		var attributeName = this.getAttributeName(builder);
		var geometryAttribute = builder.hasGeometryAttribute(attributeName);
		var result:ShaderNode;
		if (geometryAttribute == true) {
			result = super.generate(builder);
		} else {
			// Vertex color fallback should be white
			result = builder.generateConst(this.nodeType, new Vector4(1, 1, 1, 1));
		}
		return result;
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

static function vertexColor(params:Array<Dynamic>):ShaderNode {
	return ShaderNode.nodeObject(new VertexColorNode(params));
}

Node.addNodeClass('VertexColorNode', VertexColorNode);