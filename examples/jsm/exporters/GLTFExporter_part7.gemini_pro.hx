class GLTFMaterialsIridescenceExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_iridescence";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {

		if (!material.isMeshPhysicalMaterial || material.iridescence == 0) return;

		var extensionDef:Dynamic = {};

		extensionDef.iridescenceFactor = material.iridescence;

		if (material.iridescenceMap != null) {

			var iridescenceMapDef:Dynamic = {
				index: writer.processTexture(material.iridescenceMap),
				texCoord: material.iridescenceMap.channel
			};
			writer.applyTextureTransform(iridescenceMapDef, material.iridescenceMap);
			extensionDef.iridescenceTexture = iridescenceMapDef;

		}

		extensionDef.iridescenceIor = material.iridescenceIOR;
		extensionDef.iridescenceThicknessMinimum = material.iridescenceThicknessRange[0];
		extensionDef.iridescenceThicknessMaximum = material.iridescenceThicknessRange[1];

		if (material.iridescenceThicknessMap != null) {

			var iridescenceThicknessMapDef:Dynamic = {
				index: writer.processTexture(material.iridescenceThicknessMap),
				texCoord: material.iridescenceThicknessMap.channel
			};
			writer.applyTextureTransform(iridescenceThicknessMapDef, material.iridescenceThicknessMap);
			extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;

		}

		materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
		materialDef.extensions[this.name] = extensionDef;

		writer.extensionsUsed[this.name] = true;

	}

}