class GLTFMaterialsClearcoatExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_clearcoat";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic) {

		if (!Reflect.hasField(material, "isMeshPhysicalMaterial") || !Reflect.field(material, "isMeshPhysicalMaterial") || Reflect.field(material, "clearcoat") == 0) return;

		var extensionDef:Dynamic = {};

		extensionDef.clearcoatFactor = Reflect.field(material, "clearcoat");

		if (Reflect.hasField(material, "clearcoatMap") && Reflect.field(material, "clearcoatMap") != null) {
			var clearcoatMapDef:Dynamic = {
				index: Reflect.callMethod(writer, "processTexture", [Reflect.field(material, "clearcoatMap")]),
				texCoord: Reflect.field(material, "clearcoatMap").channel
			};
			Reflect.callMethod(writer, "applyTextureTransform", [clearcoatMapDef, Reflect.field(material, "clearcoatMap")]);
			extensionDef.clearcoatTexture = clearcoatMapDef;
		}

		extensionDef.clearcoatRoughnessFactor = Reflect.field(material, "clearcoatRoughness");

		if (Reflect.hasField(material, "clearcoatRoughnessMap") && Reflect.field(material, "clearcoatRoughnessMap") != null) {
			var clearcoatRoughnessMapDef:Dynamic = {
				index: Reflect.callMethod(writer, "processTexture", [Reflect.field(material, "clearcoatRoughnessMap")]),
				texCoord: Reflect.field(material, "clearcoatRoughnessMap").channel
			};
			Reflect.callMethod(writer, "applyTextureTransform", [clearcoatRoughnessMapDef, Reflect.field(material, "clearcoatRoughnessMap")]);
			extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
		}

		if (Reflect.hasField(material, "clearcoatNormalMap") && Reflect.field(material, "clearcoatNormalMap") != null) {
			var clearcoatNormalMapDef:Dynamic = {
				index: Reflect.callMethod(writer, "processTexture", [Reflect.field(material, "clearcoatNormalMap")]),
				texCoord: Reflect.field(material, "clearcoatNormalMap").channel
			};

			if (Reflect.field(material, "clearcoatNormalScale").x != 1) clearcoatNormalMapDef.scale = Reflect.field(material, "clearcoatNormalScale").x;

			Reflect.callMethod(writer, "applyTextureTransform", [clearcoatNormalMapDef, Reflect.field(material, "clearcoatNormalMap")]);
			extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
		}

		if (Reflect.hasField(materialDef, "extensions")) {
			materialDef.extensions[this.name] = extensionDef;
		} else {
			materialDef.extensions = {this.name: extensionDef};
		}

		Reflect.field(writer, "extensionsUsed")[this.name] = true;
	}

}