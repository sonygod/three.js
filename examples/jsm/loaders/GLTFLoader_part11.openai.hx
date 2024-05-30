package three.js.examples.jsm.loaders;

class GLTFMaterialsIorExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IOR;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (materialDef.extensions != null && materialDef.extensions.exists(this.name)) {
            return MeshPhysicalMaterial;
        }
        return null;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) {
            return Promise.resolve();
        }
        var extension:Dynamic = materialDef.extensions[this.name];
        materialParams.ior = extension.ior != null ? extension.ior : 1.5;
        return Promise.resolve();
    }
}