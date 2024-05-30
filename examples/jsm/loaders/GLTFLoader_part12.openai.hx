package three.js_examples_jm_loaders;

import three.js_loaders.GLTFCategory;

class GLTFMaterialsSpecularExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_SPECULAR;
    }

    public function getMaterialType(materialIndex:Int):Dynamic {
        var materialDef:Array<Dynamic> = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[this.name]) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef:Array<Dynamic> = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[this.name]) return Promise.resolve();

        var pending:Array<Promise<Dynamic>> = [];
        var extension:Dynamic = materialDef.extensions[this.name];

        materialParams.specularIntensity = if (extension.specularFactor != null) extension.specularFactor else 1.0;

        if (extension.specularTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'specularIntensityMap', extension.specularTexture));
        }

        var colorArray:Array<Float> = if (extension.specularColorFactor != null) extension.specularColorFactor else [1, 1, 1];
        materialParams.specularColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

        if (extension.specularColorTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'specularColorMap', extension.specularColorTexture, SRGBColorSpace));
        }

        return Promise.all(pending);
    }
}