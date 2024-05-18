class GLTFMaterialsTransmissionExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_transmission';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.transmission === 0 ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		extensionDef.transmissionFactor = material.transmission;

		if ( material.transmissionMap ) {

			const transmissionMapDef = {
				index: writer.processTexture( material.transmissionMap ),
				texCoord: material.transmissionMap.channel
			};
			writer.applyTextureTransform( transmissionMapDef, material.transmissionMap );
			extensionDef.transmissionTexture = transmissionMapDef;

		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}