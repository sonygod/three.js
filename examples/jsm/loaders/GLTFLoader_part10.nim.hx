class GLTFMaterialsVolumeExtension {

	var parser:GLTFParser;
	var name:String;

	public function new(parser:GLTFParser) {

		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_VOLUME;

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

			return new Promise(function(resolve) {
				resolve();
			});

		}

		var pending:Array<Promise<Void>> = [];

		var extension:Dynamic = materialDef.extensions[this.name];

		materialParams.thickness = extension.thicknessFactor != null ? extension.thicknessFactor : 0;

		if (extension.thicknessTexture != null) {

			pending.push(parser.assignTexture(materialParams, 'thicknessMap', extension.thicknessTexture));

		}

		materialParams.attenuationDistance = extension.attenuationDistance != null ? extension.attenuationDistance : Infinity;

		var colorArray:Array<Float> = extension.attenuationColor != null ? extension.attenuationColor : [1, 1, 1];
		materialParams.attenuationColor = new Color().setRGB(colorArray[0], colorArray[1], colorArray[2], LinearSRGBColorSpace);

		return Promise.all(pending);

	}

}