package three.js.examples.jvm.nodes.functions.BSDF;

import three.js.accessors.NormalNode;
import three.js.accessors.PositionNode;
import three.js.core.PropertyNode;

class BRDF_Sheen {
    static var transformedNormalView:NormalNode;
    static var positionViewDirection:PositionNode;
    static var sheen:PropertyNode<Float>;
    static var sheenRoughness:PropertyNode<Float>;

    static function D_Charlie(roughness:Float, dotNH:Float):Float {
        var alpha = roughness * roughness;
        var invAlpha = 1.0 / alpha;
        var cos2h = dotNH * dotNH;
        var sin2h = Math.max(cos2h - 1.0, 0.0078125);
        return (2.0 + invAlpha) * Math.pow(sin2h, invAlpha * 0.5) / (2.0 * Math.PI);
    }

    static function V_Neubelt(dotNV:Float, dotNL:Float):Float {
        return 1.0 / (4.0 * (dotNL + dotNV - dotNL * dotNV));
    }

    static function BRDF_Sheen(lightDirection:Vector3):Float {
        var halfDir = (lightDirection + positionViewDirection).normalize();
        var dotNL = Math.max(0.0, Math.min(1.0, transformedNormalView.dotProduct(lightDirection)));
        var dotNV = Math.max(0.0, Math.min(1.0, transformedNormalView.dotProduct(positionViewDirection)));
        var dotNH = Math.max(0.0, Math.min(1.0, transformedNormalView.dotProduct(halfDir)));

        var D = D_Charlie(sheenRoughness.value, dotNH);
        var V = V_Neubelt(dotNV, dotNL);

        return sheen.value * D * V;
    }
}