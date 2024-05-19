package three.js.examples.jsm.loaders;

import js.html.Color;
import js.Promise;

class GLTFMaterialsUnlitExtension {
    public var name:String;

    public function new() {
        this.name = EXTENSIONS.KHR_MATERIALS_UNLIT;
    }

    public function getMaterialType():Dynamic {
        return MeshBasicMaterial;
    }

    public function extendParams(materialParams:Dynamic, materialDef:Dynamic, parser:Dynamic):Promise<Dynamic> {
        var pending:Array<Promise<Dynamic>> = [];

        materialParams.color = new Color(1.0, 1.0, 1.0);
        materialParams.opacity = 1.0;

        var metallicRoughness:Dynamic = materialDef.pbrMetallicRoughness;

        if (metallicRoughness != null) {
            if (Std.isOfType(metallicRoughness.baseColorFactor, Array)) {
                var array:Array<Float> = cast metallicRoughness.baseColorFactor;
                materialParams.color.setRGB(array[0], array[1], array[2], LinearSRGBColorSpace);
                materialParams.opacity = array[3];
            }

            if (metallicRoughness.baseColorTexture != null) {
                pending.push(parser.assignTexture(materialParams, 'map', metallicRoughness.baseColorTexture, SRGBColorSpace));
            }
        }

        return Promise.all(pending);
    }
}