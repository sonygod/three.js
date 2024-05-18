import BRDF_Lambert from './BSDF/BRDF_Lambert.hx';
import BRDF_GGX from './BSDF/BRDF_GGX.hx';
import DFGApprox from './BSDF/DFGApprox.hx';
import EnvironmentBRDF from './BSDF/EnvironmentBRDF.hx';
import F_Schlick from './BSDF/F_Schlick.hx';
import Schlick_to_F0 from './BSDF/Schlick_to_F0.hx';
import BRDF_Sheen from './BSDF/BRDF_Sheen.hx';
import LightingModel from '../core/LightingModel.hx';
import { diffuseColor, specularColor, specularF90, roughness, clearcoat, clearcoatRoughness, sheen, sheenRoughness, iridescence, iridescenceIOR, iridescenceThickness, ior, thickness, transmission, attenuationDistance, attenuationColor } from '../core/PropertyNode.hx';
import { transformedNormalView, transformedClearcoatNormalView, transformedNormalWorld } from '../accessors/NormalNode.hx';
import { positionViewDirection, positionWorld } from '../accessors/PositionNode.hx';
import { tslFn, float, vec2, vec3, vec4, mat3, If } from '../shadernode/ShaderNode.hx';
import { cond } from '../math/CondNode.hx';
import { mix, normalize, refract, length, clamp, log2, log, exp, smoothstep } from '../math/MathNode.hx';
import { div } from '../math/OperatorNode.hx';
import { cameraPosition, cameraProjectionMatrix, cameraViewMatrix } from '../accessors/CameraNode.hx';
import { modelWorldMatrix } from '../accessors/ModelNode.hx';
import { viewportResolution } from '../display/ViewportNode.hx';
import { viewportMipTexture } from '../display/ViewportTextureNode.hx';

//
// Transmission
//

class GetVolumeTransmissionRay {

	@:tslFn
	public static function from(n:vec3, v:vec3, thickness:Float, ior:Float, modelMatrix:mat4):vec3 {
		// Direction of refracted light.
		var refractionVector = vec3(refract(v.negate(), normalize(n), div(1.0, ior)));

		// Compute rotation-independant scaling of the model matrix.
		var modelScale = vec3(
			length(modelMatrix[0].xyz),
			length(modelMatrix[1].xyz),
			length(modelMatrix[2].xyz)
		);

		// The thickness is specified in local space.
		return normalize(refractionVector).mul(thickness.mul(modelScale));
	}
}

@:tslFn
class ApplyIorToRoughness {

	@:tslFn
	public static function from(roughness:Float, ior:Float):Float {
		// Scale roughness with IOR so that an IOR of 1.0 results in no microfacet refraction and
		// an IOR of 1.5 results in the default amount of microfacet refraction.
		return roughness.mul(clamp(ior.mul(2.0).sub(2.0), 0.0, 1.0));
	}
}

var singleViewportMipTexture = viewportMipTexture();

@:tslFn
class GetTransmissionSample {

	@:tslFn
	public static function from(fragCoord:vec2, roughness:Float, ior:Float):vec3 {
		var transmissionSample = singleViewportMipTexture.uv(fragCoord);
		//const transmissionSample = viewportMipTexture( fragCoord );

		var lod = log2(float(viewportResolution.x)).mul(ApplyIorToRoughness.from(roughness, ior));

		return transmissionSample.bicubic(lod);
	}
}

@:tslFn
class VolumeAttenuation {

	@:tslFn
	public static function from(transmissionDistance:Float, attenuationColor:vec3, attenuationDistance:Float):vec3 {

		If(attenuationDistance.notEqual(0), () -> {

			// Compute light attenuation using Beer's law.
			var attenuationCoefficient = log(attenuationColor).negate().div(attenuationDistance);
			var transmittance = exp(attenuationCoefficient.negate().mul(transmissionDistance));

			return transmittance;

		});

		// Attenuation distance is +∞, i.e. the transmitted color is not attenuated at all.
		return vec3(1.0);
	}
}

@:tslFn
class GetIBLVolumeRefraction {

