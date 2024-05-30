class GLTFMaterialsIorExtension {
	public var parser: Parser;
	public var name: String = EXTENSIONS.KHR_MATERIALS_IOR;

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
		var extension = materialDef.extensions.get(name).cast<GLTFMaterialsIorExtensionData>();
		materialParams.ior = extension.ior.default(1.5);
	}
}