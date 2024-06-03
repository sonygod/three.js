class BSDFS {
    static function G_BlinnPhong_Implicit(): Float {
        return 0.25;
    }

    static function D_BlinnPhong(shininess: Float, dotNH: Float): Float {
        return (1.0 / Math.PI) * (shininess * 0.5 + 1.0) * Math.pow(dotNH, shininess);
    }

    static function BRDF_BlinnPhong(lightDir: Float3, viewDir: Float3, normal: Float3, specularColor: Float3, shininess: Float): Float3 {
        var halfDir = (lightDir + viewDir).normalize();

        var dotNH = Math.max(0.0, normal.dot(halfDir));
        var dotVH = Math.max(0.0, viewDir.dot(halfDir));

        var F = F_Schlick(specularColor, 1.0, dotVH);

        var G = G_BlinnPhong_Implicit();

        var D = D_BlinnPhong(shininess, dotNH);

        return F * (G * D);
    }
}