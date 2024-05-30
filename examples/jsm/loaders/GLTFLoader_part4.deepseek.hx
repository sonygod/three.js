class GLTFMaterialsEmissiveStrengthExtension {

    var parser:Dynamic;
    var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_EMISSIVE_STRENGTH;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (!materialDef.extensions || !materialDef.extensions[this.name]) {
            return Promise.resolve();
        }

        var emissiveStrength = materialDef.extensions[this.name].emissiveStrength;

        if (emissiveStrength !== undefined) {
            materialParams.emissiveIntensity = emissiveStrength;
        }

        return Promise.resolve();
    }
}