class GLTFMaterialsBumpExtension {
	public var parser: Parser;
	public var name: String = EXTENSIONS.EXT_MATERIALS_BUMP;

	public function new(parser: Parser) {
		this.parser = parser;
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
		var extension = materialDef.extensions.get(this.name);
		materialParams.bumpScale = extension.bumpFactor.default(1.0);
		if (extension.bumpTexture != null) {
			parser.assignTexture(materialParams, 'bumpMap', extension.bumpTexture);
		}
	}
}