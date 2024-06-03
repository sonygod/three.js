import js.Promise;
import js.Array;
import js.html.Vector2;

class GLTFMaterialsClearcoatExtension {

    private var parser:Dynamic;
    private var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];

        if (js.Boot.field(materialDef, 'extensions') == null || js.Boot.field(materialDef.extensions, name) == null) return null;

        return js.Boot.getClass<Dynamic>(js.Boot.getClass<Dynamic>(MeshPhysicalMaterial));
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = parser.json.materials[materialIndex];

        if (js.Boot.field(materialDef, 'extensions') == null || js.Boot.field(materialDef.extensions, name) == null) {
            return new Promise<Void>((resolve, reject) => resolve());
        }

        var pending = new Array<Promise<Void>>();

        var extension = materialDef.extensions[name];

        if (js.Boot.field(extension, 'clearcoatFactor') != null) {
            materialParams.clearcoat = extension.clearcoatFactor;
        }

        if (js.Boot.field(extension, 'clearcoatTexture') != null) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatMap', extension.clearcoatTexture));
        }

        if (js.Boot.field(extension, 'clearcoatRoughnessFactor') != null) {
            materialParams.clearcoatRoughness = extension.clearcoatRoughnessFactor;
        }

        if (js.Boot.field(extension, 'clearcoatRoughnessTexture') != null) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatRoughnessMap', extension.clearcoatRoughnessTexture));
        }

        if (js.Boot.field(extension, 'clearcoatNormalTexture') != null) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatNormalMap', extension.clearcoatNormalTexture));

            if (js.Boot.field(extension.clearcoatNormalTexture, 'scale') != null) {
                var scale = extension.clearcoatNormalTexture.scale;

                materialParams.clearcoatNormalScale = new Vector2(scale, scale);
            }
        }

        return Promise.all(pending).then((results) => {});
    }

}