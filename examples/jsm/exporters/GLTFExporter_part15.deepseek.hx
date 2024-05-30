class GLTFMaterialsBumpExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'EXT_materials_bump';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshStandardMaterial || (material.bumpScale == 1 && !material.bumpMap)) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		if (material.bumpMap) {
			var bumpMapDef = {
				index: writer.processTexture(material.bumpMap),
				texCoord: material.bumpMap.channel
			};
			writer.applyTextureTransform(bumpMapDef, material.bumpMap);
			extensionDef.bumpTexture = bumpMapDef;
		}

		extensionDef.bumpFactor = material.bumpScale;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}