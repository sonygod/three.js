class GLTFMaterialsTransmissionExtension {
	public var writer:Writer;
	public var name:String = 'KHR_materials_transmission';

	public function new(writer:Writer) {
		this.writer = writer;
	}

	public function writeMaterial(material:Material, materialDef:MaterialDef) {
		if (!material.isMeshPhysicalMaterial || material.transmission == 0) {
			return;
		}

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {
			'transmissionFactor': material.transmission
		};

		if (material.transmissionMap != null) {
			var transmissionMapDef = {
				'index': writer.processTexture(material.transmissionMap),
				'texCoord': material.transmissionMap.channel
			};
			writer.applyTextureTransform(transmissionMapDef, material.transmissionMap);
			extensionDef.transmissionTexture = transmissionMapDef;
		}

		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}