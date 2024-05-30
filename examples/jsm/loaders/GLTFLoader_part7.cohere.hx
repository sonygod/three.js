class GLTFMaterialsIridescenceExtension {
	public var parser: Parser;
	public var name: String;

	public function new(parser: Parser) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_IRIDESCENCE;
	}

	public function getMaterialType(materialIndex: Int): Class<MeshPhysicalMaterial> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions.exists(this.name)) {
			return null;
		}
		return MeshPhysicalMaterial;
	}

	public function extendMaterialParams(materialIndex: Int, materialParams: MaterialParams): Void {
		var parser = this.parser;
		var materialDef = parser.json.materials[materialIndex];

		if (!materialDef.extensions || !materialDef.extensions.exists(this.name)) {
			return;
		}

		var extension = materialDef.extensions.get(this.name).cast<GLTFMaterialsIridescenceExtensionData>();
		var pending: Array<Future<Void>> = [];

		if (extension.iridescenceFactor != null) {
			materialParams.iridescence = extension.iridescenceFactor;
		}

		if (extension.iridescenceTexture != null) {
			pending.push(parser.assignTexture(materialParams, 'iridescenceMap', extension.iridescenceTexture));
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
			pending.push(parser.assignTexture(materialParams, 'iridescenceThicknessMap', extension.iridescenceThicknessTexture));
		}

		await Promise.all(pending);
	}
}