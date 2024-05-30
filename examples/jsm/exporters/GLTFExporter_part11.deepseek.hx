class GLTFMaterialsSpecularExtension {

	var writer:Dynamic;
	var name:String;

	public function new(writer:Dynamic) {
		this.writer = writer;
		this.name = 'KHR_materials_specular';
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || (material.specularIntensity == 1.0 &&
		       material.specularColor.equals( DEFAULT_SPECULAR_COLOR ) &&
		     !material.specularIntensityMap && !material.specularColorMap)) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		if (material.specularIntensityMap) {
			var specularIntensityMapDef = {
				index: writer.processTexture(material.specularIntensityMap),
				texCoord: material.specularIntensityMap.channel
			};
			writer.applyTextureTransform(specularIntensityMapDef, material.specularIntensityMap);
			extensionDef.specularTexture = specularIntensityMapDef;
		}

		if (material.specularColorMap) {
			var specularColorMapDef = {
				index: writer.processTexture(material.specularColorMap),
				texCoord: material.specularColorMap.channel
			};
			writer.applyTextureTransform(specularColorMapDef, material.specularColorMap);
			extensionDef.specularColorTexture = specularColorMapDef;
		}

		extensionDef.specularFactor = material.specularIntensity;
		extensionDef.specularColorFactor = material.specularColor.toArray();

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;

		extensionsUsed[this.name] = true;
	}
}