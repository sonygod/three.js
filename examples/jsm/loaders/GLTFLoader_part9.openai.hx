package three.js.examples.jvm.loaders;

import js.html.Promise;

class GLTFMaterialsTransmissionExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_TRANSMISSION;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var parser = this.parser;
        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var parser = this.parser;
        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Void>> = [];

        var extension = materialDef.extensions[this.name];

        if (extension.transmissionFactor != null) {
            materialParams.transmission = extension.transmissionFactor;
        }

        if (extension.transmissionTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'transmissionMap', extension.transmissionTexture));
        }

        return Promise.all(pending);
    }
}