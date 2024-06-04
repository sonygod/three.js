import node.Node;
import node.AttributeNode;
import shadernode.ShaderNode;
import three.Vector4;

class VertexColorNode extends AttributeNode {

	public var isVertexColorNode:Bool = true;

	public var index:Int;

	public function new(index:Int = 0) {
		super(null, 'vec4');
		this.index = index;
	}

	public function getAttributeName(builder:Dynamic):String {
		return 'color' + (index > 0 ? index.toString() : '');
	}

	public function generate(builder:Dynamic):Dynamic {
		var attributeName = getAttributeName(builder);
		var geometryAttribute = builder.hasGeometryAttribute(attributeName);
		var result:Dynamic;
		if (geometryAttribute) {
			result = super.generate(builder);
		} else {
			result = builder.generateConst(nodeType, new Vector4(1, 1, 1, 1));
		}
		return result;
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.index = index;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		index = data.index;
	}

}

class VertexColorNodeHelper {
	public static function vertexColor(params:Array<Dynamic>):Dynamic {
		return ShaderNode.nodeObject(new VertexColorNode(...params));
	}
}

Node.addNodeClass('VertexColorNode', VertexColorNode);

export var VertexColorNode = VertexColorNode;
export var vertexColor = VertexColorNodeHelper.vertexColor;