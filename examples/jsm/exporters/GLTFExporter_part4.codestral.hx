import js.Browser.document;

class GLTFMaterialsUnlitExtension {
    var writer: dynamic;
    var name: String;

    public function new(writer: dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_unlit';
    }

    public function writeMaterial(material: dynamic, materialDef: dynamic): Void {
        if (!Std.is(material.isMeshBasicMaterial, Bool)) {
            return;
        }

        var extensionsUsed = this.writer.extensionsUsed;

        if (materialDef.extensions == null) {
            materialDef.extensions = js.Boot.newObject();
        }

        materialDef.extensions[this.name] = js.Boot.newObject();
        extensionsUsed[this.name] = true;

        materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
        materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;
    }
}