class GLTFMaterialsBumpExtension {
    private var writer:Writer;
    private var name:String = 'EXT_materials_bump';

    public function new(writer:Writer) {
        this.writer = writer;
    }

    public function writeMaterial(material:MeshStandardMaterial, materialDef:Dynamic) {
        if (material.isMeshStandardMaterial == null || (material.bumpScale == 1 && material.bumpMap == null)) return;

        var extensionsUsed = writer.extensionsUsed;
        var extensionDef = Dynamic();

        if (material.bumpMap != null) {
            var bumpMapDef = {
                index: writer.processTexture(material.bumpMap),
                texCoord: material.bumpMap.channel
            };
            writer.applyTextureTransform(bumpMapDef, material.bumpMap);
            extensionDef.bumpTexture = bumpMapDef;
        }

        extensionDef.bumpFactor = material.bumpScale;

        if (materialDef.extensions == null) materialDef.extensions = Dynamic();
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}