import js.Promise;
import js.Array;
import three.EXTENSIONS;
import three.MeshPhysicalMaterial;
import three.gltf.GLTFParser;

class GLTFMaterialsBumpExtension {

    public var parser:GLTFParser;
    public var name:String = EXTENSIONS.EXT_MATERIALS_BUMP;

    public function new(parser:GLTFParser) {
        this.parser = parser;
    }

    public function getMaterialType(materialIndex:Int):Class<MeshPhysicalMaterial> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return null;
        }

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Array<Void>> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null) {
            return Promise.resolve(null);
        }

        var pending:Array<Promise<Void>> = [];

        var extension = materialDef.extensions[this.name];

        materialParams.bumpScale = extension.bumpFactor != null ? extension.bumpFactor : 1.0;

        if (extension.bumpTexture != null) {
            pending.push(this.parser.assignTexture(materialParams, 'bumpMap', extension.bumpTexture));
        }

        return Promise.all(pending);
    }
}