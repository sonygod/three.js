class GLTFMaterialsVolumeExtension {
	public var writer:Any;
	public var name:String = 'KHR_materials_volume';

	public function new(writer:Any) {
		this.writer = writer;
	}

	public function writeMaterial(material:Any, materialDef:Dynamic) {
		if (!material.isMeshPhysicalMaterial || material.transmission == 0) {
			return;
		}

		var extensionsUsed = writer.extensionsUsed;
		var extensionDef = { };

		extensionDef.thicknessFactor = material.thickness;

		if (material.thicknessMap != null) {
			var thicknessMapDef = { };
			thicknessMapDef.index = writer.processTexture(material.thicknessMap);
			thicknessMapDef.texCoord = material.thicknessMap.channel;
			writer.applyTextureTransform(thicknessMapDef, material.thicknessMap);
			extensionDef.thicknessTexture = thicknessMapDef;
		}

		extensionDef.attenuationDistance = material.attenuationDistance;
		extensionDef.attenuationColor = material.attenuationColor.toArray();

		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}