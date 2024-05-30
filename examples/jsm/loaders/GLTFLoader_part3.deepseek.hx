class GLTFMaterialsUnlitExtension {

    public var name:String;

    public function new() {

        this.name = EXTENSIONS.KHR_MATERIALS_UNLIT;

    }

    public function getMaterialType():Class<MeshBasicMaterial> {

        return MeshBasicMaterial;

    }

    public function extendParams(materialParams:Dynamic, materialDef:Dynamic, parser:Dynamic):Promise<Dynamic> {

        var pending:Array<Dynamic> = [];

        materialParams.color = new Color(1.0, 1.0, 1.0);
        materialParams.opacity = 1.0;

        var metallicRoughness = materialDef.pbrMetallicRoughness;

        if (metallicRoughness != null) {

            if (Std.is(metallicRoughness.baseColorFactor, Array)) {

                var array = cast(metallicRoughness.baseColorFactor, Array<Float>);

                materialParams.color.setRGB(array[0], array[1], array[2], LinearSRGBColorSpace);
                materialParams.opacity = array[3];

            }

            if (metallicRoughness.baseColorTexture != null) {

                pending.push(parser.assignTexture(materialParams, 'map', metallicRoughness.baseColorTexture, SRGBColorSpace));

            }

        }

        return Promise.all(pending);

    }

}