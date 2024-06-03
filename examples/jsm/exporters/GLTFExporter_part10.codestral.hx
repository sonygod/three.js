class GLTFMaterialsIorExtension {
    private var writer: Writer;
    public var name: String;

    public function new(writer: Writer) {
        this.writer = writer;
        this.name = 'KHR_materials_ior';
    }

    public function writeMaterial(material: Material, materialDef: Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.ior == 1.5) return;

        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = new Dynamic();

        extensionDef.ior = material.ior;

        if (materialDef.extensions == null) materialDef.extensions = new Dynamic();
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}