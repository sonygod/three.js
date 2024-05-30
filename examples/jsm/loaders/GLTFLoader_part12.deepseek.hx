class GLTFMaterialsSpecularExtension {

	var parser:GLTFLoader_part12;
	var name:String;

	public function new(parser:GLTFLoader_part12) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_SPECULAR;
	}

	public function getMaterialType(materialIndex:Int):Class<Dynamic> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions[name]) return null;
		return MeshPhysicalMaterial;
	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions[name]) {
			return Promise.resolve();
		}
		var pending = [];
		var extension = materialDef.extensions[name];
		materialParams.specularIntensity = extension.specularFactor !== undefined ? extension.specularFactor : 1.0;
		if (extension.specularTexture !== undefined) {
			pending.push(parser.assignTexture(materialParams, 'specularIntensityMap', extension.specularTexture));
		}
		var colorArray = extension.specularColorFactor || [1, 1, 1];
		materialParams.specularColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);
		if (extension.specularColorTexture !== undefined) {
			pending.push(parser.assignTexture(materialParams, 'specularColorMap', extension.specularColorTexture, SRGBColorSpace));
		}
		return Promise.all(pending);
	}
}