class GLTFMaterialsVolumeExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_volume';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.transmission == 0) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		extensionDef.thicknessFactor = material.thickness;

		if (material.thicknessMap) {
			var thicknessMapDef = {
				index: writer.processTexture(material.thicknessMap),
				texCoord: material.thicknessMap.channel
			};
			writer.applyTextureTransform(thicknessMapDef, material.thicknessMap);
			extensionDef.thicknessTexture = thicknessMapDef;
		}

		extensionDef.attenuationDistance = material.attenuationDistance;
		extensionDef.attenuationColor = material.attenuationColor.toArray();

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}