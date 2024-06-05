package three.js.examples.jsm.exporters;

class GLTFMaterialsTransmissionExtension {
    
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_transmission';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.transmission == 0) return;

        var extensionDef:Dynamic = {};

        extensionDef.transmissionFactor = material.transmission;

        if (material.transmissionMap != null) {
            var transmissionMapDef:Dynamic = {
                index: writer.processTexture(material.transmissionMap),
                texCoord: material.transmissionMap.channel
            };
            writer.applyTextureTransform(transmissionMapDef, material.transmissionMap);
            extensionDef.transmissionTexture = transmissionMapDef;
        }

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[this.name] = extensionDef;

        writer.extensionsUsed[this.name] = true;
    }
}