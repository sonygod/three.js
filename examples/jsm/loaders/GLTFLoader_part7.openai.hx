package three.js.examples.jsm.loaders;

import js.three.mesh.MeshPhysicalMaterial;
import js.three.parser.GLTFParser;

class GLTFMaterialsIridescenceExtension {
    public var parser:GLTFParser;
    public var name:String;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IRIDESCENCE;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions != null && materialDef.extensions[this.name] != null) {
            return MeshPhysicalMaterial;
        } else {
            return null;
        }
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void->Void> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Void->Void>> = [];

        var extension = materialDef.extensions[this.name];
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