class GLTFMaterialsSpecularExtension {
    public var writer:Writer;
    public var name:String = 'KHR_materials_specular';

    public function new(writer:Writer) {
        this.writer = writer;
    }

    public function writeMaterial(material:Material, materialDef:MaterialDef) {
        if (!material.isMeshPhysicalMaterial || (material.specularIntensity == 1.0 &&
            material.specularColor == DEFAULT_SPECULAR_COLOR &&
            material.specularIntensityMap == null && material.specularColorMap == null)) {
            return;
        }

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = { };

        if (material.specularIntensityMap != null) {
            var specularIntensityMapDef = {
                'index': writer.processTexture(material.specularIntensityMap),
                'texCoord': material.specularIntensityMap.channel
            };
            writer.applyTextureTransform(specularIntensityMapDef, material.specularIntensityMap);
            extensionDef.specularTexture = specularIntensityMapDef;
        }

        if (material.specularColorMap != null) {
            var specularColorMapDef = {
                'index': writer.processTexture(material.specularColorMap),
                'texCoord': material.specularColorMap.channel
            };
            writer.applyTextureTransform(specularColorMapDef, material.specularColorMap);
            extensionDef.specularColorTexture = specularColorMapDef;
        }

        extensionDef.specularFactor = material.specularIntensity;
        extensionDef.specularColorFactor = material.specularColor.toArray();

        materialDef.extensions = materialDef.extensions ?? { };
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}