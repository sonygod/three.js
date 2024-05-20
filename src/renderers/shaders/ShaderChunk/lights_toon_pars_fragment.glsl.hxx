class ToonMaterial {
    public var diffuseColor(default, null):Vec3;
}

class IncidentLight {
    public var direction(default, null):Vec3;
    public var color(default, null):Vec3;
}

class ReflectedLight {
    public var directDiffuse(default, null):Vec3;
    public var indirectDiffuse(default, null):Vec3;
}

class ShaderChunk {
    static function RE_Direct_Toon(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:ToonMaterial, reflectedLight:ReflectedLight):Void {
        var irradiance = getGradientIrradiance(geometryNormal, directLight.direction) * directLight.color;
        reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    static function RE_IndirectDiffuse_Toon(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:ToonMaterial, reflectedLight:ReflectedLight):Void {
        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }
}