import F_Schlick from "./F_Schlick";
import V_GGX_SmithCorrelated from "./V_GGX_SmithCorrelated";
import V_GGX_SmithCorrelated_Anisotropic from "./V_GGX_SmithCorrelated_Anisotropic";
import D_GGX from "./D_GGX";
import D_GGX_Anisotropic from "./D_GGX_Anisotropic";
import { transformedNormalView } from "../../accessors/NormalNode";
import { positionViewDirection } from "../../accessors/PositionNode";
import { iridescence, alphaT, anisotropyT, anisotropyB } from "../../core/PropertyNode";
import { tslFn, defined } from "../../shadernode/ShaderNode";

// GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
var BRDF_GGX = tslFn((inputs) -> {

	var { lightDirection, f0, f90, roughness, f, USE_IRIDESCENCE, USE_ANISOTROPY } = inputs;

	var normalView = inputs.normalView || transformedNormalView;

	var alpha = roughness.pow2(); // UE4's roughness

	var halfDir = lightDirection.add(positionViewDirection).normalize();

	var dotNL = normalView.dot(lightDirection).clamp();
	var dotNV = normalView.dot(positionViewDirection).clamp(); // @ TODO: Move to core dotNV
	var dotNH = normalView.dot(halfDir).clamp();
	var dotVH = positionViewDirection.dot(halfDir).clamp();

	var F = F_Schlick.get({ f0: f0, f90: f90, dotVH: dotVH });
	var V: Dynamic, D: Dynamic;

	if (defined(USE_IRIDESCENCE)) {

		F = iridescence.mix(F, f);

	}

	if (defined(USE_ANISOTROPY)) {

		var dotTL = anisotropyT.dot(lightDirection);
		var dotTV = anisotropyT.dot(positionViewDirection);
		var dotTH = anisotropyT.dot(halfDir);
		var dotBL = anisotropyB.dot(lightDirection);
		var dotBV = anisotropyB.dot(positionViewDirection);
		var dotBH = anisotropyB.dot(halfDir);

		V = V_GGX_SmithCorrelated_Anisotropic.get({ alphaT: alphaT, alphaB: alpha, dotTV: dotTV, dotBV: dotBV, dotTL: dotTL, dotBL: dotBL, dotNV: dotNV, dotNL: dotNL });
		D = D_GGX_Anisotropic.get({ alphaT: alphaT, alphaB: alpha, dotNH: dotNH, dotTH: dotTH, dotBH: dotBH });

	} else {

		V = V_GGX_SmithCorrelated.get({ alpha: alpha, dotNL: dotNL, dotNV: dotNV });
		D = D_GGX.get({ alpha: alpha, dotNH: dotNH });

	}

	return F.mul(V).mul(D);

}); // validated

export default BRDF_GGX;