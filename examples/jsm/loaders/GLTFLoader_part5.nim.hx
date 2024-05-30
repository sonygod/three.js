import three.js.extras.core.MeshPhysicalMaterial;
import three.js.loaders.GLTFLoader.GLTFMaterialsExtension;
import three.js.loaders.GLTFLoader.GLTFParser;
import three.js.math.Vector2;
import three.js.textures.Texture;
import three.js.utils.Promise;

class GLTFMaterialsClearcoatExtension implements GLTFMaterialsExtension {

	public var parser:GLTFParser;
	public var name:String = EXTENSIONS.KHR_MATERIALS_CLEARCOAT;

	public function new(parser:GLTFParser) {
		this.parser = parser;
	}

	public function getMaterialType(materialIndex:Int):Null<Class<MeshPhysicalMaterial>> {

		var parser:GLTFParser = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Std.is(materialDef.extensions, Dynamic) || !Std.is(materialDef.extensions[this.name], Dynamic)) return null;

		return MeshPhysicalMaterial;

	}

	public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Dynamic> {

		var parser:GLTFParser = this.parser;
		var materialDef:Dynamic = parser.json.materials[materialIndex];

		if (!Std.is(materialDef.extensions, Dynamic) || !Std.is(materialDef.extensions[this.name], Dynamic)) {

			return Promise.resolve();

		}

		var pending:Array<Promise<Dynamic>> = [];

		var extension:Dynamic = materialDef.extensions[this.name];

		if (Std.is(extension.clearcoatFactor, Float)) {

			materialParams.clearcoat = extension.clearcoatFactor;

		}

		if (Std.is(extension.clearcoatTexture, Dynamic)) {

			pending.push(parser.assignTexture(materialParams, 'clearcoatMap', cast extension.clearcoatTexture));

		}

		if (Std.is(extension.clearcoatRoughnessFactor, Float)) {

			materialParams.clearcoatRoughness = extension.clearcoatRoughnessFactor;

		}

		if (Std.is(extension.clearcoatRoughnessTexture, Dynamic)) {

			pending.push(parser.assignTexture(materialParams, 'clearcoatRoughnessMap', cast extension.clearcoatRoughnessTexture));

		}

		if (Std.is(extension.clearcoatNormalTexture, Dynamic)) {

			pending.push(parser.assignTexture(materialParams, 'clearcoatNormalMap', cast extension.clearcoatNormalTexture));

			if (Std.is(extension.clearcoatNormalTexture.scale, Float)) {

				var scale:Float = extension.clearcoatNormalTexture.scale;

				materialParams.clearcoatNormalScale = new Vector2(scale, scale);

			}

		}

		return Promise.all(pending);

	}

}