	@:tslFn
	public static function from(n:vec3, v:vec3, roughness:Float, diffuseColor:vec3, specularColor:vec3, specularF90:Float, position:vec3, modelMatrix:mat4, viewMatrix:mat4, projMatrix:mat4, ior:Float, thickness:Float, attenuationColor:vec3, attenuationDistance:Float):vec4 {
		var transmissionRay = GetVolumeTransmissionRay.from(n, v, thickness, ior, modelMatrix);
		var refractedRayExit = position.add(transmissionRay);

		// Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
		var ndcPos = projMatrix.mul(viewMatrix.mul(vec4(refractedRayExit, 1.0)));
		var refractionCoords = vec2(ndcPos.xy.div(ndcPos.w)).toVar();
		refractionCoords.addAssign(1.0);
		refractionCoords.divAssign(2.0);
		refractionCoords.assign(vec2(refractionCoords.x, refractionCoords.y.oneMinus())); // webgpu

		// Sample framebuffer to get pixel the refracted ray hits.
		var transmittedLight = GetTransmissionSample.from(refractionCoords, roughness, ior);
		var transmittance = diffuseColor.mul(VolumeAttenuation.from(length(transmissionRay), attenuationColor, attenuationDistance));
		var attenuatedColor = transmittance.rgb.mul(transmittedLight.rgb);
		var dotNV = n.dot(v).clamp();

		// Get the specular component.
		var F = vec3(EnvironmentBRDF.from({
			n,
			v,
			specularColor,
			specularF90,
			roughness
		}));

		// As less light is transmitted, the opacity should be increased. This simple approximation does a decent job
		// of modulating a CSS background, and has no effect when the buffer is opaque, due to a solid object or clear color.
		var transmittanceFactor = transmittance.r.add(transmittance.g, transmittance.b).div(3.0);

		return vec4(F.oneMinus().mul(attenuatedColor), transmittedLight.a.oneMinus().mul(transmittanceFactor).oneMinus());
	}
}

//
// Iridescence
//

// XYZ to linear-sRGB color space
var XYZ_TO_REC709 = mat3(
	3.2404542, - 0.9692660, 0.0556434,
	- 1.5371385, 1.8760108, - 0.2040259,
	- 0.4985314, 0.0415560, 1.0572252
);

// Assume air interface for top
// Note: We don't handle the case fresnel0 == 1
@:tslFn
class Fresnel0ToIor {

	@:tslFn
	public static function from(fresnel0:vec3):vec3 {
		var sqrtF0 = fresnel0.sqrt();
		return vec3(1.0).add(sqrtF0).div(vec3(1.0).sub(sqrtF0));
	}
}

// ior is a value between 1.0 and 3.0. 1.0 is air interface
@:tslFn
class IorToFresnel0 {

	@:tslFn
	public static function from(transmittedIor:Float, incidentIor:Float):vec3 {
		return transmittedIor.sub(incidentIor).div(transmittedIor.add(incidentIor)).pow2();
	}
}

// Fresnel equations for dielectric/dielectric interfaces.
// Ref: https://belcour.github.io/blog/research/2017/05/01/brdf-thin-film.html
// Evaluation XYZ sensitivity curves in Fourier space
@:tslFn
class EvalSensitivity {

	@:tslFn
	public static function from(OPD:vec3, shift:vec2):vec3 {
		var phase = OPD.mul(2.0 * Math.PI * 1.0e-9);
		var val = vec3(5.4856e-13, 4.4201e-13, 5.2481e-13);
		var pos = vec3(1.6810e+06, 1.7953e+06, 2.2084e+06);
		var VAR = vec3(4.3278e+09, 9.3046e+09, 6.6121e+09);

		var x = float(9.7470e-14 * Math.sqrt(2.0 * 4.5282e+09)).mul(phase.mul(2.2399e+06).add(shift.x).cos()).mul(phase.pow2().mul(-4.5282e+09).exp());

		var xyz = val.mul(VAR.mul(2.0 * Math.PI).sqrt()).mul(pos.mul(phase).add(shift).cos()).mul(phase.pow2().negate().mul(VAR).exp());
		xyz = vec3(xyz.x.add(x), xyz.y, xyz.z).div(1.0685e-7);

		var rgb = XYZ_TO_REC709.mul(xyz);

		return rgb;
	}
}

@:tslFn
class EvalIridescence {

