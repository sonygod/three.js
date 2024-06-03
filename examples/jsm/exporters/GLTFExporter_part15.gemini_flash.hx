class GLTFMaterialsBumpExtension {

	public var writer:Dynamic;
	public var name:String = "EXT_materials_bump";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
		if (!material.isMeshStandardMaterial || (material.bumpScale == 1 && !material.bumpMap)) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = new haxe.ds.StringMap();

		if (material.bumpMap != null) {
			var bumpMapDef = new haxe.ds.StringMap();
			bumpMapDef.set("index", writer.processTexture(material.bumpMap));
			bumpMapDef.set("texCoord", material.bumpMap.channel);
			writer.applyTextureTransform(bumpMapDef, material.bumpMap);
			extensionDef.set("bumpTexture", bumpMapDef);
		}

		extensionDef.set("bumpFactor", material.bumpScale);

		materialDef.extensions = materialDef.extensions || new haxe.ds.StringMap();
		materialDef.extensions.set(this.name, extensionDef);

		extensionsUsed.set(this.name, true);
	}

}