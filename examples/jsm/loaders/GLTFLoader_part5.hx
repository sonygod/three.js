Here is the converted Haxe code:
```
package three.js.examples.jsm.loaders;

import js.lib.Promise;
import three.js.loaders.GLTFLoader;

class GLTFMaterialsClearcoatExtension {
    public var parser:GLTFLoader;
    public var name:String;

    public function new(parser:GLTFLoader) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;
    }

    public function getMaterialType(materialIndex:Int):MeshPhysicalMaterial {
        var parser:GLTFLoader = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (!materialDef.extensions || !materialDef.extensions[this.name]) return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var parser:GLTFLoader = this.parser;
        var materialDef:Dynamic = parser.json.materials[materialIndex];

        if (!materialDef.extensions || !materialDef.extensions[this.name]) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Void>> = [];

        var extension:Dynamic = materialDef.extensions[this.name];

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
                var scale:Float = extension.clearcoatNormalTexture.scale;
                materialParams.clearcoatNormalScale = new Vector2(scale, scale);
            }
        }

        return Promise.all(pending);
    }
}
```
Note that I've used the `Dynamic` type for the `materialDef` and `extension` variables, as they are not explicitly typed in the original JavaScript code. I've also used the `Void` type for the return type of the `extendMaterialParams` method, as it returns a `Promise` that resolves to no value.