import haxe.Json;
import js.lib.Promise;

class GLTFMaterialsAnisotropyExtension {

    public var parser(get, never):Dynamic;
    public var name(get, never):String;

    function new(parser) {
        this.parser = parser;
        this.name = "KHR_materials_anisotropy"; // Assuming EXTENSIONS is a constant map
    }

    inline function get parser() return this.parser;
    inline function get name() return this.name;

    public function getMaterialType(materialIndex:Int):Null<Class<Dynamic>> {
        var materialDef:Dynamic = Json.parse(this.parser.json).materials[materialIndex];
        if (materialDef.extensions == null || Reflect.hasField(materialDef.extensions, this.name) == false) {
            return null;
        }
        return MeshPhysicalMaterial; // Assuming MeshPhysicalMaterial is accessible in this scope
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Array<Dynamic>> {
        var materialDef:Dynamic = Json.parse(this.parser.json).materials[materialIndex];

        if (materialDef.extensions == null || Reflect.hasField(materialDef.extensions, this.name) == false) {
            return Promise.resolve([]);
        }

        var pending:Array<Promise<Dynamic>> = [];
        var extension:Dynamic = materialDef.extensions[this.name];

        if (extension.anisotropyStrength != null) {
            materialParams.anisotropy = extension.anisotropyStrength;
        }

        if (extension.anisotropyRotation != null) {
            materialParams.anisotropyRotation = extension.anisotropyRotation;
        }

        if (extension.anisotropyTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, "anisotropyMap", extension.anisotropyTexture));
        }

        return Promise.all(pending);
    }
}