class GLTFMaterialsClearcoatExtension {
	var parser: GLTFParser;
	var name: String = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;

	public function new(parser: GLTFParser) {
		this.parser = parser;
	}

	function getMaterialType(materialIndex: Int): Class<MeshPhysicalMaterial> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions.exists(name)) {
			return null;
		}
		return MeshPhysicalMaterial;
	}

	async function extendMaterialParams(materialIndex: Int, materialParams: MaterialParameters) {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions.exists(name)) {
			return;
		}
		var extension = materialDef.extensions.get(name).cast(GLTFMaterialsClearcoatExtension);
		if (extension.clearcoatFactor != null) {
			materialParams.clearcoat = extension.clearcoatFactor;
		}
		if (extension.clearcoatTexture != null) {
			materialParams.clearcoatMap = await parser.assignTexture(materialParams, 'clearcoatMap', extension.clearcoatTexture);
		}
		if (extension.clearcoatRoughnessFactor != null) {
			materialParams.clearcoatRoughness = extension.clearcoatRoughnessFactor;
		}
		if (extension.clearcoatRoughnessTexture != null) {
			materialParams.clearcoatRoughnessMap = await parser.assignTexture(materialParams, 'clearcoatRoughnessMap', extension.clearcoatRoughnessTexture);
		}
		if (extension.clearcoatNormalTexture != null) {
			materialParams.clearcoatNormalMap = await parser.assignTexture(materialParams, 'clearcoatNormalMap', extension.clearcoatNormalTexture);
		
			if (extension.clearcoatNormalTexture.scale != null) {
				materialParams.clearcoatNormalScale = extension.clearcoatNormalTexture.scale;
			}
		}
	}
}