	@:tslFn
	public static function from(outsideIOR:Float, eta2:Float, cosTheta1:Float, thinFilmThickness:Float, baseF0:vec3):vec3 {
		// Force iridescenceIOR -> outsideIOR when thinFilmThickness -> 0.0
		var iridescenceIOR = mix(outsideIOR, eta2, smoothstep(0.0, 0.03, thinFilmThickness));
		// Evaluate the cosTheta on the base layer (Snell law)
		var sinTheta2Sq = outsideIOR.div(iridescenceIOR).pow2().mul(float(1).sub(cosTheta1.pow2()));

		// Handle TIR:
		var cosTheta2Sq = float(1).sub(sinTheta2Sq);
		/*if (cosTheta2Sq < 0.0) {
			return vec3(1.0);
		}*/

		var cosTheta2 = cosTheta2Sq.sqrt();

		// First interface
		var R0 = IorToFresnel0.from(iridescenceIOR, outsideIOR);
		var R12 = F_Schlick.from({f0: R0, f90: 1.0, dotVH: cosTheta1});
		//const R21 = R12;
		var T121 = R12.oneMinus();
		var phi12 = iridescenceIOR.lessThan(outsideIOR).cond(Math.PI, 0.0);
		var phi21 = float(Math.PI).sub(phi12);

		// Second interface
		var baseIOR = Fresnel0ToIor.from(Fresnel0ToIor.from(baseF0.clamp(0.0, 0.9999))); // guard against 1.0
		var R1 = IorToFresnel0.from(baseIOR, iridescenceIOR.toVec3());
		var R23 = F_Schlick.from({f0: R1, f90: 1.0, dotVH: cosTheta2});
		var phi23 = vec3(
			baseIOR.x.lessThan(iridescenceIOR).cond(Math.PI, 0.0),
			baseIOR.y.lessThan(iridescenceIOR).cond(Math.PI, 0.0),
			baseIOR.z.lessThan(iridescenceIOR).cond(Math.PI, 0.0)
		);

		// Phase shift
		var OPD = iridescenceIOR.mul(thinFilmThickness, cosTheta2, 2.0);
		var phi = vec3(phi21).add(phi23);

		// Compound terms
		var R123 = R12.mul(R23).clamp(1e-5, 0.9999);
		var r123 = R123.sqrt();
		var Rs = T121.pow2().mul(R23).div(vec3(1.0).sub(R123));

		// Reflectance term for m = 0 (DC term amplitude)
		var C0 = R12.add(Rs);
		var I = C0;

		// Reflectance term for m > 0 (pairs of diracs)
		var Cm = Rs.sub(T121);
		for (var m = 1; m <= 2; ++m) {
			Cm = Cm.mul(r123);
			var Sm = EvalSensitivity.from(float(m).mul(OPD), float(m).mul(phi)).mul(2.0);
			I = I.add(Cm.mul(Sm));
		}

		// Since out of gamut colors might be produced, negative color values are clamped to 0.
		return I.max(vec3(0.0));
	}
}

//
//	Sheen
//

// This is a curve-fit approxmation to the "Charlie sheen" BRDF integrated over the hemisphere from
// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF". The analysis can be found
// in the Sheen section of https://drive.google.com/file/d/1T0D1VSyR4AllqIJTQAraEIzjlb5h4FKH/view?usp=sharing
@:tslFn
class IBLSheenBRDF {

	@:tslFn
	public static function from({normal, viewDir, roughness}:{normal:vec3, viewDir:vec3, roughness:Float}):vec3 {
		const dotNV = normal.dot(viewDir).saturate();

		const r2 = roughness.pow2();

		const a = cond(
			roughness.lessThan(0.25),
			float(-339.2).mul(r2).add(float(161.4).mul(roughness)).sub(25.9),
			float(-8.48).mul(r2).add(float(14.3).mul(roughness)).sub(9.95)
		);

		const b = cond(
			roughness.lessThan(0.25),
			float(44.0).mul(r2).sub(float(23.7).mul(roughness)).add(3.26),
			float(1.97).mul(r2).sub(float(3.27).mul(roughness)).add(0.72)
		);

		const DG = cond(roughness.lessThan(0.25), 0.0, float(0.1).mul(roughness).sub(0.025)).add(a.mul(dotNV).add(b).exp());

		return DG.mul(1.0 / Math.PI).saturate();
	}
}

var clearcoatF0 = vec3(0.04);
var clearcoatF90 = vec3(1);

//

class PhysicalLightingModel extends LightingModel {

	public clearcoat:Bool;
	public sheen:Bool;
	public iridescence:Bool;
	public anisotropy:Bool;
	public transmission:Bool;

	public clearcoatRadiance:vec3;
	public clearcoatSpecularDirect:vec3;
	public clearcoatSpecularIndirect:vec3;
	public sheenSpecularDirect:vec3;
	public sheenSpecularIndirect:vec3;
	public iridescenceFresnel:vec3;
	public iridescenceF0:vec3;

