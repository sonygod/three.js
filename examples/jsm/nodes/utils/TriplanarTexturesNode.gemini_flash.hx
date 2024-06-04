import Node from "../core/Node";
import OperatorNode from "../math/OperatorNode";
import NormalNode from "../accessors/NormalNode";
import PositionNode from "../accessors/PositionNode";
import TextureNode from "../accessors/TextureNode";
import ShaderNode from "../shadernode/ShaderNode";

class TriplanarTexturesNode extends Node {
	public textureXNode:Node;
	public textureYNode:Node;
	public textureZNode:Node;
	public scaleNode:Node;
	public positionNode:Node;
	public normalNode:Node;

	public function new(textureXNode:Node, textureYNode:Node = null, textureZNode:Node = null, scaleNode:Node = ShaderNode.float(1), positionNode:Node = PositionNode.positionLocal, normalNode:Node = NormalNode.normalLocal) {
		super("vec4");
		this.textureXNode = textureXNode;
		this.textureYNode = textureYNode;
		this.textureZNode = textureZNode;
		this.scaleNode = scaleNode;
		this.positionNode = positionNode;
		this.normalNode = normalNode;
	}

	public function setup():Node {
		var textureXNode = this.textureXNode;
		var textureYNode = this.textureYNode;
		var textureZNode = this.textureZNode;
		var scaleNode = this.scaleNode;
		var positionNode = this.positionNode;
		var normalNode = this.normalNode;

		// Ref: https://github.com/keijiro/StandardTriplanar

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

export default TriplanarTexturesNode;

export function triplanarTextures(...params:Array<Node>):TriplanarTexturesNode {
	return new TriplanarTexturesNode(...params);
}

export function triplanarTexture(...params:Array<Node>):TriplanarTexturesNode {
	return triplanarTextures(...params);
}

ShaderNode.addNodeElement("triplanarTexture", triplanarTexture);

ShaderNode.addNodeClass("TriplanarTexturesNode", TriplanarTexturesNode);