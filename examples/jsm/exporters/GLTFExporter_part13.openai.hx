package three.js.examples.jsm.exporters;

class GLTFMaterialsAnisotropyExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_anisotropy';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.anisotropy == 0.0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        if (material.anisotropyMap != null) {
            var anisotropyMapDef:Dynamic = { index: writer.processTexture(material.anisotropyMap) };
            writer.applyTextureTransform(anisotropyMapDef, material.anisotropyMap);
            extensionDef.anisotropyTexture = anisotropyMapDef;
        }

        extensionDef.anisotropyStrength = material.anisotropy;
        extensionDef.anisotropyRotation = material.anisotropyRotation;

        materialDef.extensions = materialDef.extensions || {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}