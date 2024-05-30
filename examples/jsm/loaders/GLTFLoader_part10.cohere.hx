class GLTFMaterialsVolumeExtension {
	public var parser: Parser;
	public var name: String = EXTENSIONS.KHR_MATERIALS_VOLUME;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	public function getMaterialType(materialIndex: Int): Class<MeshPhysicalMaterial> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions.exists(name)) {
			return null;
		}
		return MeshPhysicalMaterial;
	}

	public function extendMaterialParams(materialIndex: Int, materialParams: MaterialParams): Void {
		var parser = this.parser;
		var materialDef = parser.json.materials[materialIndex];

		if (!materialDef.extensions || !materialDef.extensions.exists(name)) {
			return;
		}

		var extension = materialDef.extensions.get(name).cast(MaterialsVolumeExtension);
		materialParams.thickness = extension.thicknessFactor.default(0);

		if (extension.thicknessTexture != null) {
			materialParams.thicknessMap = parser.assignTexture(extension.thicknessTexture);
		}

		materialParams.attenuationDistance = extension.attenuationDistance.default(Infinity);
		materialParams.attenuationColor = extension.attenuationColor.map($it -> new Color.fromRGB($it[0], $it[1], $it[2], LinearSRGBColorSpace));
	}
}