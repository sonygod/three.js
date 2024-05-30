package three.js.examples.jsm.loaders;

class GLTFMaterialsEmissiveStrengthExtension {
    
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = 'KHR_materials_emissive_strength';
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (!materialDef.extensions || !materialDef.extensions[this.name]) {
            return Promise.resolve();
        }

        var emissiveStrength:Float = materialDef.extensions[this.name].emissiveStrength;

        if (emissiveStrength != null) {
            materialParams.emissiveIntensity = emissiveStrength;
        }

        return Promise.resolve();
    }
}