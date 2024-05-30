class GLTFMaterialsEmissiveStrengthExtension {
	var writer: Dynamic;
	var name: String = 'KHR_materials_emissive_strength';

	public function new(writer: Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material: Dynamic, materialDef: Dynamic) {
		if (!material.isMeshStandardMaterial || material.emissiveIntensity == 1.0) {
			return;
		}

		var extensionsUsed = writer.extensionsUsed;
		var extensionDef = {
			emissiveStrength: material.emissiveIntensity
		};

		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}