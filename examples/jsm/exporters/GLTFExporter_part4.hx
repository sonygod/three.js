package three.js.examples.jsm.exporters;

class GLTFMaterialsUnlitExtension {
    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_unlit';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
        if (!material.isMeshBasicMaterial) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[this.name] = {};

        extensionsUsed[this.name] = true;

        materialDef.pbrMetallicRoughness = materialDef.pbrMetallicRoughness || {};
        materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
        materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;
    }
}