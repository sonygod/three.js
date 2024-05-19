package three.js.examples.jvm.loaders;

import js.Promise;
import js.html.Color;
import js.html.ColorSpace;

class GLTFMaterialsSpecularExtension {
    private var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = 'KHR_materials_specular';
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var parser:Dynamic = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Dynamic>> = [];

        var extension:Dynamic = materialDef.extensions[this.name];

        materialParams.specularIntensity = extension.specularFactor != null ? extension.specularFactor : 1.0;

        if (extension.specularTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'specularIntensityMap', extension.specularTexture));
        }

        var colorArray:Array<Float> = extension.specularColorFactor != null ? extension.specularColorFactor : [1, 1, 1];
        materialParams.specularColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

        if (extension.specularColorTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'specularColorMap', extension.specularColorTexture, SRGBColorSpace));
        }

        return Promise.all(pending);
    }
}