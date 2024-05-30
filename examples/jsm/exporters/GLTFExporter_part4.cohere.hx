class GLTFMaterialsUnlitExtension {
	var writer:GLTFFileWriter;
	var name:String = 'KHR_materials_unlit';

	public function new(writer:GLTFFileWriter) {
		this.writer = writer;
	}

	public function writeMaterial(material:Material, materialDef:IntermediaryMaterial) {
		if (!material.isMeshBasicMaterial) return;

		var extensionsUsed = writer.extensionsUsed;
		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = { };

		extensionsUsed[name] = true;

		materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
		materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;
	}
}