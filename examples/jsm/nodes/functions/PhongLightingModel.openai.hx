package three.js.examples.jsm.nodes.functions;

import three.js.core.LightingModel;
import three.js.nodes.bsdf.F_Schlick;
import three.js.nodes.bsdf.BRDF_Lambert;
import three.js.core.PropertyNode;
import three.js.accessors.NormalNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class PhongLightingModel extends LightingModel {
  public var specular:Bool;

  public function new(specular:Bool = true) {
    super();
    this.specular = specular;
  }

  override public function direct(data: { lightDirection:Vector3, lightColor:Vector3, reflectedLight:ReflectedLight }):Void {
    var dotNL:Float = transformedNormalView.dot(data.lightDirection).clamp();
    var irradiance:Vector3 = dotNL * data.lightColor;

    reflectedLight.directDiffuse.addAssign(irradiance * BRDF_Lambert(diffuseColor));

    if (this.specular) {
      reflectedLight.directSpecular.addAssign(irradiance * BRDF_BlinnPhong(data.lightDirection) * materialSpecularStrength);
    }
  }

  override public function indirectDiffuse(data: { irradiance:Vector3, reflectedLight:ReflectedLight }):Void {
    reflectedLight.indirectDiffuse.addAssign(data.irradiance * BRDF_Lambert(diffuseColor));
  }
}

// Utility functions

inline function G_BlinnPhong_Implicit():Float {
  return 0.25;
}

inline function D_BlinnPhong(dotNH:Float):Float {
  return shininess * 0.5 + 1.0 * Math.PI * dotNH.pow(shininess);
}

inline function BRDF_BlinnPhong(lightDirection:Vector3):Float {
  var halfDir:Vector3 = lightDirection.add(positionViewDirection).normalize();
  var dotNH:Float = transformedNormalView.dot(halfDir).clamp();
  var dotVH:Float = positionViewDirection.dot(halfDir).clamp();

  var F:Float = F_Schlick(f0 = specularColor, f90 = 1.0, dotVH);
  var G:Float = G_BlinnPhong_Implicit();
  var D:Float = D_BlinnPhong(dotNH);

  return F * G * D;
}