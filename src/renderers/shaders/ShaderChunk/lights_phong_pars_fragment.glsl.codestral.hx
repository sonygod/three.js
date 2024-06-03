class LightsPhongParsFragment {
    public static var vViewPosition: Float;

    class BlinnPhongMaterial {
        public var diffuseColor: Array<Float>;
        public var specularColor: Array<Float>;
        public var specularShininess: Float;
        public var specularStrength: Float;
    }

    public static function RE_Direct_BlinnPhong(directLight: IncidentLight, geometryPosition: Array<Float>, geometryNormal: Array<Float>, geometryViewDir: Array<Float>, geometryClearcoatNormal: Array<Float>, material: BlinnPhongMaterial, reflectedLight: ReflectedLight): Void {
        var dotNL = Math.max(0, dot(geometryNormal, directLight.direction));
        var irradiance = dotNL * directLight.color;

        reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);

        reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess) * material.specularStrength;
    }

    public static function RE_IndirectDiffuse_BlinnPhong(irradiance: Array<Float>, geometryPosition: Array<Float>, geometryNormal: Array<Float>, geometryViewDir: Array<Float>, geometryClearcoatNormal: Array<Float>, material: BlinnPhongMaterial, reflectedLight: ReflectedLight): Void {
        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    }

    public static inline function RE_Direct(directLight: IncidentLight, geometryPosition: Array<Float>, geometryNormal: Array<Float>, geometryViewDir: Array<Float>, geometryClearcoatNormal: Array<Float>, material: BlinnPhongMaterial, reflectedLight: ReflectedLight): Void {
        RE_Direct_BlinnPhong(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    public static inline function RE_IndirectDiffuse(irradiance: Array<Float>, geometryPosition: Array<Float>, geometryNormal: Array<Float>, geometryViewDir: Array<Float>, geometryClearcoatNormal: Array<Float>, material: BlinnPhongMaterial, reflectedLight: ReflectedLight): Void {
        RE_IndirectDiffuse_BlinnPhong(irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    // The dot product function is not defined in the provided code, so you would need to define it or import it from a library.
    public static function dot(a: Array<Float>, b: Array<Float>): Float {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    }
}