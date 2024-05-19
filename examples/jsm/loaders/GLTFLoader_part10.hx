package three.js.examples.jsm.loaders;

import js.Promise;
import three.Color;
import three.MeshPhysicalMaterial;

class GLTFMaterialsVolumeExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_VOLUME;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef:Dynamic = this.parser.json.materials[materialIndex];
        if (materialDef.extensions != null && materialDef.extensions[this.name] != null) {
            return MeshPhysicalMaterial;
        } else {
            return null;
        }
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef:Dynamic = this.parser.json.materials[materialIndex];
        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Dynamic>> = [];

        var extension:Dynamic = materialDef.extensions[this.name];
        materialParams.thickness = (extension.thicknessFactor != null) ? extension.thicknessFactor : 0;

        if (extension.thicknessTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'thicknessMap', extension.thicknessTexture));
        }

        materialParams.attenuationDistance = (extension.attenuationDistance != null) ? extension.attenuationDistance : Math.POSITIVE_INFINITY;

        var colorArray:Array<Float> = (extension.attenuationColor != null) ? extension.attenuationColor : [1, 1, 1];
        materialParams.attenuationColor = new Color(0, 0, 0);
        materialParams.attenuationColor.setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

        return Promise.all(pending);
    }
}