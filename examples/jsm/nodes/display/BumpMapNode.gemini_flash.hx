import TempNode from "../core/TempNode";
import Node from "../core/Node";
import UVNode from "../accessors/UVNode";
import NormalNode from "../accessors/NormalNode";
import PositionNode from "../accessors/PositionNode";
import FrontFacingNode from "./FrontFacingNode";
import ShaderNode, { addNodeElement, tslFn, nodeProxy, float, vec2 } from "../shadernode/ShaderNode";

// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

var dHdxy_fwd = tslFn((textureNode, bumpScale) => {

	// It's used to preserve the same TextureNode instance
	var sampleTexture = (callback) => textureNode.cache().context({getUV: (texNode) => callback(texNode.uvNode || UVNode.uv()), forceUVContext: true});

	var Hll = float(sampleTexture((uvNode) => uvNode));

	return vec2(
		float(sampleTexture((uvNode) => uvNode.add(uvNode.dFdx()))).sub(Hll),
		float(sampleTexture((uvNode) => uvNode.add(uvNode.dFdy()))).sub(Hll)
	).mul(bumpScale);

});

// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)

var perturbNormalArb = tslFn((inputs) => {

	var { surf_pos, surf_norm, dHdxy } = inputs;

	// normalize is done to ensure that the bump map looks the same regardless of the texture's scale
	var vSigmaX = surf_pos.dFdx().normalize();
	var vSigmaY = surf_pos.dFdy().normalize();
	var vN = surf_norm; // normalized

	var R1 = vSigmaY.cross(vN);
	var R2 = vN.cross(vSigmaX);

	var fDet = vSigmaX.dot(R1).mul(FrontFacingNode.faceDirection);

	var vGrad = fDet.sign().mul(dHdxy.x.mul(R1).add(dHdxy.y.mul(R2)));

	return fDet.abs().mul(surf_norm).sub(vGrad).normalize();

});

class BumpMapNode extends TempNode {

	public textureNode: Node;
	public scaleNode: Node;

	public constructor(textureNode: Node, scaleNode: Node = null) {

		super("vec3");

		this.textureNode = textureNode;
		this.scaleNode = scaleNode;

	}

	public setup(): Node {

		var bumpScale = this.scaleNode != null ? this.scaleNode : 1;
		var dHdxy = dHdxy_fwd(this.textureNode, bumpScale);

		return perturbNormalArb({
			surf_pos: PositionNode.positionView,
			surf_norm: NormalNode.normalView,
			dHdxy
		});

	}

}

export default BumpMapNode;

export var bumpMap = nodeProxy(BumpMapNode);

addNodeElement("bumpMap", bumpMap);

Node.addNodeClass("BumpMapNode", BumpMapNode);