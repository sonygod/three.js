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

  public function direct(lightDirection: {get: () -> Dynamic}, lightColor: {get: () -> Dynamic}, reflectedLight: {get: () -> Dynamic}): Void {
    var dotNL = transformedNormalView.dot(lightDirection).clamp();
    var irradiance = dotNL.mul(lightColor);

    reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert.new({ diffuseColor: diffuseColor.rgb })));

    if (this.specular) {
      reflectedLight.directSpecular.addAssign(irradiance.mul(BRDF_BlinnPhong.new({ lightDirection })).mul(materialSpecularStrength));
    }
  }

  public function indirectDiffuse(irradiance: {get: () -> Dynamic}, reflectedLight: {get: () -> Dynamic}): Void {
    reflectedLight.indirectDiffuse.addAssign(irradiance.mul(BRDF_Lambert.new({ diffuseColor })));
  }
}

class G_BlinnPhong_Implicit extends tslFn {
  public function new(): Void {
    super(function({ dotNH }) {
      return float(0.25);
    });
  }
}

class D_BlinnPhong extends tslFn {
  public function new(): Void {
    super(function({ dotNH }) {
      return shininess.mul(float(0.5)).add(1.0).mul(float(1 / Math.PI)).mul(dotNH.pow(shininess));
    });
  }
}

class BRDF_BlinnPhong extends tslFn {
  public function new(): Void {
    super(function({ lightDirection }) {
      var halfDir = lightDirection.add(positionViewDirection).normalize();

      var dotNH = transformedNormalView.dot(halfDir).clamp();
      var dotVH = positionViewDirection.dot(halfDir).clamp();

      var F = F_Schlick.new({ f0: specularColor, f90: 1.0, dotVH });
      var G = G_BlinnPhong_Implicit.new();
      var D = D_BlinnPhong.new();

      return F.mul(G).mul(D);
    });
  }
}

export default PhongLightingModel;