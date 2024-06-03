class LightsLambertParsFragment {
    var vViewPosition:Float;

    class LambertMaterial {
        public var diffuseColor:Array<Float>;
        public var specularStrength:Float;

        public function new(diffuseColor:Array<Float>, specularStrength:Float) {
            this.diffuseColor = diffuseColor;
            this.specularStrength = specularStrength;
        }
    }

    static function RE_Direct_Lambert(directLight:IncidentLight, geometryPosition:Array<Float>, geometryNormal:Array<Float>, geometryViewDir:Array<Float>, geometryClearcoatNormal:Array<Float>, material:LambertMaterial, reflectedLight:ReflectedLight):Void {
        var dotNL:Float = Math.max(0, dot(geometryNormal, directLight.direction));
        var irradiance:Array<Float> = vec3_mul_scalar(directLight.color, dotNL);

        reflectedLight.directDiffuse = vec3_add(reflectedLight.directDiffuse, vec3_mul(irradiance, BRDF_Lambert(material.diffuseColor)));
    }

    static function RE_IndirectDiffuse_Lambert(irradiance:Array<Float>, geometryPosition:Array<Float>, geometryNormal:Array<Float>, geometryViewDir:Array<Float>, geometryClearcoatNormal:Array<Float>, material:LambertMaterial, reflectedLight:ReflectedLight):Void {
        reflectedLight.indirectDiffuse = vec3_add(reflectedLight.indirectDiffuse, vec3_mul(irradiance, BRDF_Lambert(material.diffuseColor)));
    }

    static function RE_Direct(directLight:IncidentLight, geometryPosition:Array<Float>, geometryNormal:Array<Float>, geometryViewDir:Array<Float>, geometryClearcoatNormal:Array<Float>, material:LambertMaterial, reflectedLight:ReflectedLight):Void {
        RE_Direct_Lambert(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    static function RE_IndirectDiffuse(irradiance:Array<Float>, geometryPosition:Array<Float>, geometryNormal:Array<Float>, geometryViewDir:Array<Float>, geometryClearcoatNormal:Array<Float>, material:LambertMaterial, reflectedLight:ReflectedLight):Void {
        RE_IndirectDiffuse_Lambert(irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    // helper functions for vector operations
    static function dot(a:Array<Float>, b:Array<Float>):Float {
        return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
    }

    static function vec3_mul_scalar(a:Array<Float>, b:Float):Array<Float> {
        return [a[0]*b, a[1]*b, a[2]*b];
    }

    static function vec3_mul(a:Array<Float>, b:Array<Float>):Array<Float> {
        return [a[0]*b[0], a[1]*b[1], a[2]*b[2]];
    }

    static function vec3_add(a:Array<Float>, b:Array<Float>):Array<Float> {
        return [a[0]+b[0], a[1]+b[1], a[2]+b[2]];
    }
}