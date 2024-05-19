package three.js.examples.jsm.exporters;

class GLTFMaterialsClearcoatExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_clearcoat';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.clearcoat == 0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        extensionDef.clearcoatFactor = material.clearcoat;

        if (material.clearcoatMap != null) {
            var clearcoatMapDef:Dynamic = {
                index: writer.processTexture(material.clearcoatMap),
                texCoord: material.clearcoatMap.channel
            };
            writer.applyTextureTransform(clearcoatMapDef, material.clearcoatMap);
            extensionDef.clearcoatTexture = clearcoatMapDef;
        }

        extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;

        if (material.clearcoatRoughnessMap != null) {
            var clearcoatRoughnessMapDef:Dynamic = {
                index: writer.processTexture(material.clearcoatRoughnessMap),
                texCoord: material.clearcoatRoughnessMap.channel
            };
            writer.applyTextureTransform(clearcoatRoughnessMapDef, material.clearcoatRoughnessMap);
            extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
        }

        if (material.clearcoatNormalMap != null) {
            var clearcoatNormalMapDef:Dynamic = {
                index: writer.processTexture(material.clearcoatNormalMap),
                texCoord: material.clearcoatNormalMap.channel
            };

            if (material.clearcoatNormalScale.x != 1) {
                clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;
            }

            writer.applyTextureTransform(clearcoatNormalMapDef, material.clearcoatNormalMap);
            extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
        }

        materialDef.extensions = materialDef.extensions || {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}