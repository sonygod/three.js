package three.shader;

class PhysicalMaterial {
    public var diffuseColor:Vec3;
    public var roughness:Float;
    public var ior:Float;
    public var specularF90:Float;
    public var specularColor:Vec3;
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

class ShaderChunk {
    public static function lightsPhysicalFragment():String {
        var material:PhysicalMaterial = new PhysicalMaterial();

        material.diffuseColor = new Vec3(diffuseColor.rgb * (1.0 - metalnessFactor));

        var dxy:Vec3 = new Vec3(Math.max(Math.abs(dFdx(nonPerturbedNormal)), Math.abs(dFdy(nonPerturbedNormal))));
        var geometryRoughness:Float = Math.max(Math.max(dxy.x, dxy.y), dxy.z);

        material.roughness = Math.max(roughnessFactor, 0.0525);
        material.roughness += geometryRoughness;
        material.roughness = Math.min(material.roughness, 1.0);

        #if IOR
            material.ior = ior;

            #if USE_SPECULAR
                var specularIntensityFactor:Float = specularIntensity;
                var specularColorFactor:Vec3 = specularColor;

                #if USE_SPECULAR_COLORMAP
                    specularColorFactor *= texture2D(specularColorMap, vSpecularColorMapUv).rgb;
                #end

                #if USE_SPECULAR_INTENSITYMAP
                    specularIntensityFactor *= texture2D(specularIntensityMap, vSpecularIntensityMapUv).a;
                #end

                material.specularF90 = mix(specularIntensityFactor, 1.0, metalnessFactor);

            #else
                specularIntensityFactor = 1.0;
                specularColorFactor = new Vec3(1.0);
                material.specularF90 = 1.0;
            #end

            material.specularColor = mix(min(pow2((material.ior - 1.0) / (material.ior + 1.0)) * specularColorFactor, new Vec3(1.0)) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor);
        #else
            material.specularColor = mix(new Vec3(0.04), diffuseColor.rgb, metalnessFactor);
            material.specularF90 = 1.0;
        #end

        #if USE_CLEARCOAT
            material.clearcoat = clearcoat;
            material.clearcoatRoughness = clearcoatRoughness;
            material.clearcoatF0 = new Vec3(0.04);
            material.clearcoatF90 = 1.0;

            #if USE_CLEARCOATMAP
                material.clearcoat *= texture2D(clearcoatMap, vClearcoatMapUv).x;
            #end

            #if USE_CLEARCOAT_ROUGHNESSMAP
                material.clearcoatRoughness *= texture2D(clearcoatRoughnessMap, vClearcoatRoughnessMapUv).y;
            #end

            material.clearcoat = saturate(material.clearcoat); // Burley clearcoat model
            material.clearcoatRoughness = Math.max(material.clearcoatRoughness, 0.0525);
            material.clearcoatRoughness += geometryRoughness;
            material.clearcoatRoughness = Math.min(material.clearcoatRoughness, 1.0);
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
                var anisotropyMat:Mat2 = new Mat2(anisotropyVector.x, anisotropyVector.y, -anisotropyVector.y, anisotropyVector.x);
                var anisotropyPolar:Vec3 = texture2D(anisotropyMap, vAnisotropyMapUv).rgb;
                var anisotropyV:Vec2 = anisotropyMat.multMatVec(new Vec2(anisotropyPolar.rg)) * anisotropyPolar.b;
            #else
                var anisotropyV:Vec2 = anisotropyVector;
            #end

            material.anisotropy = anisotropyV.length();

            if (material.anisotropy == 0.0) {
                anisotropyV = new Vec2(1.0, 0.0);
            } else {
                anisotropyV = anisotropyV.divideScalar(material.anisotropy);
                material.anisotropy = saturate(material.anisotropy);
            }

            material.alphaT = mix(pow2(material.roughness), 1.0, pow2(material.anisotropy));
            material.anisotropyT = tbn[0] * anisotropyV.x + tbn[1] * anisotropyV.y;
            material.anisotropyB = tbn[1] * anisotropyV.x - tbn[0] * anisotropyV.y;
        #end

        return material;
    }
}