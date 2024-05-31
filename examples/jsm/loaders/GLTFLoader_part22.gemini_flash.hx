class GLTFTextureTransformExtension {

	public var name: String;

	public function new() {

		this.name = EXTENSIONS.KHR_TEXTURE_TRANSFORM;

	}

	public function extendTexture( texture: Texture, transform: TextureTransform ): Texture {

		if ( ( transform.texCoord == null || transform.texCoord == texture.channel )
			&& transform.offset == null
			&& transform.rotation == null
			&& transform.scale == null ) {

			// See https://github.com/mrdoob/three.js/issues/21819.
			return texture;

		}

		texture = texture.clone();

		if ( transform.texCoord != null ) {

			texture.channel = transform.texCoord;

		}

		if ( transform.offset != null ) {

			texture.offset.fromArray( transform.offset );

		}

		if ( transform.rotation != null ) {

			texture.rotation = transform.rotation;

		}

		if ( transform.scale != null ) {

			texture.repeat.fromArray( transform.scale );

		}

		texture.needsUpdate = true;

		return texture;

	}

}

typedef TextureTransform = {
  var texCoord: Null<Int>;
  var offset: Null<Array<Float>>;
  var rotation: Null<Float>;
  var scale: Null<Array<Float>>;
}