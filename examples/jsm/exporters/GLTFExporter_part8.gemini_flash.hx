class GLTFMaterialsTransmissionExtension {

	public var writer:Dynamic;
	public var name:String = 'KHR_materials_transmission';

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {

		if (!Reflect.hasField(material, 'isMeshPhysicalMaterial') || material.transmission == 0) return;

		var extensionDef:Dynamic = {};

		extensionDef.transmissionFactor = material.transmission;

		if (Reflect.hasField(material, 'transmissionMap')) {

			var transmissionMapDef:Dynamic = {
				index: writer.processTexture(material.transmissionMap),
				texCoord: material.transmissionMap.channel
			};
			writer.applyTextureTransform(transmissionMapDef, material.transmissionMap);
			extensionDef.transmissionTexture = transmissionMapDef;

		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		writer.extensionsUsed[this.name] = true;

	}

}