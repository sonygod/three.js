class GLTFMaterialsBumpExtension {

	var parser:GLTFLoader_part13;
	var name:String;

	public function new(parser:GLTFLoader_part13) {
		this.parser = parser;
		this.name = EXTENSIONS.EXT_MATERIALS_BUMP;
	}

	public function getMaterialType(materialIndex:Int):Class<Dynamic> {
		var materialDef = this.parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions[this.name]) return null;
		return MeshPhysicalMaterial;
	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
		var materialDef = this.parser.json.materials[materialIndex];
		if (!materialDef.extensions || !materialDef.extensions[this.name]) {
			return Promise.resolve();
		}
		var pending = [];
		var extension = materialDef.extensions[this.name];
		materialParams.bumpScale = extension.bumpFactor !== undefined ? extension.bumpFactor : 1.0;
		if (extension.bumpTexture !== undefined) {
			pending.push(this.parser.assignTexture(materialParams, 'bumpMap', extension.bumpTexture));
		}
		return Promise.all(pending);
	}
}