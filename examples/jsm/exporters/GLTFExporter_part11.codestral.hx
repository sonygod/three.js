class GLTFMaterialsSpecularExtension {
    var writer: dynamic;
    var name: String;

    public function new(writer: dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_specular';
    }

    public function writeMaterial(material: dynamic, materialDef: dynamic) {
        if (!material.isMeshPhysicalMaterial ||
            (material.specularIntensity == 1.0 &&
            material.specularColor.every((value, index) => value == DEFAULT_SPECULAR_COLOR[index]) &&
            !material.specularIntensityMap && !material.specularColorMap)) {
            return;
        }

        var extensionsUsed = this.writer.extensionsUsed;
        var extensionDef = {};

        if (material.specularIntensityMap != null) {
            var specularIntensityMapDef = {
                index: this.writer.processTexture(material.specularIntensityMap),
                texCoord: material.specularIntensityMap.channel
            };
            this.writer.applyTextureTransform(specularIntensityMapDef, material.specularIntensityMap);
            extensionDef.specularTexture = specularIntensityMapDef;
        }

        if (material.specularColorMap != null) {
            var specularColorMapDef = {
                index: this.writer.processTexture(material.specularColorMap),
                texCoord: material.specularColorMap.channel
            };
            this.writer.applyTextureTransform(specularColorMapDef, material.specularColorMap);
            extensionDef.specularColorTexture = specularColorMapDef;
        }

        extensionDef.specularFactor = material.specularIntensity;
        extensionDef.specularColorFactor = material.specularColor;

        if (materialDef.extensions == null) {
            materialDef.extensions = {};
        }

        materialDef.extensions[this.name] = extensionDef;
        extensionsUsed[this.name] = true;
    }
}