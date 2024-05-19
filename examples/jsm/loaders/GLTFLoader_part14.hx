package three.js.examples.jm.loaders;

import js.Promise;

class GLTFMaterialsAnisotropyExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_ANISOTROPY;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
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
            pending.push(parser.assignTexture(materialParams, 'anisotropyMap', extension.anisotropyTexture));
        }

        return Promise.all(pending);
    }
}