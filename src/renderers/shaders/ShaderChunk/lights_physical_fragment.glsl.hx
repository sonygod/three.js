package three.shader;

class PhysicalMaterial {
    public var diffuseColor:Vec3;
    public var roughness:Float;
    public var specularColor:Vec3;
    public var specularF90:Float;
    public var clearcoat:Float;
    public var clearcoatRoughness:Float;
    public var clearcoatF0:Vec3;
    public var clearcoatF90:Float;
    public var dispersion:Float;
    public var iridescence:Float;
    public var iridescenceIOR:Float;
    public var sheenColor:Vec3;
    public var sheenRoughness:Float;
    public var anisotropy:Float;
    public var alphaT:Float;
    public var anisotropyT:Vec3;
    public var anisotropyB:Vec3;

    public function new() {}

    public function init() {
        diffuseColor = new Vec3(0, 0, 0);
        roughness = 0.0;
        specularColor = new Vec3(0, 0, 0);
        specularF90 = 0.0;
        clearcoat = 0.0;
        clearcoatRoughness = 0.0;
        clearcoatF0 = new Vec3(0, 0, 0);
        clearcoatF90 = 0.0;
        dispersion = 0.0;
        iridescence = 0.0;
        iridescenceIOR = 0.0;
        sheenColor = new Vec3(0, 0, 0);
        sheenRoughness = 0.0;
        anisotropy = 0.0;
        alphaT = 0.0;
        anisotropyT = new Vec3(0, 0, 0);
        anisotropyB = new Vec3(0, 0, 0);
    }

    public function setup(diffuseColorRGB:Vec3, metalnessFactor:Float, roughnessFactor:Float, ior:Float,
                         specularIntensity:Float, specularColor:Vec3, clearcoat:Float, clearcoatRoughness:Float,
                         dispersion:Float, iridescence:Float, iridescenceIOR:Float, sheenColor:Vec3, sheenRoughness:Float,
                         anisotropyVector:Vec2) {
        var dxy:Vec3 = new Vec3(Math.max(Math.abs(dFdx(nonPerturbedNormal)), Math.abs(dFdy(nonPerturbedNormal))));
        var geometryRoughness:Float = Math.max(Math.max(dxy.x, dxy.y), dxy.z);

        diffuseColor = diffuseColorRGB * (1.0 - metalnessFactor);

        roughness = Math.max(roughnessFactor, 0.0525);
        roughness += geometryRoughness;
        roughness = Math.min(roughness, 1.0);

        #if IOR
        this.ior = ior;

        #if USE_SPECULAR
        var specularIntensityFactor:Float = specularIntensity;
        var specularColorFactor:Vec3 = specularColor;

        #if USE_SPECULAR_COLORMAP
        specularColorFactor *= texture2D(specularColorMap, vSpecularColorMapUv).rgb;
        #end

        #if USE_SPECULAR_INTENSITYMAP
        specularIntensityFactor *= texture2D(specularIntensityMap, vSpecularIntensityMapUv).a;
        #end

        specularF90 = Math.mix(specularIntensityFactor, 1.0, metalnessFactor);
        #else
        specularIntensityFactor = 1.0;
        specularColorFactor = new Vec3(1.0);
        specularF90 = 1.0;
        #end

        specularColor = Math.mix(Math.min(Math.pow(specularColorFactor, 2) * specularIntensityFactor, new Vec3(1.0)) * specularIntensityFactor, diffuseColorRGB, metalnessFactor);
        #else
        specularColor = Math.mix(new Vec3(0.04), diffuseColorRGB, metalnessFactor);
        specularF90 = 1.0;
        #end

        #if USE_CLEARCOAT
        this.clearcoat = clearcoat;
        this.clearcoatRoughness = clearcoatRoughness;
        this.clearcoatF0 = new Vec3(0.04);
        this.clearcoatF90 = 1.0;

        #if USE_CLEARCOATMAP
        this.clearcoat *= texture2D(clearcoatMap, vClearcoatMapUv).x;
        #end

        #if USE_CLEARCOAT_ROUGHNESSMAP
        this.clearcoatRoughness *= texture2D(clearcoatRoughnessMap, vClearcoatRoughnessMapUv).y;
        #end

        this.clearcoat = Math.sat(this.clearcoat);
        this.clearcoatRoughness = Math.max(this.clearcoatRoughness, 0.0525);
        this.clearcoatRoughness += geometryRoughness;
        this.clearcoatRoughness = Math.min(this.clearcoatRoughness, 1.0);
        #end

        #if USE_DISPERSION
        this.dispersion = dispersion;
        #end

        #if USE_IRIDESCENCE
        this.iridescence = iridescence;
        this.iridescenceIOR = iridescenceIOR;

        #if USE_IRIDESCENCEMAP
        this.iridescence *= texture2D(iridescenceMap, vIridescenceMapUv).r;
        #end

        #if USE_IRIDESCENCE_THICKNESSMAP
        this.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D(iridescenceThicknessMap, vIridescenceThicknessMapUv).g + iridescenceThicknessMinimum;
        #else
        this.iridescenceThickness = iridescenceThicknessMaximum;
        #end
        #end

        #if USE_SHEEN
        this.sheenColor = sheenColor;

        #if USE_SHEEN_COLORMAP
        this.sheenColor *= texture2D(sheenColorMap, vSheenColorMapUv).rgb;
        #end

        this.sheenRoughness = Math.clamp(sheenRoughness, 0.07, 1.0);

        #if USE_SHEEN_ROUGHNESSMAP
        this.sheenRoughness *= texture2D(sheenRoughnessMap, vSheenRoughnessMapUv).a;
        #end
        #end

        #if USE_ANISOTROPY
        #if USE_ANISOTROPYMAP
        var anisotropyMat:Mat2 = new Mat2(anisotropyVector.x, anisotropyVector.y, -anisotropyVector.y, anisotropyVector.x);
        var anisotropyPolar:Vec3 = texture2D(anisotropyMap, vAnisotropyMapUv).rgb;
        var anisotropyV:Vec2 = anisotropyMat.multVec(new Vec2(anisotropyPolar.rg)).mult(anisotropyPolar.b);
        #else
        var anisotropyV:Vec2 = anisotropyVector;
        #end

        this.anisotropy = Math.length(anisotropyV);

        if (this.anisotropy == 0.0) {
            anisotropyV = new Vec2(1.0, 0.0);
        } else {
            anisotropyV = anisotropyV.div(this.anisotropy);
            this.anisotropy = Math.sat(this.anisotropy);
        }

        this.alphaT = Math.mix(Math.pow2(this.roughness), 1.0, Math.pow2(this.anisotropy));
        this.anisotropyT = tbn[0].mult(anisotropyV.x) + tbn[1].mult(anisotropyV.y);
        this.anisotropyB = tbn[1].mult(anisotropyV.x) - tbn[0].mult(anisotropyV.y);
        #end
    }
}