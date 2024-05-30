import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { uv } from '../accessors/UVNode.hx';
import { normalView } from '../accessors/NormalNode.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { faceDirection } from './FrontFacingNode.hx';
import { addNodeElement, tslFn, nodeProxy, float, vec2 } from '../shadernode/ShaderNode.hx';

// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

const dHdxy_fwd = tslFn( ({ textureNode, bumpScale }) => {

	// It's used to preserve the same TextureNode instance
	inline function sampleTexture(callback) {
		return textureNode.cache().context( { getUV: (texNode) => callback(texNode.uvNode ?? uv()), forceUVContext: true } );
	}

	const Hll = float(sampleTexture((uvNode) => uvNode));

	return vec2(
		float(sampleTexture((uvNode) => uvNode.add(uvNode.dFdx()))).sub(Hll),
		float(sampleTexture((uvNode) => uvNode.add(uvNode.dFdy()))).sub(Hll)
	).mul(bumpScale);

});

// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)

const perturbNormalArb = tslFn((inputs) => {

	const { surf_pos, surf_norm, dHdxy } = inputs;

	// normalize is done to ensure that the bump map looks the same regardless of the texture's scale
	const vSigmaX = surf_pos.dFdx().normalize();
	const vSigmaY = surf_pos.dFdy().normalize();
	const vN = surf_norm; // normalized

	const R1 = vSigmaY.cross(vN);
	const R2 = vN.cross(vSigmaX);

	const fDet = vSigmaX.dot(R1).mul(faceDirection);

	const vGrad = fDet.sign().mul(dHdxy.x.mul(R1).add(dHdxy.y.mul(R2)));

	return fDet.abs().mul(surf_norm).sub(vGrad).normalize();

});

class BumpMapNode extends TempNode {

	public function new(textureNode:TextureNode, scaleNode:Node = null) {
		super('vec3');
		this.textureNode = textureNode;
		this.scaleNode = scaleNode;
	}

	override public function setup() {

		var bumpScale = if(this.scaleNode != null) this.scaleNode else 1;
		const dHdxy = dHdxy_fwd({ textureNode: this.textureNode, bumpScale });

		return perturbNormalArb({
			surf_pos: positionView,
			surf_norm: normalView,
			dHdxy
		});

	}

}

@:autoBuild
class BumpMapNodeBuild extends BumpMapNode {
}

export { BumpMapNode, BumpMapNodeBuild };

export const bumpMap = nodeProxy(BumpMapNode);

addNodeElement('bumpMap', bumpMap);

addNodeClass('BumpMapNode', BumpMapNode);