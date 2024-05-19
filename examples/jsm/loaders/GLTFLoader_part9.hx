package three.js.examples.jm.loaders;

import js.Promise;

class GLTFMaterialsTransmissionExtension {
    private var parser:Dynamic;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = "KHR_materials_transmission";
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || materialDef.extensions.get(name) == null) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || materialDef.extensions.get(name) == null) {
            return Promise.resolve(null);
        }

        var pending:Array<Promise<Dynamic>> = [];
        var extension:Dynamic = materialDef.extensions.get(name);

        if (extension.transmissionFactor != null) {
            materialParams.transmission = extension.transmissionFactor;
        }

        if (extension.transmissionTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'transmissionMap', extension.transmissionTexture));
        }

        return Promise.all(pending);
    }
}