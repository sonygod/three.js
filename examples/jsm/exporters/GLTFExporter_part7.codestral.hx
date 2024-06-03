class GLTFMaterialsIridescenceExtension {
    private var writer: GLTFWriter;
    public var name: String;

    public function new(writer: GLTFWriter) {
        this.writer = writer;
        this.name = 'KHR_materials_iridescence';
    }

    public function writeMaterial(material: MeshPhysicalMaterial, materialDef: Dynamic): Void {
        if (!material.isMeshPhysicalMaterial || material.iridescence === 0) return;

        var extensionsUsed = writer.extensionsUsed;
        var extensionDef: Dynamic = {};

        extensionDef.iridescenceFactor = material.iridescence;

        if (material.iridescenceMap != null) {
            var iridescenceMapDef: Dynamic = {
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
            var iridescenceThicknessMapDef: Dynamic = {
                index: writer.processTexture(material.iridescenceThicknessMap),
                texCoord: material.iridescenceThicknessMap.channel
            };
            writer.applyTextureTransform(iridescenceThicknessMapDef, material.iridescenceThicknessMap);
            extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;
        }

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}