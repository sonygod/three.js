package three.js.examples.jm.exporters;

class GLTFMaterialsSpecularExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_specular';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || (material.specularIntensity == 1.0 &&
            material.specularColor.equals(DEFAULT_SPECULAR_COLOR) &&
            material.specularIntensityMap == null && material.specularColorMap == null)) {
            return;
        }

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        if (material.specularIntensityMap != null) {
            var specularIntensityMapDef:Dynamic = {
                index: writer.processTexture(material.specularIntensityMap),
                texCoord: material.specularIntensityMap.channel
            };
            writer.applyTextureTransform(specularIntensityMapDef, material.specularIntensityMap);
            extensionDef.specularTexture = specularIntensityMapDef;
        }

        if (material.specularColorMap != null) {
            var specularColorMapDef:Dynamic = {
                index: writer.processTexture(material.specularColorMap),
                texCoord: material.specularColorMap.channel
            };
            writer.applyTextureTransform(specularColorMapDef, material.specularColorMap);
            extensionDef.specularColorTexture = specularColorMapDef;
        }

        extensionDef.specularFactor = material.specularIntensity;
        extensionDef.specularColorFactor = material.specularColor.toArray();

        materialDef.extensions = materialDef.extensions || {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}