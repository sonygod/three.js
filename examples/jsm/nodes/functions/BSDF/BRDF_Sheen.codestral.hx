import js.Browser.document;

class BRDF_Sheen {
    static function D_Charlie(roughness: Float, dotNH: Float): Float {
        var alpha = Math.pow(roughness, 2);
        var invAlpha = 1.0 / alpha;
        var cos2h = Math.pow(dotNH, 2);
        var sin2h = Math.max(Math.sqrt(1.0 - cos2h), 0.0078125);
        return (2.0 + invAlpha) * Math.pow(sin2h, invAlpha * 0.5) / (2.0 * Math.PI);
    }

    static function V_Neubelt(dotNV: Float, dotNL: Float): Float {
        return 1.0 / (4.0 * (dotNL + dotNV - dotNL * dotNV));
    }

    static function BRDF_Sheen(lightDirection: Vector3): Vector3 {
        var positionViewDirection = js.Browser.window.positionViewDirection;
        var halfDir = lightDirection.add(positionViewDirection).normalize();
        var transformedNormalView = js.Browser.window.transformedNormalView;
        var dotNL = Math.max(transformedNormalView.dot(lightDirection), 0);
        var dotNV = Math.max(transformedNormalView.dot(positionViewDirection), 0);
        var dotNH = Math.max(transformedNormalView.dot(halfDir), 0);
        var sheen = js.Browser.window.sheen;
        var sheenRoughness = js.Browser.window.sheenRoughness;
        var D = D_Charlie(sheenRoughness, dotNH);
        var V = V_Neubelt(dotNV, dotNL);
        return sheen.multiply(D).multiply(V);
    }
}