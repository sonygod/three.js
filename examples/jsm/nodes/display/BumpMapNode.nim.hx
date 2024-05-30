import TempNode from '../core/TempNode.js';
import { addNodeClass } from '../core/Node.js';
import { uv } from '../accessors/UVNode.js';
import { normalView } from '../accessors/NormalNode.js';
import { positionView } from '../accessors/PositionNode.js';
import { faceDirection } from './FrontFacingNode.js';
import { addNodeElement, tslFn, nodeProxy, float, vec2 } from '../shadernode/ShaderNode.js';

// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

var dHdxy_fwd = tslFn( function( textureNode, bumpScale ) {

	// It's used to preserve the same TextureNode instance
	var sampleTexture = function( callback ) {
		return textureNode.cache().context( { getUV: function( texNode ) {
			return callback( texNode.uvNode || uv() );
		}, forceUVContext: true } );
	};

	var Hll = float( sampleTexture( function( uvNode ) {
		return uvNode;
	} ) );

	return vec2(
		float( sampleTexture( function( uvNode ) {
			return uvNode.add( uvNode.dFdx() );
		} ) ).sub( Hll ),
		float( sampleTexture( function( uvNode ) {
			return uvNode.add( uvNode.dFdy() );
		} ) ).sub( Hll )
	).mul( bumpScale );

} );

// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)

var perturbNormalArb = tslFn( function( inputs ) {

	var surf_pos = inputs.surf_pos;
	var surf_norm = inputs.surf_norm;
	var dHdxy = inputs.dHdxy;

	// normalize is done to ensure that the bump map looks the same regardless of the texture's scale
	var vSigmaX = surf_pos.dFdx().normalize();
	var vSigmaY = surf_pos.dFdy().normalize();
	var vN = surf_norm; // normalized

	var R1 = vSigmaY.cross( vN );
	var R2 = vN.cross( vSigmaX );

	var fDet = vSigmaX.dot( R1 ).mul( faceDirection );

	var vGrad = fDet.sign().mul( dHdxy.x.mul( R1 ).add( dHdxy.y.mul( R2 ) ) );

	return fDet.abs().mul( surf_norm ).sub( vGrad ).normalize();

} );

class BumpMapNode extends TempNode {

	constructor( textureNode, scaleNode = null ) {

		super( 'vec3' );

		this.textureNode = textureNode;
		this.scaleNode = scaleNode;

	}

	setup() {

		var bumpScale = this.scaleNode !== null ? this.scaleNode : 1;
		var dHdxy = dHdxy_fwd( this.textureNode, bumpScale );

		return perturbNormalArb( {
			surf_pos: positionView,
			surf_norm: normalView,
			dHdxy
		} );

	}

}

export default BumpMapNode;

export var bumpMap = nodeProxy( BumpMapNode );

addNodeElement( 'bumpMap', bumpMap );

addNodeClass( 'BumpMapNode', BumpMapNode );