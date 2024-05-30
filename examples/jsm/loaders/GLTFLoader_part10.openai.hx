package three.js.examples.jSm.loaders;

class GLTFMaterialsVolumeExtension {
    private var parser:Dynamic;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = "KHR_materials_volume";
    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (materialDef.extensions != null && materialDef.extensions.exists(this.name)) {
            return MeshPhysicalMaterial;
        }
        return null;
    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
        var materialDef:Dynamic = parser.json.materials[materialIndex];
        if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) {
            return Promise.resolve();
        }

        var pending:Array<Promise<Void>> = [];
        var extension:Dynamic = materialDef.extensions[this.name];

        materialParams.thickness = if (extension.thicknessFactor != null) extension.thicknessFactor else 0;

        if (extension.thicknessTexture != null) {
            pending.push(parser.assignTexture(materialParams, 'thicknessMap', extension.thicknessTexture));
        }

        materialParams.attenuationDistance = if (extension.attenuationDistance != null) extension.attenuationDistance else Math.POSITIVE_INFINITY;

        var colorArray:Array<Float> = if (extension.attenuationColor != null) extension.attenuationColor else [1, 1, 1];
        materialParams.attenuationColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

        return Promise.all(pending);
    }
}