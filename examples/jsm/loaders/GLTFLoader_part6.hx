package three.js.examples.jsm.loaders;

class GLTFMaterialsDispersionExtension {
    private var parser:Dynamic;
    private var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_DISPERSION;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var extension:Dynamic = materialDef.extensions[this.name];
        materialParams.dispersion = extension.dispersion != null ? extension.dispersion : 0;

        return Promise.resolve();
    }
}