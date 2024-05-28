package three.shader;

@:glsl("Fragment")
class LightsLambertParsFragment {

    @:varying var vViewPosition:Vec3;

    private typedef LambertMaterial = {
        var diffuseColor:Vec3;
        var specularStrength:Float;
    }

    private function RE_Direct_Lambert(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:LambertMaterial, reflectedLight:ReflectedLight) {
        var dotNL = saturate(dot(geometryNormal, directLight.direction));
        var irradiance = dotNL * directLight.color;
        reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    private function RE_IndirectDiffuse_Lambert(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:LambertMaterial, reflectedLight:ReflectedLight) {
        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    @:define("RE_Direct") private static inline function RE_Direct_Lambert;
    @:define("RE_IndirectDiffuse") private static inline function RE_IndirectDiffuse_Lambert;
}