import F_Schlick from './F_Schlick.js';
import V_GGX_SmithCorrelated from './V_GGX_SmithCorrelated.js';
import V_GGX_SmithCorrelated_Anisotropic from './V_GGX_SmithCorrelated_Anisotropic.js';
import D_GGX from './D_GGX.js';
import D_GGX_Anisotropic from './D_GGX_Anisotropic.js';
import { transformedNormalView } from '../../accessors/NormalNode.js';
import { positionViewDirection } from '../../accessors/PositionNode.js';
import { iridescence, alphaT, anisotropyT, anisotropyB } from '../../core/PropertyNode.js';
import { tslFn, defined } from '../../shadernode/ShaderNode.js';

// GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
var BRDF_GGX = tslFn( function( inputs ) {

	var lightDirection = inputs.lightDirection;
	var f0 = inputs.f0;
	var f90 = inputs.f90;
	var roughness = inputs.roughness;
	var f = inputs.f;
	var USE_IRIDESCENCE = inputs.USE_IRIDESCENCE;
	var USE_ANISOTROPY = inputs.USE_ANISOTROPY;

	var normalView = inputs.normalView || transformedNormalView;

	var alpha = roughness.pow2(); // UE4's roughness

	var halfDir = lightDirection.add( positionViewDirection ).normalize();

	var dotNL = normalView.dot( lightDirection ).clamp();
	var dotNV = normalView.dot( positionViewDirection ).clamp(); // @ TODO: Move to core dotNV
	var dotNH = normalView.dot( halfDir ).clamp();
	var dotVH = positionViewDirection.dot( halfDir ).clamp();

	var F = F_Schlick( { f0, f90, dotVH } );
	var V, D;

	if ( defined( USE_IRIDESCENCE ) ) {

		F = iridescence.mix( F, f );

	}

	if ( defined( USE_ANISOTROPY ) ) {

		var dotTL = anisotropyT.dot( lightDirection );
		var dotTV = anisotropyT.dot( positionViewDirection );
		var dotTH = anisotropyT.dot( halfDir );
		var dotBL = anisotropyB.dot( lightDirection );
		var dotBV = anisotropyB.dot( positionViewDirection );
		var dotBH = anisotropyB.dot( halfDir );

		V = V_GGX_SmithCorrelated_Anisotropic( { alphaT, alphaB: alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL } );
		D = D_GGX_Anisotropic( { alphaT, alphaB: alpha, dotNH, dotTH, dotBH } );

	} else {

		V = V_GGX_SmithCorrelated( { alpha, dotNL, dotNV } );
		D = D_GGX( { alpha, dotNH } );

	}

	return F.mul( V ).mul( D );

} ); // validated

export default BRDF_GGX;