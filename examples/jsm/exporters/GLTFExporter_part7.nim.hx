class GLTFMaterialsIridescenceExtension {

    var writer:Writer;
    var name:String;

    public function new(writer:Writer) {

        this.writer = writer;
        this.name = 'KHR_materials_iridescence';

    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {

        if (!Type.getClass(material).toString() == "MeshPhysicalMaterial" || material.iridescence == 0) return;

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = {};

        extensionDef.iridescenceFactor = material.iridescence;

        if (material.iridescenceMap != null) {

            var iridescenceMapDef = {
                index: writer.processTexture(material.iridescenceMap),
                texCoord: material.iridescenceMap.channel
            };
            writer.applyTextureTransform(iridescenceMapDef, material.iridescenceMap);
            extensionDef.iridescenceTexture = iridescenceMapDef;

        }

        extensionDef.iridescenceIor = material.iridescenceIOR;
        extensionDef.iridescenceThicknessMinimum = material.iridescenceThicknessRange[0];
        extensionDef.iridescenceThicknessMaximum = material.iridescenceThicknessRange[1];

        if (material.iridescenceThicknessMap != null) {

            var iridescenceThicknessMapDef = {
                index: writer.processTexture(material.iridescenceThicknessMap),
                texCoord: material.iridescenceThicknessMap.channel
            };
            writer.applyTextureTransform(iridescenceThicknessMapDef, material.iridescenceThicknessMap);
            extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;

        }

        materialDef.extensions = materialDef.extensions ?? {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;

    }

}