class GLTFMaterialsEmissiveStrengthExtension {

	var parser;
	var name = EXTENSIONS.KHR_MATERIALS_EMISSIVE_STRENGTH;

	public function new(parser:Parser) {
		this.parser = parser;
	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {
		var parser = this.parser;
		var materialDef = parser.json.materials[materialIndex];

		if (!Reflect.hasField(materialDef, 'extensions') || !Reflect.hasField(materialDef.extensions, this.name)) {
			return Promise.resolve();
		}

		var emissiveStrength = materialDef.extensions[this.name].emissiveStrength;

		if (emissiveStrength != null) {
			materialParams.emissiveIntensity = emissiveStrength;
		}

		return Promise.resolve();
	}
}