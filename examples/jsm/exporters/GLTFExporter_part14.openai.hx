package three.js.examples.jsm.exporters;

class GLTFMaterialsEmissiveStrengthExtension {
    private var writer:Dynamic;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_emissive_strength';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshStandardMaterial || material.emissiveIntensity == 1.0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};
        extensionDef.emissiveStrength = material.emissiveIntensity;

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[name] = extensionDef;

        extensionsUsed[name] = true;
    }
}