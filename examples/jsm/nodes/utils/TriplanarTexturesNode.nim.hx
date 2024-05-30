import Node;
import OperatorNode;
import NormalNode;
import PositionNode;
import TextureNode;
import ShaderNode;

class TriplanarTexturesNode extends Node {

	public var textureXNode:TextureNode;
	public var textureYNode:TextureNode;
	public var textureZNode:TextureNode;
	public var scaleNode:FloatNode;
	public var positionNode:PositionNode;
	public var normalNode:NormalNode;

	public function new(textureXNode:TextureNode, textureYNode:TextureNode = null, textureZNode:TextureNode = null, scaleNode:FloatNode = ShaderNode.float(1), positionNode:PositionNode = PositionNode.positionLocal, normalNode:NormalNode = NormalNode.normalLocal) {

		super("vec4");

		this.textureXNode = textureXNode;
		this.textureYNode = textureYNode;
		this.textureZNode = textureZNode;

		this.scaleNode = scaleNode;

		this.positionNode = positionNode;
		this.normalNode = normalNode;

	}

	public function setup():ShaderNode {

		var { textureXNode, textureYNode, textureZNode, scaleNode, positionNode, normalNode } = this;

		// Blending factor of triplanar mapping
		var bf = normalNode.abs().normalize();
		bf = bf.div(bf.dot(ShaderNode.vec3(1.0)));

		// Triplanar mapping
		var tx = positionNode.yz.mul(scaleNode);
		var ty = positionNode.zx.mul(scaleNode);
		var tz = positionNode.xy.mul(scaleNode);

		// Base color
		var textureX = textureXNode.value;
		var textureY = textureYNode != null ? textureYNode.value : textureX;
		var textureZ = textureZNode != null ? textureZNode.value : textureX;

		var cx = TextureNode.texture(textureX, tx).mul(bf.x);
		var cy = TextureNode.texture(textureY, ty).mul(bf.y);
		var cz = TextureNode.texture(textureZ, tz).mul(bf.z);

		return OperatorNode.add(cx, cy, cz);

	}

}

class ShaderNode {

	public static function float(value:Float):FloatNode {
		return new FloatNode(value);
	}

	public static function vec3(value:Float):Vec3Node {
		return new Vec3Node(value);
	}

}

class FloatNode {

	public var value:Float;

	public function new(value:Float) {
		this.value = value;
	}

}

class Vec3Node {

	public var value:Float;

	public function new(value:Float) {
		this.value = value;
	}

}

class TextureNode {

	public var value:Dynamic;

	public function new(value:Dynamic) {
		this.value = value;
	}

	public static function texture(texture:Dynamic, position:Dynamic):Dynamic {
		return texture.sample(position);
	}

}

class OperatorNode {

	public static function add(a:Dynamic, b:Dynamic, c:Dynamic):Dynamic {
		return a + b + c;
	}

}

class NormalNode {

	public static function normalLocal():NormalNode {
		return new NormalNode();
	}

	public function abs():NormalNode {
		return new NormalNode();
	}

	public function normalize():NormalNode {
		return new NormalNode();
	}

	public function dot(other:Vec3Node):Float {
		return other.value;
	}

	public function div(other:FloatNode):NormalNode {
		return new NormalNode();
	}

}

class PositionNode {

	public static function positionLocal():PositionNode {
		return new PositionNode();
	}

	public function yz():Dynamic {
		return new Vec2Node();
	}

	public function zx():Dynamic {
		return new Vec2Node();
	}

	public function xy():Dynamic {
		return new Vec2Node();
	}

	public function mul(other:FloatNode):Dynamic {
		return new Vec2Node();
	}

}

class Vec2Node {

	public function mul(other:FloatNode):Dynamic {
		return new Vec2Node();
	}

}