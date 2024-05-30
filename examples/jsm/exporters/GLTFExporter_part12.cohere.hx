class GLTFMaterialsSheenExtension {
    public var writer:Writer;
    public var name:String = 'KHR_materials_sheen';

    public function new(writer:Writer) {
        this.writer = writer;
    }

    public function writeMaterial(material:Material, materialDef:MaterialDef) {
        if (!material.isMeshPhysicalMaterial || material.sheen == 0.0) {
            return;
        }

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = { };

        if (material.sheenRoughnessMap != null) {
            var sheenRoughnessMapDef = {
                'index': writer.processTexture(material.sheenRoughnessMap),
                'texCoord': Std.string(material.sheenRoughnessMap.channel)
            };
            writer.applyTextureTransform(sheenRoughnessMapDef, material.sheenRoughnessMap);
            extensionDef.set('sheenRoughnessTexture', sheenRoughnessMapDef);
        }

        if (material.sheenColorMap != null) {
            var sheenColorMapDef = {
                'index': writer.processTexture(material.sheenColorMap),
                'texCoord': Std.string(material.sheenColorMap.channel)
            };
            writer.applyTextureTransform(sheenColorMapDef, material.sheenColorMap);
            extensionDef.set('sheenColorTexture', sheenColorMapDef);
        }

        extensionDef.set('sheenRoughnessFactor', material.sheenRoughness);
        extensionDef.set('sheenColorFactor', material.sheenColor.toArray());

        if (materialDef.extensions == null) {
            materialDef.extensions = { };
        }
        materialDef.extensions.set(this.name, extensionDef);

        extensionsUsed.set(this.name, true);
    }
}