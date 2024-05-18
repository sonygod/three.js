class GLTFMaterialsClearcoatExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_clearcoat';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.clearcoat === 0 ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		extensionDef.clearcoatFactor = material.clearcoat;

		if ( material.clearcoatMap ) {

			const clearcoatMapDef = {
				index: writer.processTexture( material.clearcoatMap ),
				texCoord: material.clearcoatMap.channel
			};
			writer.applyTextureTransform( clearcoatMapDef, material.clearcoatMap );
			extensionDef.clearcoatTexture = clearcoatMapDef;

		}

		extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;

		if ( material.clearcoatRoughnessMap ) {

			const clearcoatRoughnessMapDef = {
				index: writer.processTexture( material.clearcoatRoughnessMap ),
				texCoord: material.clearcoatRoughnessMap.channel
			};
			writer.applyTextureTransform( clearcoatRoughnessMapDef, material.clearcoatRoughnessMap );
			extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;

		}

		if ( material.clearcoatNormalMap ) {

			const clearcoatNormalMapDef = {
				index: writer.processTexture( material.clearcoatNormalMap ),
				texCoord: material.clearcoatNormalMap.channel
			};

			if ( material.clearcoatNormalScale.x !== 1 ) clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;

			writer.applyTextureTransform( clearcoatNormalMapDef, material.clearcoatNormalMap );
			extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;

		}

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;


	}

}