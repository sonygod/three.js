package three.js.examples.jsm.exporters;

class GLTFMaterialsSheenExtension {
    private var writer:Dynamic;
    private var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_sheen';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.sheen == 0.0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        if (material.sheenRoughnessMap != null) {
            var sheenRoughnessMapDef:Dynamic = {
                index: writer.processTexture(material.sheenRoughnessMap),
                texCoord: material.sheenRoughnessMap.channel
            };
            writer.applyTextureTransform(sheenRoughnessMapDef, material.sheenRoughnessMap);
            extensionDef.sheenRoughnessTexture = sheenRoughnessMapDef;
        }

        if (material.sheenColorMap != null) {
            var sheenColorMapDef:Dynamic = {
                index: writer.processTexture(material.sheenColorMap),
                texCoord: material.sheenColorMap.channel
            };
            writer.applyTextureTransform(sheenColorMapDef, material.sheenColorMap);
            extensionDef.sheenColorTexture = sheenColorMapDef;
        }

        extensionDef.sheenRoughnessFactor = material.sheenRoughness;
        extensionDef.sheenColorFactor = material.sheenColor.toArray();

        materialDef.extensions = materialDef.extensions || {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}