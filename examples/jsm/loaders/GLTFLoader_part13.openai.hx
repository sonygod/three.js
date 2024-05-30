package three.js.examples.jsm.loaders;

class GLTFMaterialsBumpExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_MATERIALS_BUMP;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[this.name]) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[this.name]) {
            return Promise.resolve();
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