class GLTFMaterialsEmissiveStrengthExtension {
    private var writer: GLTFWriter;
    public var name: String = 'KHR_materials_emissive_strength';

    public function new(writer: GLTFWriter) {
        this.writer = writer;
    }

    public function writeMaterial(material: MeshStandardMaterial, materialDef: Dynamic) {
        if(!material.isMeshStandardMaterial || material.emissiveIntensity == 1.0) return;

        var extensionDef: Dynamic = {};
        extensionDef.emissiveStrength = material.emissiveIntensity;

        if(materialDef.extensions == null) materialDef.extensions = {};

        materialDef.extensions[this.name] = extensionDef;
        this.writer.extensionsUsed[this.name] = true;
    }
}