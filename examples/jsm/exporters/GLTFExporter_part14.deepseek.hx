class GLTFMaterialsEmissiveStrengthExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_emissive_strength';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshStandardMaterial || material.emissiveIntensity === 1.0) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		extensionDef.emissiveStrength = material.emissiveIntensity;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}