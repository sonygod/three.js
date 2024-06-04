class GLTFMaterialsDispersionExtension {

	public var writer:Dynamic;
	public var name:String = 'KHR_materials_dispersion';

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {

		if (!Reflect.hasField(material, "isMeshPhysicalMaterial") || Reflect.field(material, "dispersion") == 0) {
			return;
		}

		var extensionDef:Dynamic = {};

		extensionDef.dispersion = Reflect.field(material, "dispersion");

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		Reflect.field(writer, "extensionsUsed")[this.name] = true;

	}

}