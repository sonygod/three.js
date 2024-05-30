class GLTFMaterialsIridescenceExtension {
	public var writer:Writer;
	public var name:String = 'KHR_materials_iridescence';

	public function new(writer:Writer) {
		this.writer = writer;
	}

	public function writeMaterial(material:Material, materialDef:Dynamic) {
		if (!material.isMeshPhysicalMaterial || material.iridescence == 0) {
			return;
		}

		var extensionsUsed = writer.extensionsUsed;
		var extensionDef = { };

		extensionDef.iridescenceFactor = material.iridescence;

		if (material.iridescenceMap != null) {
			var iridescenceMapDef = { };
			iridescenceMapDef.index = writer.processTexture(material.iridescenceMap);
			iridescenceMapDef.texCoord = material.iridescenceMap.channel;
			writer.applyTextureTransform(iridescenceMapDef, material.iridescenceMap);
			extensionDef.iridescenceTexture = iridescenceMapDef;
		}

		extensionDef.iridescenceIor = material.iridescenceIOR;
		extensionDef.iridescenceThicknessMinimum = material.iridescenceThicknessRange[0];
		extensionDef.iridescenceThicknessMaximum = material.iridescenceThicknessRange[1];

		if (material.iridescenceThicknessMap != null) {
			var iridescenceThicknessMapDef = { };
			iridescenceThicknessMapDef.index = writer.processTexture(material.iridescenceThicknessMap);
			iridescenceThicknessMapDef.texCoord = material.iridescenceThicknessMap.channel;
			writer.applyTextureTransform(iridescenceThicknessMapDef, material.iridescenceThicknessMap);
			extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;
		}

		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}