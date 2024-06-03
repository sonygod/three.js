import js.html.WebGL;

class GLTFMaterialsDispersionExtension {

    private var writer: GLTFWriter;
    public var name: String;

    public function new(writer: GLTFWriter) {
        this.writer = writer;
        this.name = 'KHR_materials_dispersion';
    }

    public function writeMaterial(material: WebGL.Material, materialDef: Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.dispersion == 0) return;

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        extensionDef.dispersion = material.dispersion;

        if (materialDef.extensions == null) materialDef.extensions = {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }

}