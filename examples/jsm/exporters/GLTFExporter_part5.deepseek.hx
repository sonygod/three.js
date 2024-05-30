class GLTFMaterialsClearcoatExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_clearcoat';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.clearcoat == 0) return;

		var extensionDef = {};

		extensionDef.clearcoatFactor = material.clearcoat;

		if (material.clearcoatMap) {
			var clearcoatMapDef = {
				index: writer.processTexture(material.clearcoatMap),
				texCoord: material.clearcoatMap.channel
			};
			writer.applyTextureTransform(clearcoatMapDef, material.clearcoatMap);
			extensionDef.clearcoatTexture = clearcoatMapDef;
		}

		extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;

		if (material.clearcoatRoughnessMap) {
			var clearcoatRoughnessMapDef = {
				index: writer.processTexture(material.clearcoatRoughnessMap),
				texCoord: material.clearcoatRoughnessMap.channel
			};
			writer.applyTextureTransform(clearcoatRoughnessMapDef, material.clearcoatRoughnessMap);
			extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
		}

		if (material.clearcoatNormalMap) {
			var clearcoatNormalMapDef = {
				index: writer.processTexture(material.clearcoatNormalMap),
				texCoord: material.clearcoatNormalMap.channel
			};

			if (material.clearcoatNormalScale.x != 1) clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;

			writer.applyTextureTransform(clearcoatNormalMapDef, material.clearcoatNormalMap);
			extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
		}

		materialDef.extensions = materialDef.extensions ? materialDef.extensions : {};
		materialDef.extensions[this.name] = extensionDef;

		var extensionsUsed = writer.extensionsUsed;
		extensionsUsed[this.name] = true;
	}
}