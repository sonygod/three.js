package three.js.examples.jsm.loaders;

import js.html.Promise;

class GLTFMaterialsDispersionExtension {
    public var parser:Dynamic;
    public var name:String = EXTENSIONS.KHR_MATERIALS_DISPERSION;

    public function new(parser:Dynamic) {
        this.parser = parser;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var materialDef:Array<Dynamic> = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || materialDef.extensions[name] == null) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef:Array<Dynamic> = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || materialDef.extensions[name] == null) {
            return Promise.resolve();
        }
        var extension:Dynamic = materialDef.extensions[name];
        materialParams.dispersion = extension.dispersion != null ? extension.dispersion : 0;
        return Promise.resolve();
    }
}