class GLTFMaterialsDispersionExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_dispersion';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.dispersion == 0) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		extensionDef.dispersion = material.dispersion;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}