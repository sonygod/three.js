import TempNode from "../core/TempNode";
import Node from "../core/Node";
import { uv } from "../accessors/UVNode";
import { normalView } from "../accessors/NormalNode";
import { positionView } from "../accessors/PositionNode";
import { faceDirection } from "./FrontFacingNode";
import { addNodeClass, addNodeElement, float, vec2, tslFn, nodeProxy } from "../shadernode/ShaderNode";

// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

var dHdxy_fwd = tslFn(function({ textureNode, bumpScale }) {

	// It's used to preserve the same TextureNode instance
	var sampleTexture = function(callback) {
		return textureNode.cache().context({
			getUV: function(texNode) {
				return callback(texNode.uvNode != null ? texNode.uvNode : uv());
			},
			forceUVContext: true
		});
	}

	var Hll = float(sampleTexture(function(uvNode) {
		return uvNode;
	}));

	return vec2(
		float(sampleTexture(function(uvNode) {
			return uvNode.add(uvNode.dFdx());
		})).sub(Hll),
		float(sampleTexture(function(uvNode) {
			return uvNode.add(uvNode.dFdy());
		})).sub(Hll)
	).mul(bumpScale);

});

// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)

var perturbNormalArb = tslFn(function(inputs) {

	var surf_pos = inputs.surf_pos;
	var surf_norm = inputs.surf_norm;
	var dHdxy = inputs.dHdxy;

	// normalize is done to ensure that the bump map looks the same regardless of the texture's scale
	var vSigmaX = surf_pos.dFdx().normalize();
	var vSigmaY = surf_pos.dFdy().normalize();
	var vN = surf_norm; // normalized

	var R1 = vSigmaY.cross(vN);
	var R2 = vN.cross(vSigmaX);

	var fDet = vSigmaX.dot(R1).mul(faceDirection);

	var vGrad = fDet.sign().mul(dHdxy.x.mul(R1).add(dHdxy.y.mul(R2)));

	return fDet.abs().mul(surf_norm).sub(vGrad).normalize();

});

class BumpMapNode extends TempNode {

	public textureNode:Node;
	public scaleNode:Node;

	public constructor(textureNode:Node, scaleNode:Node = null) {
		super("vec3");
		this.textureNode = textureNode;
		this.scaleNode = scaleNode;
	}

	public setup():Node {
		var bumpScale = this.scaleNode != null ? this.scaleNode : 1;
		var dHdxy = dHdxy_fwd({ textureNode: this.textureNode, bumpScale: bumpScale });

		return perturbNormalArb({
			surf_pos: positionView,
			surf_norm: normalView,
			dHdxy: dHdxy
		});
	}
}

export default BumpMapNode;

export var bumpMap = nodeProxy(BumpMapNode);

addNodeElement("bumpMap", bumpMap);

addNodeClass("BumpMapNode", BumpMapNode);