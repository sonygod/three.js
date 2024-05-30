package three.js.src.renderers.shaders.ShaderChunk;

class LightsToonParsFragment {
    public static var RE_Direct:String = "RE_Direct_Toon";
    public static var RE_IndirectDiffuse:String = "RE_IndirectDiffuse_Toon";

    public static function RE_Direct_Toon(directLight:IncidentLight, geometryPosition:three.js.math.Vector3, geometryNormal:three.js.math.Vector3, geometryViewDir:three.js.math.Vector3, geometryClearcoatNormal:three.js.math.Vector3, material:ToonMaterial, reflectedLight:ReflectedLight):Void {
        var irradiance:three.js.math.Vector3 = getGradientIrradiance(geometryNormal, directLight.direction) * directLight.color;
        reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    public static function RE_IndirectDiffuse_Toon(irradiance:three.js.math.Vector3, geometryPosition:three.js.math.Vector3, geometryNormal:three.js.math.Vector3, geometryViewDir:three.js.math.Vector3, geometryClearcoatNormal:three.js.math.Vector3, material:ToonMaterial, reflectedLight:ReflectedLight):Void {
        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    public static function getGradientIrradiance(normal:three.js.math.Vector3, direction:three.js.math.Vector3):three.js.math.Vector3 {
        // Implementation of getGradientIrradiance function
    }

    public static function BRDF_Lambert(color:three.js.math.Vector3):Float {
        // Implementation of BRDF_Lambert function
    }

    public static class IncidentLight {
        public var direction:three.js.math.Vector3;
        public var color:three.js.math.Vector3;
    }

    public static class ToonMaterial {
        public var diffuseColor:three.js.math.Vector3;
    }

    public static class ReflectedLight {
        public var directDiffuse:three.js.math.Vector3;
        public var indirectDiffuse:three.js.math.Vector3;
    }
}