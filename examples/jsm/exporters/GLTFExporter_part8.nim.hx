class GLTFMaterialsTransmissionExtension {

	var writer:Writer;
	var name:String;

	public function new( writer:Writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_transmission';

	}

	public function writeMaterial( material:Material, materialDef:Dynamic ) {

		if ( ! (material is MeshPhysicalMaterial) || material.transmission == 0 ) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = { };

		extensionDef.transmissionFactor = material.transmission;

		if ( material.transmissionMap != null ) {

			var transmissionMapDef = {
				index: writer.processTexture( material.transmissionMap ),
				texCoord: material.transmissionMap.channel
			};
			writer.applyTextureTransform( transmissionMapDef, material.transmissionMap );
			extensionDef.transmissionTexture = transmissionMapDef;

		}

		materialDef.extensions = (materialDef.extensions != null) ? materialDef.extensions : {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}