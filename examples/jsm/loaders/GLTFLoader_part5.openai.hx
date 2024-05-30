package three.js.examples.jsm.loaders;

import js.Promise;
import three.js.loaders.GLTFLoader;

class GLTFMaterialsClearcoatExtension {
    public var parser:GLTFLoader;
    public var name:String;

    public function new(parser:GLTFLoader) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;
    }

    public function getMaterialType(materialIndex:Int):Null<Class<Dynamic>> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions != null && materialDef.extensions.exists(this.name)) {
            return MeshPhysicalMaterial;
        } else {
            return null;
        }
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Void>> = [];
        var extension = materialDef.extensions[this.name];

        if (extension.clearcoatFactor != null) {
            materialParams.clearcoat = extension.clearcoatFactor;
        }

        if (extension.clearcoatTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatMap', extension.clearcoatTexture));
        }

        if (extension.clearcoatRoughnessFactor != null) {
            materialParams.clearcoatRoughness = extension.clearcoatRoughnessFactor;
        }

        if (extension.clearcoatRoughnessTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatRoughnessMap', extension.clearcoatRoughnessTexture));
        }

        if (extension.clearcoatNormalTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatNormalMap', extension.clearcoatNormalTexture));

            if (extension.clearcoatNormalTexture.scale != null) {
                var scale = extension.clearcoatNormalTexture.scale;
                materialParams.clearcoatNormalScale = new Vector2(scale, scale);
            }
        }

        return Promise.all(pending);
    }
}