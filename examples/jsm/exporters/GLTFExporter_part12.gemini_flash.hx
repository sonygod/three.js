class GLTFMaterialsSheenExtension {

	public var writer: GLTFWriter;
	public var name: String = "KHR_materials_sheen";

	public function new(writer: GLTFWriter) {
		this.writer = writer;
	}

	public function writeMaterial(material: MeshPhysicalMaterial, materialDef: Dynamic) {
		if (!material.isMeshPhysicalMaterial || material.sheen == 0.0) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef: Dynamic = {};

		if (material.sheenRoughnessMap != null) {
			var sheenRoughnessMapDef: Dynamic = {
				index: writer.processTexture(material.sheenRoughnessMap),
				texCoord: material.sheenRoughnessMap.channel
			};
			writer.applyTextureTransform(sheenRoughnessMapDef, material.sheenRoughnessMap);
			extensionDef.sheenRoughnessTexture = sheenRoughnessMapDef;
		}

		if (material.sheenColorMap != null) {
			var sheenColorMapDef: Dynamic = {
				index: writer.processTexture(material.sheenColorMap),
				texCoord: material.sheenColorMap.channel
			};
			writer.applyTextureTransform(sheenColorMapDef, material.sheenColorMap);
			extensionDef.sheenColorTexture = sheenColorMapDef;
		}

		extensionDef.sheenRoughnessFactor = material.sheenRoughness;
		extensionDef.sheenColorFactor = material.sheenColor.toArray();

		materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}

}