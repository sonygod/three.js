class GLTFMaterialsAnisotropyExtension {

    private var writer: GLTFWriter;
    private var name: String;

    public function new(writer: GLTFWriter) {
        this.writer = writer;
        this.name = 'KHR_materials_anisotropy';
    }

    public function writeMaterial(material: THREE.Material, materialDef: Dynamic) {
        if (!Std.is(material, THREE.MeshPhysicalMaterial) || material.anisotropy == 0.0) return;

        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = new Dynamic();

        if (material.anisotropyMap != null) {
            var anisotropyMapDef = { index: writer.processTexture(material.anisotropyMap) };
            writer.applyTextureTransform(anisotropyMapDef, material.anisotropyMap);
            extensionDef.anisotropyTexture = anisotropyMapDef;
        }

        extensionDef.anisotropyStrength = material.anisotropy;
        extensionDef.anisotropyRotation = material.anisotropyRotation;

        if (materialDef.extensions == null) materialDef.extensions = new Dynamic();
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}