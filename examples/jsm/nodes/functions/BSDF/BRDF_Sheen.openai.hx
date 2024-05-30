package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.accessors.NormalNode;
import three.js.accessors.PositionNode;
import three.js.core.PropertyNode;

class BRDF_Sheen {
  static var transformedNormalView:NormalNode;
  static var positionViewDirection:PositionNode;
  static var sheen:PropertyNode<Float>;
  static var sheenRoughness:PropertyNode<Float>;

  static var D_Charlie = new ShaderNode("D_Charlie", Float, [
    { name: "roughness", type: Float },
    { name: "dotNH", type: Float }
  ], function(data:D_CharlieInput) {
    var alpha = data.roughness * data.roughness;
    var invAlpha = 1.0 / alpha;
    var cos2h = data.dotNH * data.dotNH;
    var sin2h = Math.max(cos2h - 1.0, 0.0078125);
    return (2.0 + invAlpha) * Math.pow(sin2h, invAlpha * 0.5) / (2.0 * Math.PI);
  });

  static var V_Neubelt = new ShaderNode("V_Neubelt", Float, [
    { name: "dotNV", type: Float },
    { name: "dotNL", type: Float }
  ], function(data:V_NeubeltInput) {
    return 1.0 / (4.0 * (data.dotNL + data.dotNV - data.dotNL * data.dotNV));
  });

  static var BRDF_Sheen = new ShaderNode("BRDF_Sheen", Float, [], function(data:BRDF_SheenInput) {
    var lightDirection = data.lightDirection;
    var halfDir = lightDirection.add(positionViewDirection).normalize();
    var dotNL = transformedNormalView.dot(lightDirection).clamp();
    var dotNV = transformedNormalView.dot(positionViewDirection).clamp();
    var dotNH = transformedNormalView.dot(halfDir).clamp();
    var D = D_Charlie({ roughness: sheenRoughness, dotNH: dotNH });
    var V = V_Neubelt({ dotNV: dotNV, dotNL: dotNL });
    return sheen * D * V;
  });
}

typedef D_CharlieInput = {
  roughness:Float,
  dotNH:Float
}

typedef V_NeubeltInput = {
  dotNV:Float,
  dotNL:Float
}

typedef BRDF_SheenInput = {
  lightDirection:Vec3
}