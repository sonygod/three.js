package three.js.examples.javascript.loaders;

import js.Promise;

class GLTFMaterialsBumpExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_MATERIALS_BUMP;
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
            return Promise.resolve(null);
        }

        var pending:Array<Promise<Dynamic>> = [];

        var extension:Dynamic = materialDef.extensions[this.name];

        materialParams.bumpScale = extension.bumpFactor != null ? extension.bumpFactor : 1.0;

        if (extension.bumpTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'bumpMap', extension.bumpTexture));
        }

        return Promise.all(pending);
    }
}