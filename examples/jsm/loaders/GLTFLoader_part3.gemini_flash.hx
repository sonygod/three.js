import three.Materials.MeshBasicMaterial;
import three.Textures.Texture;
import three.Math.Color;
import js.lib.Promise;

class GLTFMaterialsUnlitExtension {

	public var name: String;

	public function new() {
		this.name = EXTENSIONS.KHR_MATERIALS_UNLIT;
	}

	public function getMaterialType(): Class<Dynamic> {
		return MeshBasicMaterial;
	}

	public function extendParams(materialParams: Dynamic, materialDef: Dynamic, parser: Dynamic): Promise<Array<Texture>> {
		var pending: Array<Promise<Texture>> = [];

		materialParams.color = new Color(1.0, 1.0, 1.0);
		materialParams.opacity = 1.0;

		var metallicRoughness = Reflect.field(materialDef, "pbrMetallicRoughness");

		if (metallicRoughness != null) {
			var baseColorFactor: Dynamic = Reflect.field(metallicRoughness, "baseColorFactor");
			if (Std.isOfType(baseColorFactor, Array)) {
				materialParams.color.setRGB(baseColorFactor[0], baseColorFactor[1], baseColorFactor[2]);
				materialParams.opacity = baseColorFactor[3];
			}

			var baseColorTexture = Reflect.field(metallicRoughness, "baseColorTexture");
			if (baseColorTexture != null) {
				pending.push(parser.assignTexture(materialParams, "map", baseColorTexture, SRGBColorSpace));
			}
		}

		return Promise.all(pending);
	}
}