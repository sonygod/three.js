package three.shader;

import haxe.Timer;

class LambertParsFragment {
    public var vViewPosition:Vec3;

    public struct LambertMaterial {
        public var diffuseColor:Vec3;
        public var specularStrength:Float;
    }

    public function new() {}

    public function RE_Direct_Lambert(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:LambertMaterial, reflectedLight:ReflectedLight) {
        var dotNL = Math.max(0, geometryNormal.dot(directLight.direction));
        var irradiance = directLight.color.multiplyScalar(dotNL);
        reflectedLight.directDiffuse += irradiance.multiplyScalar(BRDF_Lambert(material.diffuseColor));
    }

    public function RE_IndirectDiffuse_Lambert(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:LambertMaterial, reflectedLight:ReflectedLight) {
        reflectedLight.indirectDiffuse += irradiance.multiplyScalar(BRDF_Lambert(material.diffuseColor));
    }

    public static inline function RE_Direct(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:LambertMaterial, reflectedLight:ReflectedLight) {
        RE_Direct_Lambert(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    public static inline function RE_IndirectDiffuse(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:LambertMaterial, reflectedLight:ReflectedLight) {
        RE_IndirectDiffuse_Lambert(irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }
}