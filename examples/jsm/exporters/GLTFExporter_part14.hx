package three.js.examples.jsm.exporters;

class GLTFMaterialsEmissiveStrengthExtension {
    public var writer:Dynamic;
    public var name:String;

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
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}