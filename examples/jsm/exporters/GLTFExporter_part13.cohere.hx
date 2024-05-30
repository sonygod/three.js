class GLTFMaterialsAnisotropyExtension {
	public var writer:Writer;
	public var name:String = 'KHR_materials_anisotropy';

	public function new(writer:Writer) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
		if (!material.isMeshPhysicalMaterial || material.anisotropy == 0.0) {
			return;
		}

		var extensionsUsed = writer.extensionsUsed;
		var extensionDef = { };

		if (material.anisotropyMap != null) {
			var anisotropyMapDef = { index: writer.processTexture(material.anisotropyMap) };
			writer.applyTextureTransform(anisotropyMapDef, material.anisotropyMap);
			extensionDef.anisotropyTexture = anisotropyMapDef;
		}

		extensionDef.anisotropyStrength = material.anisotropy;
		extensionDef.anisotropyRotation = material.anisotropyRotation;

		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}