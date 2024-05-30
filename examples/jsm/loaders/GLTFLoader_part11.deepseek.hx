class GLTFMaterialsIorExtension {

    var parser:GLTFParser;
    var name:String;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IOR;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
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
        materialParams.ior = extension.ior !== undefined ? extension.ior : 1.5;
        return Promise.resolve();
    }

}