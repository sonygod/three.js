class MaterialBuilder {

	constructor( manager ) {

		this.manager = manager;

		this.textureLoader = new TextureLoader( this.manager );
		this.tgaLoader = null; // lazy generation

		this.crossOrigin = 'anonymous';
		this.resourcePath = undefined;

	}

	/**
	 * @param {string} crossOrigin
	 * @return {MaterialBuilder}
	 */
	setCrossOrigin( crossOrigin ) {

		this.crossOrigin = crossOrigin;
		return this;

	}

	/**
	 * @param {string} resourcePath
	 * @return {MaterialBuilder}
	 */
	setResourcePath( resourcePath ) {

		this.resourcePath = resourcePath;
		return this;

	}

	/**
	 * @param {Object} data - parsed PMD/PMX data
	 * @param {BufferGeometry} geometry - some properties are dependend on geometry
	 * @param {function} onProgress
	 * @param {function} onError
	 * @return {Array<MMDToonMaterial>}
	 */
	build( data, geometry /*, onProgress, onError */ ) {

		const materials = [];

		const textures = {};

		this.textureLoader.setCrossOrigin( this.crossOrigin );

		// materials

		for ( let i = 0; i < data.metadata.materialCount; i ++ ) {

			const material = data.materials[ i ];

			const params = { userData: { MMD: {} } };

			if ( material.name !== undefined ) params.name = material.name;

			/*
				 * Color
				 *
				 * MMD         MMDToonMaterial
				 * ambient  -  emissive * a
				 *               (a = 1.0 without map texture or 0.2 with map texture)
				 *
				 * MMDToonMaterial doesn't have ambient. Set it to emissive instead.
				 * It'll be too bright if material has map texture so using coef 0.2.
				 */
			params.diffuse = new Color().setRGB(
				material.diffuse[ 0 ],
				material.diffuse[ 1 ],
				material.diffuse[ 2 ],
				SRGBColorSpace
			);
			params.opacity = material.diffuse[ 3 ];
			params.specular = new Color().setRGB( ...material.specular, SRGBColorSpace );
			params.shininess = material.shininess;
			params.emissive = new Color().setRGB( ...material.ambient, SRGBColorSpace );
			params.transparent = params.opacity !== 1.0;

			//

			params.fog = true;

			// blend

			params.blending = CustomBlending;
			params.blendSrc = SrcAlphaFactor;
			params.blendDst = OneMinusSrcAlphaFactor;
			params.blendSrcAlpha = SrcAlphaFactor;
			params.blendDstAlpha = DstAlphaFactor;

			// side

			if ( data.metadata.format === 'pmx' && ( material.flag & 0x1 ) === 1 ) {

				params.side = DoubleSide;

			} else {

				params.side = params.opacity === 1.0 ? FrontSide : DoubleSide;

			}

			if ( data.metadata.format === 'pmd' ) {

				// map, matcap

				if ( material.fileName ) {

					const fileName = material.fileName;
					const fileNames = fileName.split( '*' );

					// fileNames[ 0 ]: mapFileName
					// fileNames[ 1 ]: matcapFileName( optional )

					params.map = this._loadTexture( fileNames[ 0 ], textures );

					if ( fileNames.length > 1 ) {

						const extension = fileNames[ 1 ].slice( - 4 ).toLowerCase();

						params.matcap = this._loadTexture(
							fileNames[ 1 ],
							textures
						);

						params.matcapCombine = extension === '.sph'
							? MultiplyOperation
							: AddOperation;

					}

				}

				// gradientMap

				const toonFileName = ( material.toonIndex === - 1 )
					? 'toon00.bmp'
					: data.toonTextures[ material.toonIndex ].fileName;

				params.gradientMap = this._loadTexture(
					toonFileName,
					textures,
					{
						isToonTexture: true,
						isDefaultToonTexture: this._isDefaultToonTexture( toonFileName )
					}
				);

				// parameters for OutlineEffect

				params.userData.outlineParameters = {
					thickness: material.edgeFlag === 1 ? 0.003 : 0.0,
					color: [ 0, 0, 0 ],
					alpha: 1.0,
					visible: material.edgeFlag === 1
				};

			} else {

				// map

				if ( material.textureIndex !== - 1 ) {

					params.map = this._loadTexture( data.textures[ material.textureIndex ], textures );

					// Since PMX spec don't have standard to list map files except color map and env map,
					// we need to save file name for further mapping, like matching normal map file names after model loaded.
					// ref: https://gist.github.com/felixjones/f8a06bd48f9da9a4539f#texture
					params.userData.MMD.mapFileName = data.textures[ material.textureIndex ];

				}

				// matcap TODO: support m.envFlag === 3

				if ( material.envTextureIndex !== - 1 && ( material.envFlag === 1 || material.envFlag == 2 ) ) {

					params.matcap = this._loadTexture(
						data.textures[ material.envTextureIndex ],
						textures
					);

					// Same as color map above, keep file name in userData for further usage.
					params.userData.MMD.matcapFileName = data.textures[ material.envTextureIndex ];

					params.matcapCombine = material.envFlag === 1
						? MultiplyOperation
						: AddOperation;

				}

				// gradientMap

				let toonFileName, isDefaultToon;

				if ( material.toonIndex === - 1 || material.toonFlag !== 0 ) {

					toonFileName = 'toon' + ( '0' + ( material.toonIndex + 1 ) ).slice( - 2 ) + '.bmp';
					isDefaultToon = true;

				} else {

					toonFileName = data.textures[ material.toonIndex ];
					isDefaultToon = false;

				}

				params.gradientMap = this._loadTexture(
					toonFileName,
					textures,
					{
						isToonTexture: true,
						isDefaultToonTexture: isDefaultToon
					}
				);

				// parameters for OutlineEffect
				params.userData.outlineParameters = {
					thickness: material.edgeSize / 300, // TODO: better calculation?
					color: material.edgeColor.slice( 0, 3 ),
					alpha: material.edgeColor[ 3 ],
					visible: ( material.flag & 0x10 ) !== 0 && material.edgeSize > 0.0
				};

			}

			if ( params.map !== undefined ) {

				if ( ! params.transparent ) {

					this._checkImageTransparency( params.map, geometry, i );

				}

				params.emissive.multiplyScalar( 0.2 );

			}

			materials.push( new MMDToonMaterial( params ) );

		}

		if ( data.metadata.format === 'pmx' ) {

			// set transparent true if alpha morph is defined.

			function checkAlphaMorph( elements, materials ) {

				for ( let i = 0, il = elements.length; i < il; i ++ ) {

					const element = elements[ i ];

					if ( element.index === - 1 ) continue;

					const material = materials[ element.index ];

					if ( material.opacity !== element.diffuse[ 3 ] ) {

						material.transparent = true;

					}

				}

			}

			for ( let i = 0, il = data.morphs.length; i < il; i ++ ) {

				const morph = data.morphs[ i ];
				const elements = morph.elements;

				if ( morph.type === 0 ) {

					for ( let j = 0, jl = elements.length; j < jl; j ++ ) {

						const morph2 = data.morphs[ elements[ j ].index ];

						if ( morph2.type !== 8 ) continue;

						checkAlphaMorph( morph2.elements, materials );

					}

				} else if ( morph.type === 8 ) {

					checkAlphaMorph( elements, materials );

				}

			}

		}

		return materials;

	}

	// private methods

	_getTGALoader() {

		if ( this.tgaLoader === null ) {

			if ( TGALoader === undefined ) {

				throw new Error( 'THREE.MMDLoader: Import TGALoader' );

			}

			this.tgaLoader = new TGALoader( this.manager );

		}

		return this.tgaLoader;

	}

	_isDefaultToonTexture( name ) {

		if ( name.length !== 10 ) return false;

		return /toon(10|0[0-9])\.bmp/.test( name );

	}

	_loadTexture( filePath, textures, params, onProgress, onError ) {

		params = params || {};

		const scope = this;

		let fullPath;

		if ( params.isDefaultToonTexture === true ) {

			let index;

			try {

				index = parseInt( filePath.match( /toon([0-9]{2})\.bmp$/ )[ 1 ] );

			} catch ( e ) {

				console.warn( 'THREE.MMDLoader: ' + filePath + ' seems like a '
						+ 'not right default texture path. Using toon00.bmp instead.' );

				index = 0;

			}

			fullPath = DEFAULT_TOON_TEXTURES[ index ];

		} else {

			fullPath = this.resourcePath + filePath;

		}

		if ( textures[ fullPath ] !== undefined ) return textures[ fullPath ];

		let loader = this.manager.getHandler( fullPath );

		if ( loader === null ) {

			loader = ( filePath.slice( - 4 ).toLowerCase() === '.tga' )
				? this._getTGALoader()
				: this.textureLoader;

		}

		const texture = loader.load( fullPath, function ( t ) {

			// MMD toon texture is Axis-Y oriented
			// but Three.js gradient map is Axis-X oriented.
			// So here replaces the toon texture image with the rotated one.
			if ( params.isToonTexture === true ) {

				t.image = scope._getRotatedImage( t.image );

				t.magFilter = NearestFilter;
				t.minFilter = NearestFilter;

			}

			t.flipY = false;
			t.wrapS = RepeatWrapping;
			t.wrapT = RepeatWrapping;
			t.colorSpace = SRGBColorSpace;

			for ( let i = 0; i < texture.readyCallbacks.length; i ++ ) {

				texture.readyCallbacks[ i ]( texture );

			}

			delete texture.readyCallbacks;

		}, onProgress, onError );

		texture.readyCallbacks = [];

		textures[ fullPath ] = texture;

		return texture;

	}

	_getRotatedImage( image ) {

		const canvas = document.createElement( 'canvas' );
		const context = canvas.getContext( '2d' );

		const width = image.width;
		const height = image.height;

		canvas.width = width;
		canvas.height = height;

		context.clearRect( 0, 0, width, height );
		context.translate( width / 2.0, height / 2.0 );
		context.rotate( 0.5 * Math.PI ); // 90.0 * Math.PI / 180.0
		context.translate( - width / 2.0, - height / 2.0 );
		context.drawImage( image, 0, 0 );

		return context.getImageData( 0, 0, width, height );

	}

	// Check if the partial image area used by the texture is transparent.
	_checkImageTransparency( map, geometry, groupIndex ) {

		map.readyCallbacks.push( function ( texture ) {

			// Is there any efficient ways?
			function createImageData( image ) {

				const canvas = document.createElement( 'canvas' );
				canvas.width = image.width;
				canvas.height = image.height;

				const context = canvas.getContext( '2d' );
				context.drawImage( image, 0, 0 );

				return context.getImageData( 0, 0, canvas.width, canvas.height );

			}

			function detectImageTransparency( image, uvs, indices ) {

				const width = image.width;
				const height = image.height;
				const data = image.data;
				const threshold = 253;

				if ( data.length / ( width * height ) !== 4 ) return false;

				for ( let i = 0; i < indices.length; i += 3 ) {

					const centerUV = { x: 0.0, y: 0.0 };

					for ( let j = 0; j < 3; j ++ ) {

						const index = indices[ i * 3 + j ];
						const uv = { x: uvs[ index * 2 + 0 ], y: uvs[ index * 2 + 1 ] };

						if ( getAlphaByUv( image, uv ) < threshold ) return true;

						centerUV.x += uv.x;
						centerUV.y += uv.y;

					}

					centerUV.x /= 3;
					centerUV.y /= 3;

					if ( getAlphaByUv( image, centerUV ) < threshold ) return true;

				}

				return false;

			}

			/*
				 * This method expects
				 *   texture.flipY = false
				 *   texture.wrapS = RepeatWrapping
				 *   texture.wrapT = RepeatWrapping
				 * TODO: more precise
				 */
			function getAlphaByUv( image, uv ) {

				const width = image.width;
				const height = image.height;

				let x = Math.round( uv.x * width ) % width;
				let y = Math.round( uv.y * height ) % height;

				if ( x < 0 ) x += width;
				if ( y < 0 ) y += height;

				const index = y * width + x;

				return image.data[ index * 4 + 3 ];

			}

			if ( texture.isCompressedTexture === true ) {

				if ( NON_ALPHA_CHANNEL_FORMATS.includes( texture.format ) ) {

					map.transparent = false;

				} else {

					// any other way to check transparency of CompressedTexture?
					map.transparent = true;

				}

				return;

			}

			const imageData = texture.image.data !== undefined
				? texture.image
				: createImageData( texture.image );

			const group = geometry.groups[ groupIndex ];

			if ( detectImageTransparency(
				imageData,
				geometry.attributes.uv.array,
				geometry.index.array.slice( group.start, group.start + group.count ) ) ) {

				map.transparent = true;

			}

		} );

	}

}