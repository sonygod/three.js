class GLTFMaterialsDispersionExtension {

    var writer:Writer;
    var name:String;

    public function new(writer:Writer) {

        this.writer = writer;
        this.name = 'KHR_materials_dispersion';

    }

    public function writeMaterial(material:Material, materialDef:Dynamic) {

        if (!Type.enumOf(material, MaterialType.MeshPhysicalMaterial) || material.dispersion == 0) return;

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = {};

        extensionDef.dispersion = material.dispersion;

        materialDef.extensions = materialDef.extensions ?? {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;

    }

}