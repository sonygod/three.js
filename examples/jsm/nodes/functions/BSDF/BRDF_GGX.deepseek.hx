import three.js.examples.jsm.nodes.functions.BSDF.F_Schlick;
import three.js.examples.jsm.nodes.functions.BSDF.V_GGX_SmithCorrelated;
import three.js.examples.jsm.nodes.functions.BSDF.V_GGX_SmithCorrelated_Anisotropic;
import three.js.examples.jsm.nodes.functions.BSDF.D_GGX;
import three.js.examples.jsm.nodes.functions.BSDF.D_GGX_Anisotropic;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class BRDF_GGX {
    static function tslFn(inputs:Dynamic):Dynamic {
        var lightDirection = inputs.lightDirection;
        var f0 = inputs.f0;
        var f90 = inputs.f90;
        var roughness = inputs.roughness;
        var f = inputs.f;
        var USE_IRIDESCENCE = inputs.USE_IRIDESCENCE;
        var USE_ANISOTROPY = inputs.USE_ANISOTROPY;

        var normalView = inputs.normalView || NormalNode.transformedNormalView;

        var alpha = roughness.pow2(); // UE4's roughness

        var halfDir = lightDirection.add(PositionNode.positionViewDirection).normalize();

        var dotNL = normalView.dot(lightDirection).clamp();
        var dotNV = normalView.dot(PositionNode.positionViewDirection).clamp(); // @ TODO: Move to core dotNV
        var dotNH = normalView.dot(halfDir).clamp();
        var dotVH = PositionNode.positionViewDirection.dot(halfDir).clamp();

        var F = F_Schlick.F_Schlick({f0: f0, f90: f90, dotVH: dotVH});
        var V:Dynamic;
        var D:Dynamic;

        if (ShaderNode.defined(USE_IRIDESCENCE)) {
            F = PropertyNode.iridescence.mix(F, f);
        }

        if (ShaderNode.defined(USE_ANISOTROPY)) {
            var dotTL = PropertyNode.anisotropyT.dot(lightDirection);
            var dotTV = PropertyNode.anisotropyT.dot(PositionNode.positionViewDirection);
            var dotTH = PropertyNode.anisotropyT.dot(halfDir);
            var dotBL = PropertyNode.anisotropyB.dot(lightDirection);
            var dotBV = PropertyNode.anisotropyB.dot(PositionNode.positionViewDirection);
            var dotBH = PropertyNode.anisotropyB.dot(halfDir);

            V = V_GGX_SmithCorrelated_Anisotropic.V_GGX_SmithCorrelated_Anisotropic({alphaT: PropertyNode.alphaT, alphaB: alpha, dotTV: dotTV, dotBV: dotBV, dotTL: dotTL, dotBL: dotBL, dotNV: dotNV, dotNL: dotNL});
            D = D_GGX_Anisotropic.D_GGX_Anisotropic({alphaT: PropertyNode.alphaT, alphaB: alpha, dotNH: dotNH, dotTH: dotTH, dotBH: dotBH});
        } else {
            V = V_GGX_SmithCorrelated.V_GGX_SmithCorrelated({alpha: alpha, dotNL: dotNL, dotNV: dotNV});
            D = D_GGX.D_GGX({alpha: alpha, dotNH: dotNH});
        }

        return F.mul(V).mul(D);
    }
}