class GLTFMaterialsEmissiveStrengthExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_emissive_strength";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
		if (!Reflect.hasField(material, "isMeshStandardMaterial") || material.emissiveIntensity == 1.0) return;

		var extensionDef:Dynamic = {};
		extensionDef.emissiveStrength = material.emissiveIntensity;

		if (!Reflect.hasField(materialDef, "extensions")) {
			materialDef.extensions = {};
		}

		materialDef.extensions[this.name] = extensionDef;
		this.writer.extensionsUsed[this.name] = true;
	}

}