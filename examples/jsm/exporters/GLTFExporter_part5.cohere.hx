class GLTFMaterialsClearcoatExtension {
    public var writer:Writer;
    public var name:String = 'KHR_materials_clearcoat';

    public function new(writer:Writer) {
        this.writer = writer;
    }

    public function writeMaterial(material:Material, materialDef:MaterialDef) {
        if (!material.isMeshPhysicalMaterial || material.clearcoat == 0) {
            return;
        }

        var extensionsUsed = writer.extensionsUsed;
        var extensionDef = { };

        extensionDef.clearcoatFactor = material.clearcoat;

        if (material.clearcoatMap != null) {
            var clearcoatMapDef = {
                index: writer.processTexture(material.clearcoatMap),
                texCoord: material.clearcoatMap.channel
            };
            writer.applyTextureTransform(clearcoatMapDef, material.clearcoatMap);
            extensionDef.clearcoatTexture = clearcoatMapDef;
        }

        extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;

        if (material.clearcoatRoughnessMap != null) {
            var clearcoatRoughnessMapDef = {
                index: writer.processTexture(material.clearcoatRoughnessMap),
                texCoord: material.clearcoatRoughnessMap.channel
            };
            writer.applyTextureTransform(clearcoatRoughnessMapDef, material.clearcoatRoughnessMap);
            extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
        }

        if (material.clearcoatNormalMap != null) {
            var clearcoatNormalMapDef = {
                index: writer.processTexture(material.clearcoatNormalMap),
                texCoord: material.clearcoatNormalMap.channel
            };

            if (material.clearcoatNormalScale.x != 1) {
                clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;
            }

            writer.applyTextureTransform(clearcoatNormalMapDef, material.clearcoatNormalMap);
            extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
        }

        materialDef.extensions = materialDef.extensions ?? { };
        materialDef.extensions[name] = extensionDef;

        extensionsUsed[name] = true;
    }
}