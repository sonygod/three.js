import three.Colors.Color;
import three.Constants.LinearSRGBColorSpace;
import three.Constants.SRGBColorSpace;
import three.Materials.MeshPhysicalMaterial;

class GLTFMaterialsSpecularExtension {

    public var parser(get, never): GLTFParser;
    public var name: String;

    public function new(parser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_SPECULAR;
    }

    inline function get_parser(): GLTFParser {
        return this.parser;
    }

    public function getMaterialType(materialIndex: Int): Null<Class<Dynamic>> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) {
            return null;
        }
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex: Int, materialParams: Dynamic): js.lib.Promise<Array<Dynamic>> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) {
            return js.lib.Promise.resolve([]);
        }

        var pending: Array<js.lib.Promise<Dynamic>> = [];
        var extension = materialDef.extensions[this.name];

        Reflect.setProperty(materialParams, "specularIntensity", extension.specularFactor != null ? extension.specularFactor : 1.0);

        if (extension.specularTexture != null) {
            pending.push(parser.assignTexture(materialParams, "specularIntensityMap", extension.specularTexture));
        }

        var colorArray: Array<Float> = extension.specularColorFactor != null ? extension.specularColorFactor : [1, 1, 1];
        Reflect.setProperty(materialParams, "specularColor", new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace));

        if (extension.specularColorTexture != null) {
            pending.push(parser.assignTexture(materialParams, "specularColorMap", extension.specularColorTexture, SRGBColorSpace));
        }

        return js.lib.Promise.all(pending);
    }
}