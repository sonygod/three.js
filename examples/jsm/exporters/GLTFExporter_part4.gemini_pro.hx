class GLTFMaterialsUnlitExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_unlit";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {

		if (!Std.is(material, MeshBasicMaterial)) return;

		var extensionsUsed:Dynamic = writer.extensionsUsed;

		if (materialDef.extensions == null) materialDef.extensions = {};
		materialDef.extensions[this.name] = {};

		extensionsUsed[this.name] = true;

		materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
		materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;

	}

}