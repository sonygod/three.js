import js.html.ArrayBuffer;

class GLTFMaterialsVolumeExtension {

    private var writer: GLTFWriter;
    public var name: String;

    public function new(writer: GLTFWriter) {
        this.writer = writer;
        this.name = 'KHR_materials_volume';
    }

    public function writeMaterial(material: MeshPhysicalMaterial, materialDef: Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.transmission === 0) return;

        var extensionsUsed = this.writer.extensionsUsed;

        var extensionDef: Dynamic = {};

        extensionDef.thicknessFactor = material.thickness;

        if (material.thicknessMap != null) {
            var thicknessMapDef: Dynamic = {
                index: this.writer.processTexture(material.thicknessMap),
                texCoord: material.thicknessMap.channel
            };
            this.writer.applyTextureTransform(thicknessMapDef, material.thicknessMap);
            extensionDef.thicknessTexture = thicknessMapDef;
        }

        extensionDef.attenuationDistance = material.attenuationDistance;
        extensionDef.attenuationColor = material.attenuationColor.toArray();

        if (materialDef.extensions == null) {
            materialDef.extensions = {};
        }
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}