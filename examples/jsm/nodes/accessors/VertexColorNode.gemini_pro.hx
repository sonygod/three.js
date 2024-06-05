import three.core.Node;
import three.core.AttributeNode;
import three.shadernode.ShaderNode;
import three.math.Vector4;

class VertexColorNode extends AttributeNode {

	public var isVertexColorNode:Bool = true;

	public var index:Int = 0;

	public function new(index:Int = 0) {
		super(null, "vec4");
		this.index = index;
	}

	public function getAttributeName(builder:Dynamic):String {
		var index = this.index;
		return "color" + (index > 0 ? index : "");
	}

	public function generate(builder:Dynamic):Dynamic {
		var attributeName = this.getAttributeName(builder);
		var geometryAttribute = builder.hasGeometryAttribute(attributeName);

		var result:Dynamic;

		if (geometryAttribute) {
			result = super.generate(builder);
		} else {
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

class VertexColorNodeWrapper {
	public static function vertexColor(params:Array<Dynamic>):Dynamic {
		return nodeObject(new VertexColorNode(params[0]));
	}
}

addNodeClass("VertexColorNode", VertexColorNode);