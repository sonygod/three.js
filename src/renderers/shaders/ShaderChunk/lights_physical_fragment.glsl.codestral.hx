import js.Browser.document;

class LightsPhysicalFragment {
    public function new() {
    }

    public function process(diffuseColor: Float, metalnessFactor: Float, roughnessFactor: Float,
                            nonPerturbedNormal: Float, ior: Float, specularIntensity: Float,
                            specularColor: Float, clearcoat: Float, clearcoatRoughness: Float,
                            dispersion: Float, iridescence: Float, iridescenceIOR: Float,
                            iridescenceThicknessMaximum: Float, iridescenceThicknessMinimum: Float,
                            sheenColor: Float, sheenRoughness: Float, anisotropyVector: Float,
                            tbn: Array<Float>): PhysicalMaterial {
        var material:PhysicalMaterial = new PhysicalMaterial();
        material.diffuseColor = diffuseColor * (1.0 - metalnessFactor);

        var dxy = js.Array2.max(js.Array2.map(js.Array2.abs(js.Array2.dFdx(nonPerturbedNormal)), js.Array2.abs(js.Array2.dFdy(nonPerturbedNormal))));
        var geometryRoughness = js.Array2.max(dxy);

        material.roughness = js.Math.max(roughnessFactor, 0.0525);
        material.roughness += geometryRoughness;
        material.roughness = js.Math.min(material.roughness, 1.0);

        if (Std.is(ior, Dynamic)) {
            material.ior = ior;

            var specularIntensityFactor = specularIntensity;
            var specularColorFactor = specularColor;

            if (Std.is(specularColor, Dynamic)) {
                specularColorFactor *= texture2D(specularColorMap, vSpecularColorMapUv);
            }

            if (Std.is(specularIntensity, Dynamic)) {
                specularIntensityFactor *= texture2D(specularIntensityMap, vSpecularIntensityMapUv).a;
            }

            material.specularF90 = js.Math.mix(specularIntensityFactor, 1.0, metalnessFactor);
            material.specularColor = js.Math.mix(js.Math.min(js.Math.pow((material.ior - 1.0) / (material.ior + 1.0), 2) * specularColorFactor, 1.0) * specularIntensityFactor, diffuseColor, metalnessFactor);
        } else {
            material.specularColor = js.Math.mix(0.04, diffuseColor, metalnessFactor);
            material.specularF90 = 1.0;
        }

        if (Std.is(clearcoat, Dynamic)) {
            material.clearcoat = clearcoat;
            material.clearcoatRoughness = clearcoatRoughness;
            material.clearcoatF0 = 0.04;
            material.clearcoatF90 = 1.0;

            if (Std.is(clearcoatMap, Dynamic)) {
                material.clearcoat *= texture2D(clearcoatMap, vClearcoatMapUv).x;
            }

            if (Std.is(clearcoatRoughnessMap, Dynamic)) {
                material.clearcoatRoughness *= texture2D(clearcoatRoughnessMap, vClearcoatRoughnessMapUv).y;
            }

            material.clearcoat = js.Math.saturate(material.clearcoat);
            material.clearcoatRoughness = js.Math.max(material.clearcoatRoughness, 0.0525);
            material.clearcoatRoughness += geometryRoughness;
            material.clearcoatRoughness = js.Math.min(material.clearcoatRoughness, 1.0);
        }

        if (Std.is(dispersion, Dynamic)) {
            material.dispersion = dispersion;
        }

        if (Std.is(iridescence, Dynamic)) {
            material.iridescence = iridescence;
            material.iridescenceIOR = iridescenceIOR;

            if (Std.is(iridescenceMap, Dynamic)) {
                material.iridescence *= texture2D(iridescenceMap, vIridescenceMapUv).r;
            }

            if (Std.is(iridescenceThicknessMap, Dynamic)) {
                material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D(iridescenceThicknessMap, vIridescenceThicknessMapUv).g + iridescenceThicknessMinimum;
            } else {
                material.iridescenceThickness = iridescenceThicknessMaximum;
            }
        }

        if (Std.is(sheenColor, Dynamic)) {
            material.sheenColor = sheenColor;

            if (Std.is(sheenColorMap, Dynamic)) {
                material.sheenColor *= texture2D(sheenColorMap, vSheenColorMapUv);
            }

            material.sheenRoughness = js.Math.clamp(sheenRoughness, 0.07, 1.0);

            if (Std.is(sheenRoughnessMap, Dynamic)) {
                material.sheenRoughness *= texture2D(sheenRoughnessMap, vSheenRoughnessMapUv).a;
            }
        }

        if (Std.is(anisotropyVector, Dynamic)) {
            var anisotropyV = anisotropyVector;

            if (Std.is(anisotropyMap, Dynamic)) {
                var anisotropyMat = new Float(new Array<Dynamic>(anisotropyVector.x, anisotropyVector.y, -anisotropyVector.y, anisotropyVector.x));
                var anisotropyPolar = texture2D(anisotropyMap, vAnisotropyMapUv);
                anisotropyV = anisotropyMat * js.Math.normalize(2.0 * anisotropyPolar.rg - 1.0) * anisotropyPolar.b;
            }

            material.anisotropy = js.Math.length(anisotropyV);

            if (material.anisotropy == 0.0) {
                anisotropyV = new Float(new Array<Dynamic>(1.0, 0.0));
            } else {
                anisotropyV /= material.anisotropy;
                material.anisotropy = js.Math.saturate(material.anisotropy);
            }

            material.alphaT = js.Math.mix(js.Math.pow(material.roughness, 2), 1.0, js.Math.pow(material.anisotropy, 2));
            material.anisotropyT = tbn[0] * anisotropyV.x + tbn[1] * anisotropyV.y;
            material.anisotropyB = tbn[1] * anisotropyV.x - tbn[0] * anisotropyV.y;
        }

        return material;
    }
}

class PhysicalMaterial {
    public var diffuseColor: Float;
    public var roughness: Float;
    public var specularColor: Float;
    public var specularF90: Float;
    public var ior: Float;
    public var clearcoat: Float;
    public var clearcoatRoughness: Float;
    public var clearcoatF0: Float;
    public var clearcoatF90: Float;
    public var dispersion: Float;
    public var iridescence: Float;
    public var iridescenceIOR: Float;
    public var iridescenceThickness: Float;
    public var sheenColor: Float;
    public var sheenRoughness: Float;
    public var anisotropy: Float;
    public var alphaT: Float;
    public var anisotropyT: Float;
    public var anisotropyB: Float;
}