class GLTFMaterialsSheenExtension {
	var parser: Parser;
	var name: String = EXTENSIONS.KHR_MATERIALS_SHEEN;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	function getMaterialType(materialIndex: Int): Class<MeshPhysicalMaterial> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions.exists(name)) {
			return null;
		}
		return MeshPhysicalMaterial;
	}

	async function extendMaterialParams(materialIndex: Int, materialParams: MaterialParams) {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions.exists(name)) {
			return;
		}

		materialParams.sheenColor = new Color.fromRGB(0, 0, 0, LinearSRGBColorSpace);
		materialParams.sheenRoughness = 0;
		materialParams.sheen = 1;

		var extension = materialDef.extensions.get(name).cast<GLTFMaterialsSheenExtensionData>();

		if (extension.sheenColorFactor.isNotEmpty()) {
			var colorFactor = extension.sheenColorFactor;
			materialParams.sheenColor.setRGB(colorFactor[0], colorFactor[1], colorFactor[2], LinearSRGBColorSpace);
		}

		if (extension.sheenRoughnessFactor.exists()) {
			materialParams.sheenRoughness = extension.sheenRoughnessFactor;
		}

		if (extension.sheenColorTexture.exists()) {
			var texture = await parser.assignTexture(materialParams, 'sheenColorMap', extension.sheenColorTexture, SRGBColorSpace);
		}

		if (extension.sheenRoughnessTexture.exists()) {
			var texture = await parser.assignTexture(materialParams, 'sheenRoughnessMap', extension.sheenRoughnessTexture);
		}
	}
}