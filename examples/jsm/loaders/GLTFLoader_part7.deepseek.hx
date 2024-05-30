class GLTFMaterialsIridescenceExtension {

    var parser:GLTFParser;
    var name:String;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IRIDESCENCE;
    }

    public function getMaterialType(materialIndex:Int):Class<Material> {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:MaterialParams):Promise<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) {
            return Promise.resolve();
        }

        var pending = [];
        var extension = materialDef.extensions[name];

        if (extension.iridescenceFactor !== undefined) {
            materialParams.iridescence = extension.iridescenceFactor;
        }

        if (extension.iridescenceTexture !== undefined) {
            pending.push(parser.assignTexture(materialParams, 'iridescenceMap', extension.iridescenceTexture));
        }

        if (extension.iridescenceIor !== undefined) {
            materialParams.iridescenceIOR = extension.iridescenceIor;
        }

        if (materialParams.iridescenceThicknessRange === undefined) {
            materialParams.iridescenceThicknessRange = [100, 400];
        }

        if (extension.iridescenceThicknessMinimum !== undefined) {
            materialParams.iridescenceThicknessRange[0] = extension.iridescenceThicknessMinimum;
        }

        if (extension.iridescenceThicknessMaximum !== undefined) {
            materialParams.iridescenceThicknessRange[1] = extension.iridescenceThicknessMaximum;
        }

        if (extension.iridescenceThicknessTexture !== undefined) {
            pending.push(parser.assignTexture(materialParams, 'iridescenceThicknessMap', extension.iridescenceThicknessTexture));
        }

        return Promise.all(pending);
    }
}