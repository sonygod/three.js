package ;

import three.MeshPhysicalMaterial;

class GLTFMaterialsDispersionExtension {

	public var parser : GLTFParser;
	public var name : String;

	public function new(parser) {

		this.parser = parser;
		this.name = EXTENSIONS.KHR_MATERIALS_DISPERSION;

	}

	public function getMaterialType(materialIndex : Int) : Class<Dynamic> {

		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) return null;

		return MeshPhysicalMaterial;

	}

	public function extendMaterialParams(materialIndex : Int, materialParams : Dynamic) : js.lib.Promise<Void> {

		var materialDef = parser.json.materials[materialIndex];

		if (materialDef.extensions == null || !materialDef.extensions.exists(this.name)) {

			return js.lib.Promise.resolve();

		}

		var extension = materialDef.extensions[this.name];

		materialParams.dispersion = extension.dispersion != null ? extension.dispersion : 0;

		return js.lib.Promise.resolve();

	}

}