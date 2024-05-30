class GLTFMaterialsBumpExtension {

	var parser:GLTFLoader;
	var name:String = EXTENSIONS.EXT_MATERIALS_BUMP;

	public function new(parser:GLTFLoader) {
		this.parser = parser;
	}

	function getMaterialType(materialIndex:Int):Null<Class<MeshPhysicalMaterial>> {
		var parser:GLTFLoader = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Std.is(materialDef.extensions, Dynamic) || !Std.is(materialDef.extensions[this.name], Dynamic)) return null;

		return MeshPhysicalMaterial;
	}

	function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {
		var parser:GLTFLoader = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Std.is(materialDef.extensions, Dynamic) || !Std.is(materialDef.extensions[this.name], Dynamic)) {
			return Promise.resolve();
		}

		var pending:Array<Promise<Dynamic>> = [];

		var extension:Dynamic = materialDef.extensions[this.name];

		materialParams.bumpScale = Std.is(extension.bumpFactor, Float) ? extension.bumpFactor : 1.0;

		if (Std.is(extension.bumpTexture, Dynamic)) {
			pending.push(parser.assignTexture(materialParams, 'bumpMap', extension.bumpTexture));
		}

		return Promise.all(pending);
	}

}