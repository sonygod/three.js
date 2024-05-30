class GLTFMaterialsTransmissionExtension {
    var parser: GLTFParser;
    var name: String = EXTENSIONS.KHR_MATERIALS_TRANSMISSION;

    public function new(parser: GLTFParser) {
        this.parser = parser;
    }

    public function getMaterialType(materialIndex: Int): Dynamic {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) {
            return null;
        }
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex: Int, materialParams: MaterialParams): Promise<Void> {
        var parser = this.parser;
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) {
            return Promise.resolve();
        }
        var extension = materialDef.extensions[name];
        var pending: Array<Promise<Void>> = [];
        if (extension.transmissionFactor != null) {
            materialParams.transmission = extension.transmissionFactor;
        }
        if (extension.transmissionTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'transmissionMap', extension.transmissionTexture));
        }
        return Promise.all(pending);
    }
}