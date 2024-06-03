import js.Promise;

class GLTFMaterialsEmissiveStrengthExtension {

    var parser:Parser;
    var name:String;

    public function new(parser:Parser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_EMISSIVE_STRENGTH;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve(null);
        }

        var emissiveStrength = materialDef.extensions[this.name].emissiveStrength;

        if (emissiveStrength != null) {
            materialParams.emissiveIntensity = emissiveStrength;
        }

        return Promise.resolve(null);
    }
}