	public function new(clearcoat:Bool = false, sheen:Bool = false, iridescence:Bool = false, anisotropy:Bool = false, transmission:Bool = false) {
		super();

		this.clearcoat = clearcoat;
		this.sheen = sheen;
		this.iridescence = iridescence;
		this.anisotropy = anisotropy;
		this.transmission = transmission;

		this.clearcoatRadiance = null;
		this.clearcoatSpecularDirect = null;
		this.clearcoatSpecularIndirect = null;
		this.sheenSpecularDirect = null;
		this.sheenSpecularIndirect = null;
		this.iridescenceFresnel = null;
		this.iridescenceF0 = null;
	}

	public function start(context:Context) {
		if (this.clearcoat === true) {
			this.clearcoatRadiance = vec3().temp('clearcoatRadiance');
			this.clearcoatSpecularDirect = vec3().temp('clearcoatSpecularDirect');
			this.clearcoatSpecularIndirect = vec3().temp('clearcoatSpecularIndirect');
		}

		if (this.sheen === true) {
			this.sheenSpecularDirect = vec3().temp('sheenSpecularDirect');
			this.sheenSpecularIndirect = vec3().temp('sheenSpecularIndirect');
		}

		if (this.iridescence === true) {
			var dotNVi = transformedNormalView.dot(positionViewDirection).clamp();

			this.iridescenceFresnel = EvalIridescence.from(
				1.0,
				iridescenceIOR,
				dotNVi,
				iridescenceThickness,
				specularColor
			);

			this.iridescenceF0 = Schlick_to_F0.from({f: this.iridescenceFresnel, f90: 1.0, dotVH: dotNVi});
		}

		if (this.transmission === true) {
			var position = positionWorld;
			var v = cameraPosition.sub(positionWorld).normalize(); // TODO: Create Node for this, same issue in MaterialX
			var n = transformedNormalWorld;

			context.backdrop = GetIBLVolumeRefraction.from(
				n,
				v,
				roughness,
				diffuseColor,
				specularColor,
				specularF90, // specularF90
				position, // positionWorld
				modelWorldMatrix, // modelMatrix
				cameraViewMatrix, // viewMatrix
				cameraProjectionMatrix, // projMatrix
				ior,
				thickness,
				attenuationColor,
				attenuationDistance
			);

			context.backdropAlpha = transmission;

			diffuseColor.a.mulAssign(mix(1, context.backdrop.a, transmission));
		}
	}

	// Fdez-Agüera's "Multiple-Scattering Microfacet Model for Real-Time Image Based Lighting"
	// Approximates multiscattering in order to preserve energy.
	// http://www.jcgt.org/published/0008/01/03/

	public function computeMultiscattering(singleScatter:vec3, multiScatter:vec3, specularF90:vec3) {
		const dotNV = transformedNormalView.dot(positionViewDirection).clamp(); // @ TODO: Move to core dotNV

		const fab = DFGApprox.from(roughness, dotNV);

		const Fr = this.iridescenceF0 ? iridescence.mix(specularColor, this.iridescenceF0) : specularColor;

		const FssEss = Fr.mul(fab.x).add(specularF90.mul(fab.y));

		const Ess = fab.x.add(fab.y);
		const Ems = Ess.oneMinus();

		const Favg = specularColor.add(specularColor.oneMinus().mul(0.047619)); // 1/21
		const Fms = FssEss.mul(Favg).div(Ems.mul(Favg).oneMinus());

		singleScatter.addAssign(FssEss);
		multiScatter.addAssign(Fms.mul(Ems));
	}

