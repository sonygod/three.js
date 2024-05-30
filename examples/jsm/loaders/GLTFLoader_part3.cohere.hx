class GLTFMaterialsUnlitExtension {
	public var name:String = EXTENSIONS.KHR_MATERIALS_UNLIT;

	public function new() { }

	public function getMaterialType():Dynamic {
		return MeshBasicMaterial;
	}

	public function extendParams(materialParams:Dynamic, materialDef:Dynamic, parser:Dynamic):Promise<Void> {
		var pending = [];

		materialParams.color = new Color(1.0, 1.0, 1.0);
		materialParams.opacity = 1.0;

		var metallicRoughness = materialDef.pbrMetallicRoughness;
		if (metallicRoughness != null) {
			if (metallicRoughness.baseColorFactor != null) {
				var array = metallicRoughness.baseColorFactor;
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