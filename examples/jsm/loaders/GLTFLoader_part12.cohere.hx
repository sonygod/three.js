class GLTFMaterialsSpecularExtension {
	var parser: GLTFParser;
	var name: String;

	public function new(parser: GLTFParser) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_SPECULAR;
	}

	public function getMaterialType(materialIndex: Int): Class<MeshMaterial> {
		var materialDef = parser.json.materials[materialIndex];

		if (!materialDef.extensions || !materialDef.extensions.exists(this.name)) {
			return null;
		}

		return MeshPhysicalMaterial;
	}

	public function extendMaterialParams(materialIndex: Int, materialParams: MaterialParameters): Void {
		var parser = this.parser;
		var materialDef = parser.json.materials[materialIndex];

		if (!materialDef.extensions || !materialDef.extensions.exists(this.name)) {
			return;
		}

		var extension = materialDef.extensions.get(this.name).cast(GLTFMaterialsSpecularExtensionProperties);
		materialParams.specularIntensity = extension.specularFactor.default(1.0);

		if (extension.specularTexture.exists) {
			parser.assignTexture(materialParams, 'specularIntensityMap', extension.specularTexture);
		}

		var colorArray = extension.specularColorFactor.default([1, 1, 1]);
		materialParams.specularColor = Color.fromRGBArray(colorArray, LinearSRGBColorSpace);

		if (extension.specularColorTexture.exists) {
			parser.assignTexture(materialParams, 'specularColorMap', extension.specularColorTexture, SRGBColorSpace);
		}
	}
}

typedef GLTFMaterialsSpecularExtensionProperties = {
	var specularFactor: Float;
	var specularTexture: Int;
	var specularColorFactor: Array<Float>;
	var specularColorTexture: Int;
}