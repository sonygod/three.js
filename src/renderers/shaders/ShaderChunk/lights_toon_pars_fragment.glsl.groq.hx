package three.shader;

import three.shader.ReflectedLight;

class ShaderChunk {
  static var vViewPosition:Vec3;

  static class ToonMaterial {
    public var diffuseColor:Vec3;
  }

  static function RE_Direct_Toon(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:ToonMaterial, reflectedLight:ReflectedLight) {
    var irradiance:Vec3 = getGradientIrradiance(geometryNormal, directLight.direction) * directLight.color;
    reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
  }

  static function RE_IndirectDiffuse_Toon(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:ToonMaterial, reflectedLight:ReflectedLight) {
    reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
  }

  static inline function RE_Direct(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:ToonMaterial, reflectedLight:ReflectedLight) {
    RE_Direct_Toon(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
  }

  static inline function RE_IndirectDiffuse(irradiance:Vec3, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:ToonMaterial, reflectedLight:ReflectedLight) {
    RE_IndirectDiffuse_Toon(irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
  }
}