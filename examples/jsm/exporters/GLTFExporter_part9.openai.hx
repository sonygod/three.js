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

        var extensionsUsed = writer.extensionsUsed;
        var extensionDef = {};

        extensionDef.thicknessFactor = material.thickness;

        if (material.thicknessMap != null) {
            var thicknessMapDef = {
                index: writer.processTexture(material.thicknessMap),
                texCoord: material.thicknessMap.channel
            };
            writer.applyTextureTransform(thicknessMapDef, material.thicknessMap);
            extensionDef.thicknessTexture = thicknessMapDef;
        }

        extensionDef.attenuationDistance = material.attenuationDistance;
        extensionDef.attenuationColor = material.attenuationColor.toArray();

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[name] = extensionDef;

        extensionsUsed[name] = true;
    }
}