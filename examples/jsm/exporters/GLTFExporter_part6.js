class GLTFMaterialsDispersionExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_dispersion';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshPhysicalMaterial || material.dispersion === 0 ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		extensionDef.dispersion = material.dispersion;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}