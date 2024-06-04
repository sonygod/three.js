import LightingModel from "../core/LightingModel";
import BRDF_Lambert from "./BSDF/BRDF_Lambert";
import diffuseColor from "../core/PropertyNode";
import normalGeometry from "../accessors/NormalNode";
import { tslFn, float, vec2, vec3 } from "../shadernode/ShaderNode";
import { mix, smoothstep } from "../math/MathNode";
import materialReference from "../accessors/MaterialReferenceNode";

var getGradientIrradiance = tslFn((params) -> {
	var normal = params.normal;
	var lightDirection = params.lightDirection;
	var builder = params.builder;

	// dotNL will be from -1.0 to 1.0
	var dotNL = normal.dot(lightDirection);
	var coord = vec2(dotNL.mul(0.5).add(0.5), 0.0);

	if (builder.material.gradientMap != null) {
		var gradientMap = materialReference("gradientMap", "texture").context({
			getUV: () -> coord
		});

		return vec3(gradientMap.r);
	} else {
		var fw = coord.fwidth().mul(0.5);

		return mix(vec3(0.7), vec3(1.0), smoothstep(float(0.7).sub(fw.x), float(0.7).add(fw.x), coord.x));
	}
});

class ToonLightingModel extends LightingModel {
	public function direct(params: {
		lightDirection: vec3;
		lightColor: vec3;
		reflectedLight: { directDiffuse: vec3 };
	}, stack: Dynamic, builder: Dynamic) {
		var irradiance = getGradientIrradiance({
			normal: normalGeometry,
			lightDirection: params.lightDirection,
			builder: builder
		}).mul(params.lightColor);

		params.reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert({
			diffuseColor: diffuseColor.rgb
		})));
	}

	public function indirectDiffuse(params: {
		irradiance: vec3;
		reflectedLight: { indirectDiffuse: vec3 };
	}) {
		params.reflectedLight.indirectDiffuse.addAssign(params.irradiance.mul(BRDF_Lambert({
			diffuseColor: diffuseColor
		})));
	}
}

export default ToonLightingModel;