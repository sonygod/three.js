import three.Color;
import three.ColorSpace;
import three.MeshBasicMaterial;
import three.GLTFLoaderParser;

class GLTFMaterialsUnlitExtension {

    public var name:String;

    public function new() {
        this.name = EXTENSIONS.KHR_MATERIALS_UNLIT;
    }

    public function getMaterialType():Class<MeshBasicMaterial> {
        return MeshBasicMaterial;
    }

    public function extendParams(materialParams:any, materialDef:Dynamic, parser:GLTFLoaderParser):Promise<Array<any>> {
        var pending:Array<Promise<any>> = [];

        materialParams.color = new Color(1.0, 1.0, 1.0);
        materialParams.opacity = 1.0;

        var metallicRoughness = materialDef.pbrMetallicRoughness;

        if (metallicRoughness != null) {
            if (Std.is(metallicRoughness.baseColorFactor, Array<Float>)) {
                var array:Array<Float> = metallicRoughness.baseColorFactor;

                materialParams.color.setRGB(array[0], array[1], array[2], ColorSpace.LinearSRGBColorSpace);
                materialParams.opacity = array[3];
            }

            if (metallicRoughness.baseColorTexture != null) {
                pending.push(parser.assignTexture(materialParams, 'map', metallicRoughness.baseColorTexture, ColorSpace.SRGBColorSpace));
            }
        }

        return Promise.all(pending);
    }
}