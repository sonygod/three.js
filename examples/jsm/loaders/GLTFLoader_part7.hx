package three.examples.jsm.loaders;

import js.Promise;
import three.MeshPhysicalMaterial;

class GLTFMaterialsIridescenceExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IRIDESCENCE;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (!materialDef.extensions || !materialDef.extensions[this.name]) return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (!materialDef.extensions || !materialDef.extensions[this.name]) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Dynamic>> = [];

        var extension:Dynamic = materialDef.extensions[this.name];

        if (extension.iridescenceFactor != null) {
            materialParams.iridescence = extension.iridescenceFactor;
        }

        if (extension.iridescenceTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'iridescenceMap', extension.iridescenceTexture));
        }

        if (extension.iridescenceIor != null) {
            materialParams.iridescenceIOR = extension.iridescenceIor;
        }

        if (materialParams.iridescenceThicknessRange == null) {
            materialParams.iridescenceThicknessRange = [100, 400];
        }

        if (extension.iridescenceThicknessMinimum != null) {
            materialParams.iridescenceThicknessRange[0] = extension.iridescenceThicknessMinimum;
        }

        if (extension.iridescenceThicknessMaximum != null) {
            materialParams.iridescenceThicknessRange[1] = extension.iridescenceThicknessMaximum;
        }

        if (extension.iridescenceThicknessTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'iridescenceThicknessMap', extension.iridescenceThicknessTexture));
        }

        return Promise.all(pending);
    }
}