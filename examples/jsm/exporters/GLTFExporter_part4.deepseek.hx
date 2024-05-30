class GLTFMaterialsUnlitExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_unlit';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshBasicMaterial) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = {};

		extensionsUsed[this.name] = true;

		materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
		materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;
	}
}