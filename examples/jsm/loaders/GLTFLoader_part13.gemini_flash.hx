import three.MeshPhysicalMaterial;
import three.materials.Material;

class GLTFMaterialsBumpExtension {

    public var name : String;
    var parser : Dynamic;

    public function new(parser) {

        this.parser = parser;
        this.name = "EXT_materials_bump"; // Replace with actual constant if available

    }

    public function getMaterialType(materialIndex : Int) : Class<Material> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return null;
        }

        return MeshPhysicalMaterial;

    }

    public function extendMaterialParams(materialIndex : Int, materialParams : Dynamic) : js.lib.Promise<Void> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return js.lib.Promise.resolve();
        }

        var pending : Array<js.lib.Promise<Void>> = [];

        var extension = Reflect.field(materialDef.extensions, this.name);

        materialParams.bumpScale = (extension.bumpFactor != null) ? extension.bumpFactor : 1.0;

        if (extension.bumpTexture != null) {

            pending.push(parser.assignTexture(materialParams, 'bumpMap', extension.bumpTexture));

        }

        return js.lib.Promise.all(pending);

    }

}