package three.js.examples.jsm.loaders;

import js.Promise;
import three.js.color.Color;
import three.js.materials.MeshPhysicalMaterial;

class GLTFMaterialsSheenExtension {
    private var parser:Dynamic;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = "KHR_materials_sheen";
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Void>> = [];

        materialParams.sheenColor = new Color(0, 0, 0);
        materialParams.sheenRoughness = 0;
        materialParams.sheen = 1;

        var extension = materialDef.extensions[this.name];

        if (extension.sheenColorFactor != null) {
            var colorFactor = extension.sheenColorFactor;
            materialParams.sheenColor.setRGB(colorFactor[0], colorFactor[1], colorFactor[2], LinearSRGBColorSpace);
        }

        if (extension.sheenRoughnessFactor != null) {
            materialParams.sheenRoughness = extension.sheenRoughnessFactor;
        }

        if (extension.sheenColorTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'sheenColorMap', extension.sheenColorTexture, SRGBColorSpace));
        }

        if (extension.sheenRoughnessTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'sheenRoughnessMap', extension.sheenRoughnessTexture));
        }

        return Promise.all(pending);
    }
}