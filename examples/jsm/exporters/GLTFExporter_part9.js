class GLTFMaterialsVolumeExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_volume';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.transmission === 0 ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		extensionDef.thicknessFactor = material.thickness;

		if ( material.thicknessMap ) {

			const thicknessMapDef = {
				index: writer.processTexture( material.thicknessMap ),
				texCoord: material.thicknessMap.channel
			};
			writer.applyTextureTransform( thicknessMapDef, material.thicknessMap );
			extensionDef.thicknessTexture = thicknessMapDef;

		}

		extensionDef.attenuationDistance = material.attenuationDistance;
		extensionDef.attenuationColor = material.attenuationColor.toArray();

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}