	public function direct({lightDirection, lightColor, reflectedLight}:{lightDirection:vec3, lightColor:vec3, reflectedLight:ReflectedLight}) {
		const dotNL = transformedNormalView.dot(lightDirection).clamp();
		const irradiance = dotNL.mul(lightColor);

		if (this.sheen === true) {
			this.sheenSpecularDirect.addAssign(irradiance.mul(IBLSheenBRDF({normal: transformedNormalView, viewDir: positionViewDirection, roughness: sheenRoughness})));
		}

		if (this.clearcoat === true) {
			const dotNVcc = transformedClearcoatNormalView.dot(lightDirection).clamp();
			const ccIrradiance = dotNVcc.mul(lightColor);

			this.clearcoatSpecularDirect.addAssign(ccIrradiance.mul(BRDF_GGX.from({lightDirection, f0: clearcoatF0, f90: clearcoatF90, normalView: transformedClearcoatNormalView, roughness: clearcoatRoughness})));
		}

		reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert.from({diffuseColor: diffuseColor.rgb})));

		reflectedLight.directSpecular.addAssign(irradiance.mul(BRDF_GGX.from({lightDirection, f0: specularColor, f90: 1, roughness, iridescence: this.iridescence, f: this.iridescenceFresnel, USE_IRIDESCENCE: this.iridescence, USE_ANISOTROPY: this.anisotropy})));
	}

	public function indirectDiffuse({irradiance, reflectedLight}:{irradiance:vec3, reflectedLight:ReflectedLight}) {
		reflectedLight.indirectDiffuse.addAssign(irradiance.mul(BRDF_Lambert.from({diffuseColor})));
	}

	public function indirectSpecular({radiance, iblIrradiance, reflectedLight}:{radiance:vec3, iblIrradiance:vec3, reflectedLight:ReflectedLight}) {
		if (this.sheen === true) {
			this.sheenSpecularIndirect.addAssign(iblIrradiance.mul(
				sheen,
				IBLSheenBRDF({
					normal: transformedNormalView,
					viewDir: positionViewDirection,
					roughness: sheenRoughness
				})
			));
		}

		if (this.clearcoat === true) {
			const dotNVcc = transformedClearcoatNormalView.dot(positionViewDirection).clamp();

			const clearcoatEnv = EnvironmentBRDF.from({
				dotNV: dotNVcc,
				specularColor: clearcoatF0,
				specularF90: clearcoatF90,
				roughness: clearcoatRoughness
			});

			this.clearcoatSpecularIndirect.addAssign(this.clearcoatRadiance.mul(clearcoatEnv));
		}

		// Both indirect specular and indirect diffuse light accumulate here

		var singleScattering = vec3().temp('singleScattering');
		var multiScattering = vec3().temp('multiScattering');
		var cosineWeightedIrradiance = iblIrradiance.mul(1 / Math.PI);

		this.computeMultiscattering(singleScattering, multiScattering, specularF90);

		var totalScattering = singleScattering.add(multiScattering);

		var diffuse = diffuseColor.mul(totalScattering.r.max(totalScattering.g).max(totalScattering.b).oneMinus());

		reflectedLight.indirectSpecular.addAssign(radiance.mul(singleScattering));
		reflectedLight.indirectSpecular.addAssign(multiScattering.mul(cosineWeightedIrradiance));

		reflectedLight.indirectDiffuse.addAssign(diffuse.mul(cosineWeightedIrradiance));
	}

	public function ambientOcclusion({ambientOcclusion, reflectedLight}:{ambientOcclusion:Float, reflectedLight:ReflectedLight}) {
		const dotNV = transformedNormalView.dot(positionViewDirection).clamp(); // @ TODO: Move to core dotNV

		const aoNV = dotNV.add(ambientOcclusion);
		const aoExp = roughness.mul(-16.0).oneMinus().negate().exp2();

		var aoNode = ambientOcclusion.sub(aoNV.pow(aoExp).oneMinus()).clamp();

		if (this.clearcoat === true) {
			this.clearcoatSpecularIndirect.mulAssign(ambientOcclusion);
		}

		if (this.sheen === true) {
			this.sheenSpecularIndirect.mulAssign(ambientOcclusion);
		}

		reflectedLight.indirectDiffuse.mulAssign(ambientOcclusion);
		reflectedLight.indirectSpecular.mulAssign(aoNode);
	}

	public function finish(context:Context) {
		const {outgoingLight} = context;

		if (this.clearcoat === true) {
			const dotNVcc = transformedClearcoatNormalView.dot(positionViewDirection).clamp();

			const Fcc = F_Schlick.from({
				dotVH: dotNVcc,
				f0: clearcoatF0,
				f90: clearcoatF90
			});

			const clearcoatLight = outgoingLight.mul(clearcoat.mul(Fcc).oneMinus()).add(this.clearcoatSpecularDirect.add(this.clearcoatSpecularIndirect).mul(clearcoat));

			outgoingLight.assign(clearcoatLight);
		}

		if (this.sheen === true) {
			const sheenEnergyComp = sheen.r.max(sheen.g).max(sheen.b).mul(0.157).oneMinus();
			const sheenLight = outgoingLight.mul(sheenEnergyComp).add(this.sheenSpecularDirect, this.sheenSpecularIndirect);

			outgoingLight.assign(sheenLight);
		}
	}
}