class GLTFMaterialsVolumeExtension {

	var parser:GLTFLoader_part10;
	var name:String;

	public function new(parser:GLTFLoader_part10) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_VOLUME;
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
		materialParams.thickness = extension.thicknessFactor !== undefined ? extension.thicknessFactor : 0;
		if (extension.thicknessTexture !== undefined) {
			pending.push(parser.assignTexture(materialParams, 'thicknessMap', extension.thicknessTexture));
		}
		materialParams.attenuationDistance = extension.attenuationDistance || Infinity;
		var colorArray = extension.attenuationColor || [1, 1, 1];
		materialParams.attenuationColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);
		return Promise.all(pending);
	}
}