import js.Promise;
class GLTFMaterialsIridescenceExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IRIDESCENCE;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null)
            return null;

        return js.Boot.getClass(MeshPhysicalMaterial);
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef = this.parser.json.materials[materialIndex];

        if (materialDef.extensions == null || materialDef.extensions[this.name] == null)
            return Promise.resolve(null);

        var extension = materialDef.extensions[this.name];
        var promises:Array<Promise<Void>> = [];

        if (extension.iridescenceFactor != null) {
            materialParams.iridescence = extension.iridescenceFactor;
        }

        if (extension.iridescenceTexture != null) {
            promises.push(this.parser.assignTexture(materialParams, 'iridescenceMap', extension.iridescenceTexture));
        }

        if (extension.iridescenceIor != null) {
            materialParams.iridescenceIOR = extension.iridescenceIor;
        }

        if (materialParams.iridescenceThicknessRange == null) {
            materialParams.iridescenceThicknessRange = [100, 400];
        }

        if (extension.iridescenceThicknessMinimum != null) {
            materialParams.iridescenceThicknessRange[0] = extension.iridescenceThicknessMinimum;
        }

        if (extension.iridescenceThicknessMaximum != null) {
            materialParams.iridescenceThicknessRange[1] = extension.iridescenceThicknessMaximum;
        }

        if (extension.iridescenceThicknessTexture != null) {
            promises.push(this.parser.assignTexture(materialParams, 'iridescenceThicknessMap', extension.iridescenceThicknessTexture));
        }

        return Promise.all(promises).then(() -> Promise.resolve(null));
    }
}