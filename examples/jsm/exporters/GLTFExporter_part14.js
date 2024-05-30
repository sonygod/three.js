class GLTFMaterialsEmissiveStrengthExtension {

	constructor( writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_emissive_strength';

	}

	writeMaterial( material, materialDef ) {

		if ( ! material.isMeshStandardMaterial || material.emissiveIntensity === 1.0 ) return;

		const writer = this.writer;
		const extensionsUsed = writer.extensionsUsed;

		const extensionDef = {};

		extensionDef.emissiveStrength = material.emissiveIntensity;

		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}