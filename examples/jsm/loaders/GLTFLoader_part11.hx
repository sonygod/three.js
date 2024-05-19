package three.js.examples.jsm.loaders;

class GLTFMaterialsIorExtension {
    private var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IOR;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var extension:Dynamic = materialDef.extensions[this.name];

        materialParams.ior = (extension.ior != null) ? extension.ior : 1.5;

        return Promise.resolve();
    }
}