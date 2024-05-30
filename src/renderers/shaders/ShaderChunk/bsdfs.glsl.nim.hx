package three.js.src.renderers.shaders.ShaderChunk;

class bsdfs {
    public static function G_BlinnPhong_Implicit():Float {
        // geometry term is (n dot l)(n dot v) / 4(n dot l)(n dot v)
        return 0.25;
    }

    public static function D_BlinnPhong(shininess:Float, dotNH:Float):Float {
        return (1.0 / Math.PI) * (shininess * 0.5 + 1.0) * Math.pow(dotNH, shininess);
    }

    public static function BRDF_BlinnPhong(lightDir:three.js.Vector3, viewDir:three.js.Vector3, normal:three.js.Vector3, specularColor:three.js.Vector3, shininess:Float):three.js.Vector3 {
        var halfDir:three.js.Vector3 = lightDir.add(viewDir).normalize();

        var dotNH:Float = Math.min(normal.dot(halfDir), 1.0);
        var dotVH:Float = Math.min(viewDir.dot(halfDir), 1.0);

        var F:three.js.Vector3 = F_Schlick(specularColor, 1.0, dotVH);

        var G:Float = G_BlinnPhong_Implicit();

        var D:Float = D_BlinnPhong(shininess, dotNH);

        return F.multiplyScalar(G * D);
    }
}