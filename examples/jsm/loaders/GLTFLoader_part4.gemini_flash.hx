package ;

import haxe.Json;

class GLTFMaterialsEmissiveStrengthExtension {

    public var parser:Dynamic;
    public var name:String;

    public function new(parser) {

        this.parser = parser;
        this.name = "KHR_MATERIALS_EMISSIVE_STRENGTH"; // Replace with actual EXTENSIONS object access

    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {

        var materialDef:Dynamic = Json.parse(this.parser.json).materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {

            return Promise.resolve();

        }

        var emissiveStrength:Float = Reflect.field(materialDef.extensions, this.name).emissiveStrength;

        if (emissiveStrength != null) {

            materialParams.emissiveIntensity = emissiveStrength;

        }

        return Promise.resolve();

    }

}