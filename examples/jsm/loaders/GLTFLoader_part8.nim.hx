class GLTFMaterialsSheenExtension {

	var parser:GLTFParser;
	var name:String;

	public function new(parser:GLTFParser) {

		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_SHEEN;

	}

	public function getMaterialType(materialIndex:Int):Null<Class<MeshPhysicalMaterial>> {

		var parser:GLTFParser = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Reflect.hasField(materialDef, 'extensions') || !Reflect.hasField(materialDef.extensions, this.name)) return null;

		return MeshPhysicalMaterial;

	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {

		var parser:GLTFParser = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Reflect.hasField(materialDef, 'extensions') || !Reflect.hasField(materialDef.extensions, this.name)) {

			return Promise.resolve(null);

		}

		var pending:Array<Promise<Void>> = [];

		materialParams.sheenColor = new Color(0, 0, 0);
		materialParams.sheenRoughness = 0;
		materialParams.sheen = 1;

		var extension:Dynamic = materialDef.extensions[this.name];

		if (Reflect.hasField(extension, 'sheenColorFactor')) {

			var colorFactor:Array<Float> = extension.sheenColorFactor;
			materialParams.sheenColor.setRGB(colorFactor[0], colorFactor[1], colorFactor[2], LinearSRGBColorSpace);

		}

		if (Reflect.hasField(extension, 'sheenRoughnessFactor')) {

			materialParams.sheenRoughness = extension.sheenRoughnessFactor;

		}

		if (Reflect.hasField(extension, 'sheenColorTexture')) {

			pending.push(parser.assignTexture(materialParams, 'sheenColorMap', extension.sheenColorTexture, SRGBColorSpace));

		}

		if (Reflect.hasField(extension, 'sheenRoughnessTexture')) {

			pending.push(parser.assignTexture(materialParams, 'sheenRoughnessMap', extension.sheenRoughnessTexture));

		}

		return Promise.all(pending);

	}

}