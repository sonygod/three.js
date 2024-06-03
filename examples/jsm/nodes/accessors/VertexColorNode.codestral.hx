import three.nodes.core.Node;
import three.nodes.core.AttributeNode;
import three.nodes.shadernode.ShaderNode;
import three.math.Vector4;

class VertexColorNode extends AttributeNode {

	public var index:Int;
	public var isVertexColorNode:Bool;

	public function new(index:Int = 0) {
		super(null, 'vec4');
		this.isVertexColorNode = true;
		this.index = index;
	}

	public function getAttributeName():String {
		return 'color' + (this.index > 0 ? this.index.toString() : '');
	}

	override public function generate(builder):Dynamic {
		var attributeName:String = this.getAttributeName();
		var geometryAttribute:Bool = builder.hasGeometryAttribute(attributeName);

		var result:Dynamic;

		if (geometryAttribute === true) {
			result = super.generate(builder);
		} else {
			result = builder.generateConst(this.nodeType, new Vector4(1, 1, 1, 1));
		}

		return result;
	}

	override public function serialize(data:Dynamic) {
		super.serialize(data);
		data.index = this.index;
	}

	override public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.index = data.index;
	}
}

function vertexColor(...params):Dynamic {
	return ShaderNode.nodeObject(new VertexColorNode(params));
}

Node.addNodeClass('VertexColorNode', VertexColorNode);