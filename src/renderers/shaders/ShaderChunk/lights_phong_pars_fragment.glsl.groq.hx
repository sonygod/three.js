package three.js.src.renderers.shaders.ShaderChunk;

private class LightsPhongParsFragment {

    public var vViewPosition:Vec3;

    private typedef BlinnPhongMaterial = {
        var diffuseColor:Vec3;
        var specularColor:Vec3;
        var specularShininess:Float;
        var specularStrength:Float;
    }

    public function new() {}

    public function RE_Direct_BlinnPhong(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {
        var dotNL:Float = Math.max(0, Vec3.dot(geometryNormal, directLight.direction));
        var irradiance:Vec3 = new Vec3(directLight.color.x * dotNL, directLight.color.y * dotNL, directLight.color.z * dotNL);

        reflectedLight.directDiffuse += irradiance.multiply(BRDF_Lambert(material.diffuseColor));

        reflectedLight.directSpecular += irradiance.multiply(BRDF_BlinnPhong(directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess) * material.specularStrength);
    }

    public function RE_IndirectDiffuse_BlinnPhong(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {
        reflectedLight.indirectDiffuse += irradiance.multiply(BRDF_Lambert(material.diffuseColor));
    }

    public static inline function RE_Direct():Void {
        RE_Direct_BlinnPhong;
    }

    public static inline function RE_IndirectDiffuse():Void {
        RE_IndirectDiffuse_BlinnPhong;
    }
}