package three.shader;

class PhysicalMaterial {
    public var diffuseColor:Vec3;
    public var roughness:Float;
    public var ior:Float;
    public var specularColor:Vec3;
    public var specularF90:Float;
    public var clearcoat:Float;
    public var clearcoatRoughness:Float;
    public var clearcoatF0:Vec3;
    public var clearcoatF90:Float;
    public var dispersion:Float;
    public var iridescence:Float;
    public var iridescenceIOR:Float;
    public var iridescenceThickness:Float;
    public var sheenColor:Vec3;
    public var sheenRoughness:Float;
    public var anisotropy:Float;
    public var alphaT:Float;
    public var anisotropyT:Vec3;
    public var anisotropyB:Vec3;
}

class LightsPhysicalFragment {
    public static function frag(material:PhysicalMaterial, diffuseColor:Vec3, metalnessFactor:Float, nonPerturbedNormal:Vec3, roughnessFactor:Float, ior:Float, specularIntensity:Float, specularColor:Vec3, clearcoat:Float, clearcoatRoughness:Float, dispersion:Float, iridescence:Float, iridescenceIOR:Float, iridescenceThickness:Float, sheenColor:Vec3, sheenRoughness:Float, anisotropyVector:Vec2) {
        material.diffuseColor = diffuseColor.rgb * (1.0 - metalnessFactor);

        var dxy = max(abs(dFdx(nonPerturbedNormal)), abs(dFdy(nonPerturbedNormal)));
        var geometryRoughness = max(max(dxy.x, dxy.y), dxy.z);

        material.roughness = max(roughnessFactor, 0.0525) + geometryRoughness;
        material.roughness = min(material.roughness, 1.0);

        #if IOR
            material.ior = ior;

            #if USE_SPECULAR
                var specularIntensityFactor = specularIntensity;
                var specularColorFactor = specularColor;

                #if USE_SPECULAR_COLORMAP
                    specularColorFactor *= texture2D(specularColorMap, vSpecularColorMapUv).rgb;
                #end

                #if USE_SPECULAR_INTENSITYMAP
                    specularIntensityFactor *= texture2D(specularIntensityMap, vSpecularIntensityMapUv).a;
                #end

                material.specularF90 = mix(specularIntensityFactor, 1.0, metalnessFactor);

            #else
                var specularIntensityFactor = 1.0;
                var specularColorFactor = Vec3.one();
                material.specularF90 = 1.0;
            #end

            material.specularColor = mix(min(pow2((material.ior - 1.0) / (material.ior + 1.0)) * specularColorFactor, Vec3.one()) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor);
        #else
            material.specularColor = mix(Vec3.fromArray([0.04, 0.04, 0.04]), diffuseColor.rgb, metalnessFactor);
            material.specularF90 = 1.0;
        #end

        #if USE_CLEARCOAT
            material.clearcoat = clearcoat;
            material.clearcoatRoughness = clearcoatRoughness;
            material.clearcoatF0 = Vec3.fromArray([0.04, 0.04, 0.04]);
            material.clearcoatF90 = 1.0;

            #if USE_CLEARCOATMAP
                material.clearcoat *= texture2D(clearcoatMap, vClearcoatMapUv).x;
            #end

            #if USE_CLEARCOAT_ROUGHNESSMAP
                material.clearcoatRoughness *= texture2D(clearcoatRoughnessMap, vClearcoatRoughnessMapUv).y;
            #end

            material.clearcoat = saturate(material.clearcoat); // Burley clearcoat model
            material.clearcoatRoughness = max(material.clearcoatRoughness, 0.0525);
            material.clearcoatRoughness += geometryRoughness;
            material.clearcoatRoughness = min(material.clearcoatRoughness, 1.0);
        #end

        #if USE_DISPERSION
            material.dispersion = dispersion;
        #end

        #if USE_IRIDESCENCE
            material.iridescence = iridescence;
            material.iridescenceIOR = iridescenceIOR;

            #if USE_IRIDESCENCEMAP
                material.iridescence *= texture2D(iridescenceMap, vIridescenceMapUv).r;
            #end

            #if USE_IRIDESCENCE_THICKNESSMAP
                material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D(iridescenceThicknessMap, vIridescenceThicknessMapUv).g + iridescenceThicknessMinimum;
            #else
                material.iridescenceThickness = iridescenceThicknessMaximum;
            #end
        #end

        #if USE_SHEEN
            material.sheenColor = sheenColor;

            #if USE_SHEEN_COLORMAP
                material.sheenColor *= texture2D(sheenColorMap, vSheenColorMapUv).rgb;
            #end

            material.sheenRoughness = clamp(sheenRoughness, 0.07, 1.0);

            #if USE_SHEEN_ROUGHNESSMAP
                material.sheenRoughness *= texture2D(sheenRoughnessMap, vSheenRoughnessMapUv).a;
            #end
        #end

        #if USE_ANISOTROPY
            #if USE_ANISOTROPYMAP
                var anisotropyMat = new Mat2(anisotropyVector.x, anisotropyVector.y, -anisotropyVector.y, anisotropyVector.x);
                var anisotropyPolar = texture2D(anisotropyMap, vAnisotropyMapUv).rgb;
                var anisotropyV = anisotropyMat.multVec(new Vec2(anisotropyPolar.rg)) * anisotropyPolar.b;
            #else
                var anisotropyV = anisotropyVector;
            #end

            material.anisotropy = length(anisotropyV);

            if (material.anisotropy == 0.0) {
                anisotropyV = new Vec2(1.0, 0.0);
            } else {
                anisotropyV /= material.anisotropy;
                material.anisotropy = saturate(material.anisotropy);
            }

            material.alphaT = mix(pow2(material.roughness), 1.0, pow2(material.anisotropy));

            material.anisotropyT = tbn[0] * anisotropyV.x + tbn[1] * anisotropyV.y;
            material.anisotropyB = tbn[1] * anisotropyV.x - tbn[0] * anisotropyV.y;
        #end
    }
}