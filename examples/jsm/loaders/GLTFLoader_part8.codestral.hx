import three.Color;
import three.ColorSpace;
import three.MeshPhysicalMaterial;
import GLTFLoaderParser;
import js.Promise;

class GLTFMaterialsSheenExtension {
    private var parser:GLTFLoaderParser;
    public var name:String;

    public function new(parser:GLTFLoaderParser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_SHEEN;
    }

    public function getMaterialType(materialIndex:Int) {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic) {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve(null);
        }

        var pending = new Array<Promise<Void>>();

        materialParams.sheenColor = new Color(0, 0, 0);
        materialParams.sheenRoughness = 0;
        materialParams.sheen = 1;

        var extension = materialDef.extensions[this.name];

        if (extension.sheenColorFactor != null) {
            var colorFactor = extension.sheenColorFactor;
            materialParams.sheenColor.setRGB(colorFactor[0], colorFactor[1], colorFactor[2], ColorSpace.LinearSRGB);
        }

        if (extension.sheenRoughnessFactor != null) {
            materialParams.sheenRoughness = extension.sheenRoughnessFactor;
        }

        if (extension.sheenColorTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'sheenColorMap', extension.sheenColorTexture, ColorSpace.SRGB));
        }

        if (extension.sheenRoughnessTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'sheenRoughnessMap', extension.sheenRoughnessTexture));
        }

        return Promise.all(pending);
    }
}