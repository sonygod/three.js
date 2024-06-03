class GLTFMaterialsClearcoatExtension {

    private var writer: GLTFWriter;
    public var name: String;

    public function new(writer: GLTFWriter) {
        this.writer = writer;
        this.name = 'KHR_materials_clearcoat';
    }

    public function writeMaterial(material: MeshPhysicalMaterial, materialDef: Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.clearcoat == 0) return;

        var extensionsUsed = this.writer.extensionsUsed;
        var extensionDef = new Dynamic();

        extensionDef.clearcoatFactor = material.clearcoat;

        if (material.clearcoatMap != null) {
            var clearcoatMapDef = {
                index: this.writer.processTexture(material.clearcoatMap),
                texCoord: material.clearcoatMap.channel
            };
            this.writer.applyTextureTransform(clearcoatMapDef, material.clearcoatMap);
            extensionDef.clearcoatTexture = clearcoatMapDef;
        }

        extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;

        if (material.clearcoatRoughnessMap != null) {
            var clearcoatRoughnessMapDef = {
                index: this.writer.processTexture(material.clearcoatRoughnessMap),
                texCoord: material.clearcoatRoughnessMap.channel
            };
            this.writer.applyTextureTransform(clearcoatRoughnessMapDef, material.clearcoatRoughnessMap);
            extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
        }

        if (material.clearcoatNormalMap != null) {
            var clearcoatNormalMapDef = {
                index: this.writer.processTexture(material.clearcoatNormalMap),
                texCoord: material.clearcoatNormalMap.channel
            };

            if (material.clearcoatNormalScale.x != 1) clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;

            this.writer.applyTextureTransform(clearcoatNormalMapDef, material.clearcoatNormalMap);
            extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
        }

        if (materialDef.extensions == null) materialDef.extensions = new Dynamic();
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}