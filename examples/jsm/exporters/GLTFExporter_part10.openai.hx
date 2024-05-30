package three.js.examples.jsm.exporters;

class GLTFMaterialsIorExtension {

    public var writer:Dynamic;
    public var name:String = 'KHR_materials_ior';

    public function new(writer:Dynamic) {
        this.writer = writer;
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
        if (!material.isMeshPhysicalMaterial || material.ior == 1.5) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        extensionDef.ior = material.ior;

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[name] = extensionDef;

        extensionsUsed[name] = true;
    }
}