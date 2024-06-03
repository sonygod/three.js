import js.Promise;
import js.Array;
import three.Color;
import three.LinearSRGBColorSpace;
import three.MeshPhysicalMaterial;

class GLTFMaterialsVolumeExtension {

    var parser: dynamic;
    var name: String;

    public function new(parser: dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_VOLUME;
    }

    public function getMaterialType(materialIndex: Int): Class<MeshPhysicalMaterial> {
        var materialDef = parser.json.materials[materialIndex];

        if (!hasExtension(materialDef))
            return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex: Int, materialParams: Dynamic): Promise<Void> {
        var materialDef = parser.json.materials[materialIndex];

        if (!hasExtension(materialDef))
            return Promise.resolve();

        var pending: Array<Promise<Void>> = [];

        var extension = materialDef.extensions[this.name];

        materialParams.thickness = extension.thicknessFactor !== null ? extension.thicknessFactor : 0;

        if (extension.thicknessTexture !== null) {
            pending.push(parser.assignTexture(materialParams, 'thicknessMap', extension.thicknessTexture));
        }

        materialParams.attenuationDistance = extension.attenuationDistance !== null ? extension.attenuationDistance : Float.POSITIVE_INFINITY;

        var colorArray = extension.attenuationColor !== null ? extension.attenuationColor : [1, 1, 1];
        materialParams.attenuationColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

        return Promise.all(pending);
    }

    private function hasExtension(materialDef: Dynamic): Bool {
        return materialDef.extensions !== null && materialDef.extensions[this.name] !== null;
    }
}