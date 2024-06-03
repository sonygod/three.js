@:import('F_Schlick.hx')
@:import('V_GGX_SmithCorrelated.hx')
@:import('V_GGX_SmithCorrelated_Anisotropic.hx')
@:import('D_GGX.hx')
@:import('D_GGX_Anisotropic.hx')
@:import('../../accessors/NormalNode.hx')
@:import('../../accessors/PositionNode.hx')
@:import('../../core/PropertyNode.hx')
@:import('../../shadernode/ShaderNode.hx')

class BRDF_GGX {
    public static function calculate(inputs:Dynamic):Float {
        var temp = {
            lightDirection: inputs.lightDirection,
            f0: inputs.f0,
            f90: inputs.f90,
            roughness: inputs.roughness,
            f: inputs.f,
            USE_IRIDESCENCE: inputs.USE_IRIDESCENCE,
            USE_ANISOTROPY: inputs.USE_ANISOTROPY,
            normalView: inputs.normalView != null ? inputs.normalView : NormalNode.transformedNormalView,
            anisotropyT: inputs.anisotropyT,
            anisotropyB: inputs.anisotropyB
        };

        var alpha = temp.roughness.pow2();

        var halfDir = temp.lightDirection.add(PositionNode.positionViewDirection).normalize();

        var dotNL = temp.normalView.dot(temp.lightDirection).clamp();
        var dotNV = temp.normalView.dot(PositionNode.positionViewDirection).clamp();
        var dotNH = temp.normalView.dot(halfDir).clamp();
        var dotVH = PositionNode.positionViewDirection.dot(halfDir).clamp();

        var F = F_Schlick.calculate({f0: temp.f0, f90: temp.f90, dotVH: dotVH});
        var V:Float;
        var D:Float;

        if (temp.USE_IRIDESCENCE != null) {
            F = PropertyNode.iridescence.mix(F, temp.f);
        }

        if (temp.USE_ANISOTROPY != null) {
            var dotTL = temp.anisotropyT.dot(temp.lightDirection);
            var dotTV = temp.anisotropyT.dot(PositionNode.positionViewDirection);
            var dotTH = temp.anisotropyT.dot(halfDir);
            var dotBL = temp.anisotropyB.dot(temp.lightDirection);
            var dotBV = temp.anisotropyB.dot(PositionNode.positionViewDirection);
            var dotBH = temp.anisotropyB.dot(halfDir);

            V = V_GGX_SmithCorrelated_Anisotropic.calculate({alphaT: PropertyNode.alphaT, alphaB: alpha, dotTV: dotTV, dotBV: dotBV, dotTL: dotTL, dotBL: dotBL, dotNV: dotNV, dotNL: dotNL});
            D = D_GGX_Anisotropic.calculate({alphaT: PropertyNode.alphaT, alphaB: alpha, dotNH: dotNH, dotTH: dotTH, dotBH: dotBH});
        } else {
            V = V_GGX_SmithCorrelated.calculate({alpha: alpha, dotNL: dotNL, dotNV: dotNV});
            D = D_GGX.calculate({alpha: alpha, dotNH: dotNH});
        }

        return F * V * D;
    }
}

class Main {
    static function main() {
        // Test the function with sample inputs.
    }
}