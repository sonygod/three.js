package three.js.examples.jsm.nodes.functions.BSDF;

import F_Schlick;
import V_GGX_SmithCorrelated;
import V_GGX_SmithCorrelated_Anisotropic;
import D_GGX;
import D_GGX_Anisotropic;

import three.js.accessors.NormalNode.transformedNormalView;
import three.js.accessors.PositionNode.positionViewDirection;

import three.js.core.PropertyNode.Iridescence;
import three.js.core.PropertyNode.AlphaT;
import three.js.core.PropertyNode.AnisotropyT;
import three.js.core.PropertyNode.AnisotropyB;

import three.js.shadernode.ShaderNode.TslFn;
import three.js.shadernode.ShaderNode.Defined;

class BRDF_GGX {
  public static function compute(inputs:Dynamic):Float {
    var lightDirection:Vector3 = inputs.lightDirection;
    var f0:Float = inputs.f0;
    var f90:Float = inputs.f90;
    var roughness:Float = inputs.roughness;
    var f:Float = inputs.f;
    var useIridescence:Bool = inputs.USE_IRIDESCENCE;
    var useAnisotropy:Bool = inputs.USE_ANISOTROPY;

    var normalView:Vector3 = inputs.normalView != null ? inputs.normalView : transformedNormalView;

    var alpha:Float = roughness * roughness; // UE4's roughness

    var halfDir:Vector3 = lightDirection.add(positionViewDirection).normalize();

    var dotNL:Float = Math.max(0, Math.min(1, normalView.dot(lightDirection)));
    var dotNV:Float = Math.max(0, Math.min(1, normalView.dot(positionViewDirection))); // @TODO: Move to core dotNV
    var dotNH:Float = Math.max(0, Math.min(1, normalView.dot(halfDir)));
    var dotVH:Float = Math.max(0, Math.min(1, positionViewDirection.dot(halfDir)));

    var F:Float = F_Schlick.compute({ f0: f0, f90: f90, dotVH: dotVH });
    var V:Float;
    var D:Float;

    if (useIridescence) {
      F = Iridescence.mix(F, f);
    }

    if (useAnisotropy) {
      var dotTL:Float = AnisotropyT.dot(lightDirection);
      var dotTV:Float = AnisotropyT.dot(positionViewDirection);
      var dotTH:Float = AnisotropyT.dot(halfDir);
      var dotBL:Float = AnisotropyB.dot(lightDirection);
      var dotBV:Float = AnisotropyB.dot(positionViewDirection);
      var dotBH:Float = AnisotropyB.dot(halfDir);

      V = V_GGX_SmithCorrelated_Anisotropic.compute({
        alphaT: AlphaT,
        alphaB: alpha,
        dotTV: dotTV,
        dotBV: dotBV,
        dotTL: dotTL,
        dotBL: dotBL,
        dotNV: dotNV,
        dotNL: dotNL
      });
      D = D_GGX_Anisotropic.compute({
        alphaT: AlphaT,
        alphaB: alpha,
        dotNH: dotNH,
        dotTH: dotTH,
        dotBH: dotBH
      });
    } else {
      V = V_GGX_SmithCorrelated.compute({ alpha: alpha, dotNL: dotNL, dotNV: dotNV });
      D = D_GGX.compute({ alpha: alpha, dotNH: dotNH });
    }

    return F * V * D;
  }
}