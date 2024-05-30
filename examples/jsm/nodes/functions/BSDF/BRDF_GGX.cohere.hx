import F_Schlick from './F_Schlick.hx';
import V_GGX_SmithCorrelated from './V_GGX_SmithCorrelated.hx';
import V_GGX_SmithCorrelated_Anisotropic from './V_GGX_SmithCorrelated_Anisotropic.hx';
import D_GGX from './D_GGX.hx';
import D_GGX_Anisotropic from './D_GGX_Anisotropic.hx';

import { transformedNormalView } from '../../accessors/NormalNode.hx';
import { positionViewDirection } from '../../accessors/PositionNode.hx';
import { iridescence, alphaT, anisotropyT, anisotropyB } from '../../core/PropertyNode.hx';
import { tslFn, defined } from '../../shadernode/ShaderNode.hx';

// GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
const BRDF_GGX = tslFn( ( inputs : { lightDirection : Float3, f0 : Float3, f90 : Float, roughness : Float, f : Float3, USE_IRIDESCENCE : Bool, USE_ANISOTROPY : Bool, normalView : Option<Float3> } ) => {

	var lightDirection = inputs.lightDirection;
	var f0 = inputs.f0;
	var f90 = inputs.f90;
	var roughness = inputs.roughness;
	var f = inputs.f;
	var USE_IRIDESCENCE = inputs.USE_IRIDESCENCE;
	var USE_ANISOTROPY = inputs.USE_ANISOTROPY;
	var normalView = inputs.normalView.defVal(transformedNormalView);

	var alpha = roughness * roughness; // UE4's roughness

	var halfDir = normalize(lightDirection + positionViewDirection);

	var dotNL = clamp(normalView.dot(lightDirection), 0., 1.);
	var dotNV = clamp(normalView.dot(positionViewDirection), 0., 1.); // @ TODO: Move to core dotNV
	var dotNH = clamp(normalView.dot(halfDir), 0., 1.);
	var dotVH = clamp(positionViewDirection.dot(halfDir), 0., 1.);

	var F = F_Schlick({ f0: f0, f90: f90, dotVH: dotVH });
	var V, D;

	if (defined(USE_IRIDESCENCE)) {

		F = mix(F, f, iridescence);

	}

	if (defined(USE_ANISOTROPY)) {

		var dotTL = anisotropyT.dot(lightDirection);
		var dotTV = anisotropyT.dot(positionViewDirection);
		var dotTH = anisotropyT.dot(halfDir);
		var dotBL = anisotropyB.dot(lightDirection);
		var dotBV = anisotropyB.dot(positionViewDirection);
		var dotBH = anisotropyB.dot(halfDir);

		V = V_GGX_SmithCorrelated_Anisotropic({ alphaT: alphaT, alphaB: alpha, dotTV: dotTV, dotBV: dotBV, dotTL: dotTL, dotBL: dotBL, dotNV: dotNV, dotNL: dotNL });
		D = D_GGX_Anisotropic({ alphaT: alphaT, alphaB: alpha, dotNH: dotNH, dotTH: dotTH, dotBH: dotBH });

	} else {

		V = V_GGX_SmithCorrelated({ alpha: alpha, dotNL: dotNL, dotNV: dotNV });
		D = D_GGX({ alpha: alpha, dotNH: dotNH });

	}

	return F * V * D;

} ); // validated

export default BRDF_GGX;