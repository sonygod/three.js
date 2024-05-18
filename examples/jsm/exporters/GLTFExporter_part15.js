class GLTFMaterialsBumpExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'EXT_materials_bump';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshStandardMaterial || (
		       material.bumpScale === 1 &&
		     ! material.bumpMap ) ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		if ( material.bumpMap ) {

			const bumpMapDef = {
				index: writer.processTexture( material.bumpMap ),
				texCoord: material.bumpMap.channel
			};
			writer.applyTextureTransform( bumpMapDef, material.bumpMap );
			extensionDef.bumpTexture = bumpMapDef;

		}

		extensionDef.bumpFactor = material.bumpScale;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}