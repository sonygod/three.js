package three.js.examples.jm.loaders;

class GLTFMaterialsEmissiveStrengthExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = "KHR_MATERIALS_EMISSIVE_STRENGTH";
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise< Void > {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var emissiveStrength:Float = materialDef.extensions[this.name].emissiveStrength;

        if (emissiveStrength != Math.NaN) {
            materialParams.emissiveIntensity = emissiveStrength;
        }

        return Promise.resolve();
    }
}