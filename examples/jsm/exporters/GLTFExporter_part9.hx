package three.js.examples.jsm.exporters;

class GLTFMaterialsVolumeExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_volume';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.transmission == 0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        extensionDef.thicknessFactor = material.thickness;

        if (material.thicknessMap != null) {
            var thicknessMapDef:Dynamic = {
                index: writer.processTexture(material.thicknessMap),
                texCoord: material.thicknessMap.channel
            };
            writer.applyTextureTransform(thicknessMapDef, material.thicknessMap);
            extensionDef.thicknessTexture = thicknessMapDef;
        }

        extensionDef.attenuationDistance = material.attenuationDistance;
        extensionDef.attenuationColor = material.attenuationColor.toArray();

        materialDef.extensions = materialDef.extensions || {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}