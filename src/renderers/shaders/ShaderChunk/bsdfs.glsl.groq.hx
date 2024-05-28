package three.renderers.shaders.ShaderChunk;

class Bsdfs {
    public static function G_BlinnPhong_Implicit():Float {
        // geometry term is (n dot l)(n dot v) / 4(n dot l)(n dot v)
        return 0.25;
    }

    public static function D_BlinnPhong(shininess:Float, dotNH:Float):Float {
        return 1 / Math.PI * (shininess * 0.5 + 1.0) * Math.pow(dotNH, shininess);
    }

    public static function BRDF_BlinnPhong(lightDir:Vec3, viewDir:Vec3, normal:Vec3, specularColor:Vec3, shininess:Float):Vec3 {
        var halfDir:Vec3 = Vec3.normalize(lightDir.add(viewDir));
        var dotNH:Float = Math.max(0, Vec3.dot(normal, halfDir));
        var dotVH:Float = Math.max(0, Vec3.dot(viewDir, halfDir));

        var F:Vec3 = F_Schlick(specularColor, 1.0, dotVH);
        var G:Float = G_BlinnPhong_Implicit();
        var D:Float = D_BlinnPhong(shininess, dotNH);

        return F.multiply(G * D);
    }
}