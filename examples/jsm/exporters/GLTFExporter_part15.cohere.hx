class GLTFMaterialsBumpExtension {
	var writer:Dynamic;
	var name:String = 'EXT_materials_bump';

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
		if (!material.isMeshStandardMaterial || (material.bumpScale == 1 && material.bumpMap == null)) {
			return;
		}

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = { };

		if (material.bumpMap != null) {
			var bumpMapDef = { };
			bumpMapDef.index = writer.processTexture(material.bumpMap);
			bumpMapDef.texCoord = material.bumpMap.channel;
			writer.applyTextureTransform(bumpMapDef, material.bumpMap);
			extensionDef.bumpTexture = bumpMapDef;
		}

		extensionDef.bumpFactor = material.bumpScale;

		materialDef.extensions = materialDef.extensions ?? { };
		materialDef.extensions[name] = extensionDef;

		extensionsUsed[name] = true;
	}
}