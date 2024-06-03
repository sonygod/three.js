class GLTFMaterialsVolumeExtension {

	public var writer:Dynamic;
	public var name:String = 'KHR_materials_volume';

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
		if (!Reflect.hasField(material, 'isMeshPhysicalMaterial') || material.transmission == 0) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef:Dynamic = {};

		extensionDef.thicknessFactor = material.thickness;

		if (Reflect.hasField(material, 'thicknessMap')) {

			var thicknessMapDef:Dynamic = {
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