class GLTFMaterialsSheenExtension {

	var parser:GLTFParser;
	var name:String;

	public function new(parser:GLTFParser) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_SHEEN;
	}

	public function getMaterialType(materialIndex:Int):Class<Material> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions[name]) return null;
		return MeshPhysicalMaterial;
	}

	public function extendMaterialParams(materialIndex:Int, materialParams:MaterialParams):Promise<Dynamic> {
		var materialDef = parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions[name]) {
			return Promise.resolve();
		}
		var pending = [];
		materialParams.sheenColor = new Color(0, 0, 0);
		materialParams.sheenRoughness = 0;
		materialParams.sheen = 1;
		var extension = materialDef.extensions[name];
		if (extension.sheenColorFactor !== undefined) {
			var colorFactor = extension.sheenColorFactor;
			materialParams.sheenColor.setRGB(colorFactor[0], colorFactor[1], colorFactor[2], LinearSRGBColorSpace);
		}
		if (extension.sheenRoughnessFactor !== undefined) {
			materialParams.sheenRoughness = extension.sheenRoughnessFactor;
		}
		if (extension.sheenColorTexture !== undefined) {
			pending.push(parser.assignTexture(materialParams, 'sheenColorMap', extension.sheenColorTexture, SRGBColorSpace));
		}
		if (extension.sheenRoughnessTexture !== undefined) {
			pending.push(parser.assignTexture(materialParams, 'sheenRoughnessMap', extension.sheenRoughnessTexture));
		}
		return Promise.all(pending);
	}
}