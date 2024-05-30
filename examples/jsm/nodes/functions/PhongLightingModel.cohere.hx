import LightingModel from '../core/LightingModel.hx';
import F_Schlick from './BSDF/F_Schlick.hx';
import BRDF_Lambert from './BSDF/BRDF_Lambert.hx';

import diffuseColor from '../core/PropertyNode.hx';
import transformedNormalView from '../accessors/NormalNode.hx';
import materialSpecularStrength from '../accessors/MaterialNode.hx';
import shininess, specularColor from '../core/PropertyNode.hx';
import positionViewDirection from '../accessors/PositionNode.hx';
import { tslFn, float } from '../shadernode/ShaderNode.hx';

const G_BlinnPhong_Implicit = () => float(0.25);

const D_BlinnPhong = tslFn({ dotNH }:{Dynamic}) -> {
	return shininess.mul(float(0.5)).add(1.0).mul(float(1 / Math.PI)).mul(dotNH.pow(shininess));
};

const BRDF_BlinnPhong = tslFn({ lightDirection }:{Dynamic}) -> {
	var halfDir = lightDirection.add(positionViewDirection).normalize();
	var dotNH = transformedNormalView.dot(halfDir).clamp();
	var dotVH = positionViewDirection.dot(halfDir).clamp();
	var F = F_Schlick({ f0: specularColor, f90: 1.0, dotVH });
	var G = G_BlinnPhong_Implicit();
	var D = D_BlinnPhong({ dotNH });
	return F.mul(G).mul(D);
};

class PhongLightingModel extends LightingModel {
	public var specular:Bool;

	public function new(specular:Bool = true) {
		super();
		this.specular = specular;
	}

	public function direct({ lightDirection, lightColor, reflectedLight }:{Dynamic}) -> Void {
		var dotNL = transformedNormalView.dot(lightDirection).clamp();
		var irradiance = dotNL.mul(lightColor);
		reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert({ diffuseColor: diffuseColor.rgb })));

		if (this.specular) {
			reflectedLight.directSpecular.addAssign(irradiance.mul(BRDF_BlinnPhong({ lightDirection })).mul(materialSpecularStrength));
		}
	}

	public function indirectDiffuse({ irradiance, reflectedLight }:{Dynamic}) -> Void {
		reflectedLight.indirectDiffuse.addAssign(irradiance.mul(BRDF_Lambert({ diffuseColor })));
	}
}