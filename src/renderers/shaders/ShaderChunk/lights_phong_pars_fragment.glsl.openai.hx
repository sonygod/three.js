@:glsl(
    varying vViewPosition:Vec3;

    struct BlinnPhongMaterial {
        var diffuseColor:Vec3;
        var specularColor:Vec3;
        var specularShininess:Float;
        var specularStrength:Float;
    }

    function RE_Direct_BlinnPhong(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {
        var dotNL = saturate(dot(geometryNormal, directLight.direction));
        var irradiance = dotNL * directLight.color;

        reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);

        reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess) * material.specularStrength;
    }

    function RE_IndirectDiffuse_BlinnPhong(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {
        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    #define RE_Direct RE_Direct_BlinnPhong
    #define RE_IndirectDiffuse RE_IndirectDiffuse_BlinnPhong
)