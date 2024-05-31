import three.Vector2;
import three.MeshPhysicalMaterial;

class GLTFMaterialsClearcoatExtension {

	public var parser(get, never):GLTFParser;
	public var name:String;

	public function new(parser:GLTFParser) {

		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;

	}

	inline function get_parser():GLTFParser {
		return this.parser;
	}

	public function getMaterialType(materialIndex:Int):Class<Dynamic> {

		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) return null;

		return MeshPhysicalMaterial;

	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Void> {

		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {

			return Promise.resolve();

		}

		var pending:Array<Promise<Void>> = [];

		var extension = Reflect.field(materialDef.extensions, this.name);

		if (Reflect.hasField(extension, 'clearcoatFactor')) {

			materialParams.clearcoat = extension.clearcoatFactor;

		}

		if (Reflect.hasField(extension, 'clearcoatTexture')) {

			pending.push(parser.assignTexture(materialParams, 'clearcoatMap', extension.clearcoatTexture));

		}

		if (Reflect.hasField(extension, 'clearcoatRoughnessFactor')) {

			materialParams.clearcoatRoughness = extension.clearcoatRoughnessFactor;

		}

		if (Reflect.hasField(extension, 'clearcoatRoughnessTexture')) {

			pending.push(parser.assignTexture(materialParams, 'clearcoatRoughnessMap', extension.clearcoatRoughnessTexture));

		}

		if (Reflect.hasField(extension, 'clearcoatNormalTexture')) {

			pending.push(parser.assignTexture(materialParams, 'clearcoatNormalMap', extension.clearcoatNormalTexture));

			if (Reflect.hasField(extension.clearcoatNormalTexture, 'scale')) {

				var scale = extension.clearcoatNormalTexture.scale;

				materialParams.clearcoatNormalScale = new Vector2(scale, scale);

			}

		}

		return Promise.all(pending);

	}

}