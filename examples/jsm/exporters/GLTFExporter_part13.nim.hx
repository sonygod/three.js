class GLTFMaterialsAnisotropyExtension {

	var writer:Writer;
	var name:String;

	public function new( writer:Writer ) {

		this.writer = writer;
		this.name = 'KHR_materials_anisotropy';

	}

	public function writeMaterial( material:Dynamic, materialDef:Dynamic ) {

		if ( !Std.is(material, MeshPhysicalMaterial) || material.anisotropy == 0.0 ) return;

		var writer = this.writer;
		var extensionsUsed = writer.extensionsUsed;

		var extensionDef = {};

		if ( material.anisotropyMap != null ) {

			var anisotropyMapDef = { index: writer.processTexture( material.anisotropyMap ) };
			writer.applyTextureTransform( anisotropyMapDef, material.anisotropyMap );
			extensionDef.anisotropyTexture = anisotropyMapDef;

		}

		extensionDef.anisotropyStrength = material.anisotropy;
		extensionDef.anisotropyRotation = material.anisotropyRotation;

		materialDef.extensions = materialDef.extensions ?? {};
		materialDef.extensions[ this.name ] = extensionDef;

		extensionsUsed[ this.name ] = true;

	}

}