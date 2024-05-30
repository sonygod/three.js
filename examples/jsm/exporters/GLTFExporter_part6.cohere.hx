class GLTFMaterialsDispersionExtension {
	var writer: Dynamic;
	var name: String = 'KHR_materials_dispersion';

	public function new(writer: Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material: Dynamic, materialDef: Dynamic) {
		if (!material.isMeshPhysicalMaterial || material.dispersion == 0) {
			return;
		}

		var extensionsUsed = writer.extensionsUsed;
		var extensionDef = {
			'dispersion': material.dispersion
		};

		if (materialDef.extensions == null) {
			materialDef.extensions = { };
		}
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}