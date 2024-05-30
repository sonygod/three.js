class GLTFTextureTransformExtension {
	public var name:String = EXTENSIONS.KHR_TEXTURE_TRANSFORM;

	public function new() {
		
	}

	public function extendTexture(texture:Texture, transform:GLTFTextureTransform) : Texture {
		if (transform.texCoord == null || transform.texCoord == texture.channel && transform.offset == null && transform.rotation == null && transform.scale == null) {
			// See https://github.com/mrdoob/three.js/issues/21819.
			return texture;
		}

		var newTexture = texture.clone();

		if (transform.texCoord != null) {
			newTexture.channel = transform.texCoord;
		}

		if (transform.offset != null) {
			newTexture.offset = Vector2.ofArray(transform.offset);
		}

		if (transform.rotation != null) {
			newTexture.rotation = transform.rotation;
		}

		if (transform.scale != null) {
			newTexture.repeat = Vector2.ofArray(transform.scale);
		}

		newTexture.needsUpdate = true;

		return newTexture;
	}
}