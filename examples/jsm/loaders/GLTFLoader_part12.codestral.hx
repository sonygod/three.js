import js.Promise;
import three.Color;
import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;
import three.MeshPhysicalMaterial;
import three.GLTFLoader.GLTFParser;
import three.GLTFLoader.Extensions;

class GLTFMaterialsSpecularExtension {
    private var parser:GLTFParser;
    private var name:String;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = Extensions.KHR_MATERIALS_SPECULAR;
    }

    public function getMaterialType(materialIndex:Int):Class<MeshPhysicalMaterial> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions.get(this.name) == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions.get(this.name) == null) {
            return Promise.resolve(null);
        }

        var pending = new Array<Promise<Void>>();
        var extension = materialDef.extensions.get(this.name);

        if (Reflect.hasField(extension, "specularFactor")) {
            materialParams.specularIntensity = extension.specularFactor;
        } else {
            materialParams.specularIntensity = 1.0;
        }

        if (Reflect.hasField(extension, "specularTexture")) {
            pending.push(this.parser.assignTexture(materialParams, "specularIntensityMap", extension.specularTexture));
        }

        var colorArray:Array<Float> = Reflect.hasField(extension, "specularColorFactor") ? extension.specularColorFactor : [1.0, 1.0, 1.0];
        materialParams.specularColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace.get_instance());

        if (Reflect.hasField(extension, "specularColorTexture")) {
            pending.push(this.parser.assignTexture(materialParams, "specularColorMap", extension.specularColorTexture, SRGBColorSpace.get_instance()));
        }

        return Promise.all(pending);
    }
}