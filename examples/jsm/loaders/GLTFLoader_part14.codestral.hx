import js.Promise;

class GLTFMaterialsAnisotropyExtension {
    private var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_ANISOTROPY;
    }

    public function getMaterialType(materialIndex:Int):Class<Material> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve(null);
        }

        var pending:Array<Promise<Void>> = [];
        var extension = materialDef.extensions[this.name];

        if (extension.anisotropyStrength != null) {
            materialParams.anisotropy = extension.anisotropyStrength;
        }

        if (extension.anisotropyRotation != null) {
            materialParams.anisotropyRotation = extension.anisotropyRotation;
        }

        if (extension.anisotropyTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'anisotropyMap', extension.anisotropyTexture));
        }

        return Promise.all(pending);
    }
}