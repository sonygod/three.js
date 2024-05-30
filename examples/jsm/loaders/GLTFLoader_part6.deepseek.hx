class GLTFMaterialsDispersionExtension {

    var parser:Dynamic;
    var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_DISPERSION;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var materialDef = this.parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[this.name]) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef = this.parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[this.name]) {
            return Promise.resolve();
        }
        var extension = materialDef.extensions[this.name];
        materialParams.dispersion = extension.dispersion !== undefined ? extension.dispersion : 0;
        return Promise.resolve();
    }
}