	function initTexture( textureProperties, texture ) {

		let forceUpload = false;

		if ( textureProperties.__webglInit === undefined ) {

			textureProperties.__webglInit = true;

			texture.addEventListener( 'dispose', onTextureDispose );

		}

		// create Source <-> WebGLTextures mapping if necessary

		const source = texture.source;
		let webglTextures = _sources.get( source );

		if ( webglTextures === undefined ) {

			webglTextures = {};
			_sources.set( source, webglTextures );

		}

		// check if there is already a WebGLTexture object for the given texture parameters

		const textureCacheKey = getTextureCacheKey( texture );

		if ( textureCacheKey !== textureProperties.__cacheKey ) {

			// if not, create a new instance of WebGLTexture

			if ( webglTextures[ textureCacheKey ] === undefined ) {

				// create new entry

				webglTextures[ textureCacheKey ] = {
					texture: _gl.createTexture(),
					usedTimes: 0
				};

				info.memory.textures ++;

				// when a new instance of WebGLTexture was created, a texture upload is required
				// even if the image contents are identical

				forceUpload = true;

			}

			webglTextures[ textureCacheKey ].usedTimes ++;

			// every time the texture cache key changes, it's necessary to check if an instance of
			// WebGLTexture can be deleted in order to avoid a memory leak.

			const webglTexture = webglTextures[ textureProperties.__cacheKey ];

			if ( webglTexture !== undefined ) {

				webglTextures[ textureProperties.__cacheKey ].usedTimes --;

				if ( webglTexture.usedTimes === 0 ) {

					deleteTexture( texture );

				}

			}

			// store references to cache key and WebGLTexture object

			textureProperties.__cacheKey = textureCacheKey;
			textureProperties.__webglTexture = webglTextures[ textureCacheKey ].texture;

		}

		return forceUpload;

	}