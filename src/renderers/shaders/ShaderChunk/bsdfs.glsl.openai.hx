package three.shader;

class Bsdf {
    public static function G_BlinnPhong_Implicit() : Float {
        return 0.25;
    }

    public static function D_BlinnPhong(shininess : Float, dotNH : Float) : Float {
        return Math.PI_RECIPROCAL * (shininess * 0.5 + 1.0) * Math.pow(dotNH, shininess);
    }

    public static function BRDF_BlinnPhong(lightDir : Vec3, viewDir : Vec3, normal : Vec3, specularColor : Vec3, shininess : Float) : Vec3 {
        var halfDir : Vec3 = normalize(lightDir + viewDir);

        var dotNH : Float = saturate(dot(normal, halfDir));
        var dotVH : Float = saturate(dot(viewDir, halfDir));

        var F : Vec3 = F_Schlick(specularColor, 1.0, dotVH);

        var G : Float = G_BlinnPhong_Implicit();
        var D : Float = D_BlinnPhong(shininess, dotNH);

        return F * (G * D);
    }
}