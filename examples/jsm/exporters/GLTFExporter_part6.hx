package three.examples.jm.exporters;

class GLTFMaterialsDispersionExtension {
    private var writer:Dynamic;
    private var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_dispersion';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.dispersion == 0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        extensionDef.dispersion = material.dispersion;

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}