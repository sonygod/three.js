import js.Promise;

class GLTFMaterialsIorExtension {
    private var parser: Parser;
    public var name: String;

    public function new(parser: Parser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IOR;
    }

    public function getMaterialType(materialIndex: Int): Class<dynamic> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions.get(this.name) == null) return null;

        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex: Int, materialParams: Dynamic): Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions.get(this.name) == null) {
            return Promise.resolve(null);
        }

        var extension = materialDef.extensions.get(this.name);

        if (extension.hasOwnProperty('ior')) {
            materialParams.ior = extension.ior;
        } else {
            materialParams.ior = 1.5;
        }

        return Promise.resolve(null);
    }
}