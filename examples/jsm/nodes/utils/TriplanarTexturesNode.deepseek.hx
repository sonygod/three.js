import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.math.OperatorNode;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.accessors.TextureNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class TriplanarTexturesNode extends Node {

	public function new(textureXNode:TextureNode, textureYNode:TextureNode = null, textureZNode:TextureNode = null, scaleNode:Float = 1, positionNode:PositionNode = positionLocal, normalNode:NormalNode = normalLocal) {
		super('vec4');

		this.textureXNode = textureXNode;
		this.textureYNode = textureYNode;
		this.textureZNode = textureZNode;

		this.scaleNode = scaleNode;

		this.positionNode = positionNode;
		this.normalNode = normalNode;
	}

	public function setup():Void {
		var textureXNode = this.textureXNode;
		var textureYNode = this.textureYNode;
		var textureZNode = this.textureZNode;
		var scaleNode = this.scaleNode;
		var positionNode = this.positionNode;
		var normalNode = this.normalNode;

		// Ref: https://github.com/keijiro/StandardTriplanar

		// Blending factor of triplanar mapping
		var bf = normalNode.abs().normalize();
		bf = bf.div(bf.dot(new Vec3(1.0)));

		// Triplanar mapping
		var tx = positionNode.yz.mul(scaleNode);
		var ty = positionNode.zx.mul(scaleNode);
		var tz = positionNode.xy.mul(scaleNode);

		// Base color
		var textureX = textureXNode.value;
		var textureY = textureYNode != null ? textureYNode.value : textureX;
		var textureZ = textureZNode != null ? textureZNode.value : textureX;

		var cx = texture(textureX, tx).mul(bf.x);
		var cy = texture(textureY, ty).mul(bf.y);
		var cz = texture(textureZ, tz).mul(bf.z);

		return add(cx, cy, cz);
	}
}

static function triplanarTextures(...params):TriplanarTexturesNode {
	return new TriplanarTexturesNode(params);
}

static function triplanarTexture(...params):Void {
	triplanarTextures(params);
}

ShaderNode.addNodeElement('triplanarTexture', triplanarTexture);

Node.addNodeClass('TriplanarTexturesNode', TriplanarTexturesNode);