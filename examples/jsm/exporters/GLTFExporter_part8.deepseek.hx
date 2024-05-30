class GLTFMaterialsTransmissionExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_transmission';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.transmission == 0) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		extensionDef.transmissionFactor = material.transmission;

		if (material.transmissionMap) {
			var transmissionMapDef = {
				index: writer.processTexture(material.transmissionMap),
				texCoord: material.transmissionMap.channel
			};
			writer.applyTextureTransform(transmissionMapDef, material.transmissionMap);
			extensionDef.transmissionTexture = transmissionMapDef;
		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}