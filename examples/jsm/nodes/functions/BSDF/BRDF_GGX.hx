package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.core.PropertyNode;
import three.js.examples.jsm.shadernode.ShaderNode;

class BRDF_GGX {
    public static function compute(inputs:Dynamic):Float {
        var lightDirection:Vector3 = inputs.lightDirection;
        var f0:Float = inputs.f0;
        var f90:Float = inputs.f90;
        var roughness:Float = inputs.roughness;
        var f:Float = inputs.f;
        var useIridescence:Bool = inputs.USE_IRIDESCENCE;
        var useAnisotropy:Bool = inputs.USE_ANISOTROPY;

        var normalView:Vector3 = inputs.normalView != null ? inputs.normalView : transformedNormalView();
        var positionViewDirection:Vector3 = positionViewDirection();

        var alpha:Float = roughness * roughness; // UE4's roughness

        var halfDir:Vector3 = lightDirection.add(positionViewDirection).normalize();

        var dotNL:Float = normalView.dot(lightDirection).clamp(0, 1);
        var dotNV:Float = normalView.dot(positionViewDirection).clamp(0, 1); // @ TODO: Move to core dotNV
        var dotNH:Float = normalView.dot(halfDir).clamp(0, 1);
        var dotVH:Float = positionViewDirection.dot(halfDir).clamp(0, 1);

        var F:Float = F_Schlick.compute({ f0: f0, f90: f90, dotVH: dotVH });
        var V:Float;
        var D:Float;

        if (useIridescence) {
            F = iridescence.mix(F, f);
        }

        if (useAnisotropy) {
            var dotTL:Float = anisotropyT.dot(lightDirection);
            var dotTV:Float = anisotropyT.dot(positionViewDirection);
            var dotTH:Float = anisotropyT.dot(halfDir);
            var dotBL:Float = anisotropyB.dot(lightDirection);
            var dotBV:Float = anisotropyB.dot(positionViewDirection);
            var dotBH:Float = anisotropyB.dot(halfDir);

            V = V_GGX_SmithCorrelated_Anisotropic.compute({
                alphaT: alphaT,
                alphaB: alpha,
                dotTV: dotTV,
                dotBV: dotBV,
                dotTL: dotTL,
                dotBL: dotBL,
                dotNV: dotNV,
                dotNL: dotNL
            });
            D = D_GGX_Anisotropic.compute({
                alphaT: alphaT,
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