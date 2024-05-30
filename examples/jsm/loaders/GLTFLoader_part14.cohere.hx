class GLTFMaterialsAnisotropyExtension {
	public var parser: Parser;
	public var name: String = EXTENSIONS.KHR_MATERIALS_ANISOTROPY;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	public function getMaterialType(materialIndex: Int): MeshPhysicalMaterial {
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

		var extension = materialDef.extensions.get(this.name).cast<FGLTF_KHR_materials_anisotropyExtension>();

		if (extension.anisotropyStrength != null) {
			materialParams.anisotropy = extension.anisotropyStrength;
		}

		if (extension.anisotropyRotation != null) {
			materialParams.anisotropyRotation = extension.anisotropyRotation;
		}

		if (extension.anisotropyTexture != null) {
			var pending = parser.assignTexture(materialParams, 'anisotropyMap', extension.anisotropyTexture);
			if (pending != null) {
				pending();
			}
		}
	}
}