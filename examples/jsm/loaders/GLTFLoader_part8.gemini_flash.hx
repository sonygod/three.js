import three.MeshPhysicalMaterial;
import three.textures.Texture;
import three.math.Color;

class GLTFMaterialsSheenExtension {

	public var parser(get, never):GLTFParser;
	public var name(default, null):String;

	public function new(parser:GLTFParser) {

		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_SHEEN;

	}

	inline function get_parser():GLTFParser {
		return this.parser;
	}

	public function getMaterialType(materialIndex:Int):Class<Dynamic> {

		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
			return null;
		}

		return MeshPhysicalMaterial;

	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Array<Texture>> {

		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
			return Promise.resolve([]);
		}

		var pending:Array<Promise<Texture>> = [];

		materialParams.sheenColor = new Color(0, 0, 0);
		materialParams.sheenRoughness = 0;
		materialParams.sheen = 1;

		var extension = Reflect.field(materialDef.extensions, this.name);

		if (Reflect.hasField(extension, "sheenColorFactor")) {

			var colorFactor = extension.sheenColorFactor;
			materialParams.sheenColor.setRGB(colorFactor[0], colorFactor[1], colorFactor[2]);

		}

		if (Reflect.hasField(extension, "sheenRoughnessFactor")) {

			materialParams.sheenRoughness = extension.sheenRoughnessFactor;

		}

		if (Reflect.hasField(extension, "sheenColorTexture")) {

			pending.push(parser.assignTexture(materialParams, 'sheenColorMap', extension.sheenColorTexture, SRGBColorSpace));

		}

		if (Reflect.hasField(extension, "sheenRoughnessTexture")) {

			pending.push(parser.assignTexture(materialParams, 'sheenRoughnessMap', extension.sheenRoughnessTexture));

		}

		return Promise.all(pending);

	}

}