import LightingModel from "../core/LightingModel";
import F_Schlick from "./BSDF/F_Schlick";
import BRDF_Lambert from "./BSDF/BRDF_Lambert";
import { diffuseColor } from "../core/PropertyNode";
import { transformedNormalView } from "../accessors/NormalNode";
import { materialSpecularStrength } from "../accessors/MaterialNode";
import { shininess, specularColor } from "../core/PropertyNode";
import { positionViewDirection } from "../accessors/PositionNode";
import { tslFn, float } from "../shadernode/ShaderNode";

class PhongLightingModel extends LightingModel {
  public specular: Bool;

  public function new(specular: Bool = true) {
    super();
    this.specular = specular;
  }

  override public function direct(params: {lightDirection: Vector3, lightColor: Vector3, reflectedLight: ReflectedLight}): Void {
    var dotNL = transformedNormalView.dot(params.lightDirection).clamp();
    var irradiance = dotNL.mul(params.lightColor);

    params.reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert.new({diffuseColor: diffuseColor.rgb})));

    if (this.specular) {
      params.reflectedLight.directSpecular.addAssign(irradiance.mul(BRDF_BlinnPhong.new({lightDirection: params.lightDirection})).mul(materialSpecularStrength));
    }
  }

  override public function indirectDiffuse(params: {irradiance: Vector3, reflectedLight: ReflectedLight}): Void {
    params.reflectedLight.indirectDiffuse.addAssign(params.irradiance.mul(BRDF_Lambert.new({diffuseColor: diffuseColor})));
  }
}

private static function G_BlinnPhong_Implicit(): Float {
  return float(0.25);
}

private static function D_BlinnPhong(dotNH: Float): Float {
  return shininess.mul(float(0.5)).add(1.0).mul(float(1 / Math.PI)).mul(dotNH.pow(shininess));
}

private static function BRDF_BlinnPhong(lightDirection: Vector3): Vector3 {
  var halfDir = lightDirection.add(positionViewDirection).normalize();

  var dotNH = transformedNormalView.dot(halfDir).clamp();
  var dotVH = positionViewDirection.dot(halfDir).clamp();

  var F = F_Schlick.new({f0: specularColor, f90: 1.0, dotVH: dotVH});
  var G = G_BlinnPhong_Implicit();
  var D = D_BlinnPhong(dotNH);

  return F.mul(G).mul(D);
}

export default PhongLightingModel;