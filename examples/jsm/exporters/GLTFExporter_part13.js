class GLTFMaterialsAnisotropyExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_anisotropy';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.anisotropy == 0.0 ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		if ( material.anisotropyMap ) {

			const anisotropyMapDef = { index: writer.processTexture( material.anisotropyMap ) };
			writer.applyTextureTransform( anisotropyMapDef, material.anisotropyMap );
			extensionDef.anisotropyTexture = anisotropyMapDef;

		}

		extensionDef.anisotropyStrength = material.anisotropy;
		extensionDef.anisotropyRotation = material.anisotropyRotation;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}