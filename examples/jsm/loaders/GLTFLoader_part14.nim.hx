class GLTFMaterialsAnisotropyExtension {

	var parser:Parser;
	var name:String;

	public function new(parser:Parser) {

		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_ANISOTROPY;

	}

	public function getMaterialType(materialIndex:Int):Null<Class<MeshPhysicalMaterial>> {

		var parser:Parser = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Std.is(materialDef.extensions, Dynamic) || !Std.is(materialDef.extensions[this.name], Dynamic)) return null;

		return MeshPhysicalMaterial;

	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {

		var parser:Parser = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Std.is(materialDef.extensions, Dynamic) || !Std.is(materialDef.extensions[this.name], Dynamic)) {

			return Promise.resolve();

		}

		var pending:Array<Promise<Dynamic>> = [];

		var extension:Dynamic = materialDef.extensions[this.name];

		if (Std.is(extension.anisotropyStrength, Float)) {

			materialParams.anisotropy = extension.anisotropyStrength;

		}

		if (Std.is(extension.anisotropyRotation, Float)) {

			materialParams.anisotropyRotation = extension.anisotropyRotation;

		}

		if (Std.is(extension.anisotropyTexture, Dynamic)) {

			pending.push(parser.assignTexture(materialParams, 'anisotropyMap', extension.anisotropyTexture));

		}

		return Promise.all(pending);

	}

}