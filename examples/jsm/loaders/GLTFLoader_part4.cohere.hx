class GLTFMaterialsEmissiveStrengthExtension {
	public var parser: Parser;
	public var name: String = EXTENSIONS.KHR_MATERIALS_EMISSIVE_STRENGTH;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	public function extendMaterialParams(materialIndex: Int, materialParams: MaterialParams): VoidPromise {
		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || materialDef.extensions.__get(name) == null) {
			return VoidPromise.resolve();
		}

		var emissiveStrength = materialDef.extensions.__get(name).emissiveStrength;
		if (emissiveStrength != null) {
			materialParams.emissiveIntensity = emissiveStrength;
		}

		return VoidPromise.resolve();
	}
}