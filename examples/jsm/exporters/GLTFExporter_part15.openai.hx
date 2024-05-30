package three.js.examples.jm.exporters;

class GLTFMaterialsBumpExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'EXT_materials_bump';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshStandardMaterial || (material.bumpScale == 1 && material.bumpMap == null)) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        if (material.bumpMap != null) {
            var bumpMapDef:Dynamic = {
                index: writer.processTexture(material.bumpMap),
                texCoord: material.bumpMap.channel
            };
            writer.applyTextureTransform(bumpMapDef, material.bumpMap);
            extensionDef.bumpTexture = bumpMapDef;
        }

        extensionDef.bumpFactor = material.bumpScale;

        materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}