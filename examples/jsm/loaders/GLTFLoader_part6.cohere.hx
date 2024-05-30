class GLTFMaterialsDispersionExtension {
	var parser: Parser;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	public function getMaterialType(materialIndex: Int): String {
		var materialDef = parser.json.materials[materialIndex];

		if (!materialDef.extensions || !materialDef.extensions.exists(EXTENSIONS.KHR_MATERIALS_DISPERSION)) {
			return null;
		}

		return 'MeshPhysicalMaterial';
	}

	public function extendMaterialParams(materialIndex: Int, materialParams: MaterialParams): Void {
		var parser = this.parser;
		var materialDef = parser.json.materials[materialIndex];

		if (!materialDef.extensions || !materialDef.extensions.exists(EXTENSIONS.KHR_MATERIALS_DISPERSION)) {
			return;
		}

		var extension = materialDef.extensions.get(EXTENSIONS.KHR_MATERIALS_DISPERSION).cast<F32>;

		materialParams.dispersion = extension.dispersion.default(0);
	}
}