import three.MeshPhysicalMaterial;
import three.Color;
import three.LinearSRGBColorSpace;
import js.lib.Promise;

class GLTFMaterialsVolumeExtension {

    public var parser : Dynamic;
    public var name : String;

    public function new(parser) {
        this.parser = parser;
        this.name = "KHR_MATERIALS_VOLUME"; // Replace EXTENSIONS.KHR_MATERIALS_VOLUME with actual value
    }

    public function getMaterialType(materialIndex : Int) : Class<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return null;
        }
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex : Int, materialParams : Dynamic) : Promise<Void> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return Promise.resolve();
        }

        var pending : Array<Promise<Void>> = [];
        var extension = materialDef.extensions[this.name];

        materialParams.thickness = (extension.thicknessFactor != null) ? extension.thicknessFactor : 0;

        if (extension.thicknessTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'thicknessMap', extension.thicknessTexture));
        }

        materialParams.attenuationDistance = extension.attenuationDistance != null ? extension.attenuationDistance : Math.POSITIVE_INFINITY;

        var colorArray = extension.attenuationColor != null ? extension.attenuationColor : [1, 1, 1];
        materialParams.attenuationColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

        return Promise.all(pending);
    }

}