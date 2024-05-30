class GLTFMaterialsIorExtension {
	var writer: Any;
	var name: String;

	public function new(writer: Any) {
		this.writer = writer;
		this.name = 'KHR_materials_ior';
	}

	public function writeMaterial(material: Any, materialDef: Any): Void {
		if (!material.isMeshPhysicalMaterial || material.ior == 1.5) {
			return;
		}

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = { ior: material.ior };

		if (materialDef.extensions == null) {
			materialDef.extensions = { };
		}
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}