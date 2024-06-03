import three.loaders.GLTFLoader;
import three.materials.Material;
import three.materials.MeshPhysicalMaterial;

class GLTFMaterialsDispersionExtension {
    private var parser:GLTFLoader;
    public var name:String;

    public function new(parser:GLTFLoader) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_DISPERSION;
    }

    public function getMaterialType(materialIndex:Int):Class<Material> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions.get(this.name) == null) return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions.get(this.name) == null) {
            return Promise.resolve(null);
        }

        var extension = materialDef.extensions.get(this.name);

        materialParams.dispersion = extension.dispersion != null ? extension.dispersion : 0;

        return Promise.resolve(null);
    }
}