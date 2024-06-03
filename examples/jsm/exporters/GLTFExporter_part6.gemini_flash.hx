class GLTFMaterialsDispersionExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_dispersion";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {

		if (!Reflect.hasField(material, "isMeshPhysicalMaterial") || !Reflect.field(material, "isMeshPhysicalMaterial") || Reflect.field(material, "dispersion") == 0) {
			return;
		}

		var extensionDef:Dynamic = {};
		extensionDef.dispersion = Reflect.field(material, "dispersion");

		if (Reflect.hasField(materialDef, "extensions")) {
			materialDef.extensions = materialDef.extensions;
		} else {
			materialDef.extensions = {};
		}

		materialDef.extensions[this.name] = extensionDef;

		if (Reflect.hasField(writer, "extensionsUsed")) {
			writer.extensionsUsed[this.name] = true;
		}
	}

}