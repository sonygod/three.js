class GLTFMaterialsIorExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_ior";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
		if (!material.isMeshPhysicalMaterial || material.ior == 1.5) return;

		var extensionDef:Dynamic = {};
		extensionDef.ior = material.ior;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		this.writer.extensionsUsed[this.name] = true;
	}

}