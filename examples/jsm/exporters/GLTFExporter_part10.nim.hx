class GLTFMaterialsIorExtension {

	var writer:Writer;
	var name:String;

	public function new(writer:Writer) {

		this.writer = writer;
		this.name = 'KHR_materials_ior';

	}

	public function writeMaterial(material:Material, materialDef:Dynamic) {

		if (!Type.getClass(material) == MeshPhysicalMaterial || material.ior == 1.5) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		extensionDef.ior = material.ior;

		materialDef.extensions = materialDef.extensions ?? {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;

	}

}