package three.js.examples.jsm.nodes.utils;

import three.core.Node;
import three.math.OperatorNode;
import three.accessors.NormalNode;
import three.accessors.PositionNode;
import three.accessors.TextureNode;
import three.shadernode.ShaderNode;

class TriplanarTexturesNode extends Node {

	public var textureXNode:TextureNode;
	public var textureYNode:TextureNode;
	public var textureZNode:TextureNode;
	public var scaleNode:ShaderNode;
	public var positionNode:PositionNode;
	public var normalNode:NormalNode;

	public function new(textureXNode:TextureNode, ?textureYNode:TextureNode, ?textureZNode:TextureNode, ?scaleNode:ShaderNode = new ShaderNode(float(1)), ?positionNode:PositionNode = new PositionNode(), ?normalNode:NormalNode = new NormalNode()) {
		super('vec4');

		this.textureXNode = textureXNode;
		this.textureYNode = textureYNode;
		this.textureZNode = textureZNode;

		this.scaleNode = scaleNode;

		this.positionNode = positionNode;
		this.normalNode = normalNode;
	}

	public function setup():ShaderNode {
		var bf:ShaderNode = normalNode.abs().normalize();
		bf = bf.div(bf.dot(new Vec3(1.0)));

		var tx:ShaderNode = positionNode.yz.mul(scaleNode);
		var ty:ShaderNode = positionNode.zx.mul(scaleNode);
		var tz:ShaderNode = positionNode.xy.mul(scaleNode);

		var textureX:ShaderNode = textureXNode.value;
		var textureY:ShaderNode = textureYNode != null ? textureYNode.value : textureX;
		var textureZ:ShaderNode = textureZNode != null ? textureZNode.value : textureX;

		var cx:ShaderNode = texture(textureX, tx).mul(bf.x);
		var cy:ShaderNode = texture(textureY, ty).mul(bf.y);
		var cz:ShaderNode = texture(textureZ, tz).mul(bf.z);

		return add(cx, cy, cz);
	}

}

// exports
@:keep
var triplanarTextures = nodeProxy(TriplanarTexturesNode);
@:keep
function triplanarTexture(params:Array<Dynamic>) {
	return triplanarTextures.apply(null, params);
}

addNodeElement('triplanarTexture', triplanarTexture);
addNodeClass('TriplanarTexturesNode', TriplanarTexturesNode);