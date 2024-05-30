package three.js.examples.jsm.exporters;

class GLTFMaterialsSheenExtension {
    private var writer:Dynamic;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_sheen';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.sheen == 0.0) return;

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = {};

        if (material.sheenRoughnessMap != null) {
            var sheenRoughnessMapDef = {
                index: writer.processTexture(material.sheenRoughnessMap),
                texCoord: material.sheenRoughnessMap.channel
            };
            writer.applyTextureTransform(sheenRoughnessMapDef, material.sheenRoughnessMap);
            extensionDef.sheenRoughnessTexture = sheenRoughnessMapDef;
        }

        if (material.sheenColorMap != null) {
            var sheenColorMapDef = {
                index: writer.processTexture(material.sheenColorMap),
                texCoord: material.sheenColorMap.channel
            };
            writer.applyTextureTransform(sheenColorMapDef, material.sheenColorMap);
            extensionDef.sheenColorTexture = sheenColorMapDef;
        }

        extensionDef.sheenRoughnessFactor = material.sheenRoughness;
        extensionDef.sheenColorFactor = material.sheenColor.toArray();

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}