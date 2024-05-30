class GLTFMaterialsAnisotropyExtension {

    var parser:Dynamic;
    var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_ANISOTROPY;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) {
            return Promise.resolve();
        }

        var pending = [];
        var extension = materialDef.extensions[name];

        if (extension.anisotropyStrength !== undefined) {
            materialParams.anisotropy = extension.anisotropyStrength;
        }

        if (extension.anisotropyRotation !== undefined) {
            materialParams.anisotropyRotation = extension.anisotropyRotation;
        }

        if (extension.anisotropyTexture !== undefined) {
            pending.push(parser.assignTexture(materialParams, 'anisotropyMap', extension.anisotropyTexture));
        }

        return Promise.all(pending);
    }
}