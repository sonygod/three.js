class GLTFMaterialsClearcoatExtension {

    var parser:Dynamic;
    var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) return null;
        return MeshPhysicalMaterial;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
        var materialDef = parser.json.materials[materialIndex];
        if (!materialDef.extensions || !materialDef.extensions[name]) {
            return Promise.resolve();
        }

        var pending = [];
        var extension = materialDef.extensions[name];

        if (extension.clearcoatFactor !== undefined) {
            materialParams.clearcoat = extension.clearcoatFactor;
        }

        if (extension.clearcoatTexture !== undefined) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatMap', extension.clearcoatTexture));
        }

        if (extension.clearcoatRoughnessFactor !== undefined) {
            materialParams.clearcoatRoughness = extension.clearcoatRoughnessFactor;
        }

        if (extension.clearcoatRoughnessTexture !== undefined) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatRoughnessMap', extension.clearcoatRoughnessTexture));
        }

        if (extension.clearcoatNormalTexture !== undefined) {
            pending.push(parser.assignTexture(materialParams, 'clearcoatNormalMap', extension.clearcoatNormalTexture));
            if (extension.clearcoatNormalTexture.scale !== undefined) {
                var scale = extension.clearcoatNormalTexture.scale;
                materialParams.clearcoatNormalScale = new Vector2(scale, scale);
            }
        }

        return Promise.all(pending);
    }
}