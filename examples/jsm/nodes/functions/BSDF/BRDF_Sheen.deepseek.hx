import three.examples.jsm.nodes.accessors.NormalNode;
import three.examples.jsm.nodes.accessors.PositionNode;
import three.examples.jsm.nodes.core.PropertyNode;
import three.examples.jsm.nodes.shadernode.ShaderNode;

class BRDF_Sheen {
    static function D_Charlie(roughness:Float, dotNH:Float):Float {
        var alpha = Math.pow(roughness, 2.0);
        var invAlpha = 1.0 / alpha;
        var cos2h = Math.pow(dotNH, 2.0);
        var sin2h = Math.max(1.0 - cos2h, 0.0078125);
        return (2.0 + invAlpha) * Math.pow(sin2h, invAlpha * 0.5) / (2.0 * Math.PI);
    }

    static function V_Neubelt(dotNV:Float, dotNL:Float):Float {
        return 1.0 / (4.0 * (dotNL + dotNV - dotNL * dotNV));
    }

    static function BRDF_Sheen(lightDirection:Float):Float {
        var halfDir = lightDirection + PositionNode.positionViewDirection;
        var dotNL = Math.max(0.0, Math.min(NormalNode.transformedNormalView.dot(lightDirection), 1.0));
        var dotNV = Math.max(0.0, Math.min(NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection), 1.0));
        var dotNH = Math.max(0.0, Math.min(NormalNode.transformedNormalView.dot(halfDir), 1.0));
        var D = D_Charlie(PropertyNode.sheenRoughness, dotNH);
        var V = V_Neubelt(dotNV, dotNL);
        return PropertyNode.sheen * D * V;
    }
}