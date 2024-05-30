class GLTFMaterialsTransmissionExtension {

	var parser:GLTFLoader_part9;
	var name:String;

	public function new(parser:GLTFLoader_part9) {
		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_TRANSMISSION;
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
		if (extension.transmissionFactor !== undefined) {
			materialParams.transmission = extension.transmissionFactor;
		}
		if (extension.transmissionTexture !== undefined) {
			pending.push(parser.assignTexture(materialParams, 'transmissionMap', extension.transmissionTexture));
		}
		return Promise.all(pending);
	}
}