class MMDLoader extends Loader {

	constructor( manager ) {

		super( manager );

		this.loader = new FileLoader( this.manager );

		this.parser = null; // lazy generation
		this.meshBuilder = new MeshBuilder( this.manager );
		this.animationBuilder = new AnimationBuilder();

	}

	/**
	 * @param {string} animationPath
	 * @return {MMDLoader}
	 */
	setAnimationPath( animationPath ) {

		this.animationPath = animationPath;
		return this;

	}

	// Load MMD assets as Three.js Object

	/**
	 * Loads Model file (.pmd or .pmx) as a SkinnedMesh.
	 *
	 * @param {string} url - url to Model(.pmd or .pmx) file
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	load( url, onLoad, onProgress, onError ) {

		const builder = this.meshBuilder.setCrossOrigin( this.crossOrigin );

		// resource path

		let resourcePath;

		if ( this.resourcePath !== '' ) {

			resourcePath = this.resourcePath;

		} else if ( this.path !== '' ) {

			resourcePath = this.path;

		} else {

			resourcePath = LoaderUtils.extractUrlBase( url );

		}

		const parser = this._getParser();
		const extractModelExtension = this._extractModelExtension;

		this.loader
			.setMimeType( undefined )
			.setPath( this.path )
			.setResponseType( 'arraybuffer' )
			.setRequestHeader( this.requestHeader )
			.setWithCredentials( this.withCredentials )
			.load( url, function ( buffer ) {

				try {

					const modelExtension = extractModelExtension( buffer );

					if ( modelExtension !== 'pmd' && modelExtension !== 'pmx' ) {

						if ( onError ) onError( new Error( 'THREE.MMDLoader: Unknown model file extension .' + modelExtension + '.' ) );

						return;

					}

					const data = modelExtension === 'pmd' ? parser.parsePmd( buffer, true ) : parser.parsePmx( buffer, true );

					onLoad( builder.build( data, resourcePath, onProgress, onError ) );

				} catch ( e ) {

					if ( onError ) onError( e );

				}

			}, onProgress, onError );

	}

	/**
	 * Loads Motion file(s) (.vmd) as a AnimationClip.
	 * If two or more files are specified, they'll be merged.
	 *
	 * @param {string|Array<string>} url - url(s) to animation(.vmd) file(s)
	 * @param {SkinnedMesh|THREE.Camera} object - tracks will be fitting to this object
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	loadAnimation( url, object, onLoad, onProgress, onError ) {

		const builder = this.animationBuilder;

		this.loadVMD( url, function ( vmd ) {

			onLoad( object.isCamera
				? builder.buildCameraAnimation( vmd )
				: builder.build( vmd, object ) );

		}, onProgress, onError );

	}

	/**
	 * Loads mode file and motion file(s) as an object containing
	 * a SkinnedMesh and a AnimationClip.
	 * Tracks of AnimationClip are fitting to the model.
	 *
	 * @param {string} modelUrl - url to Model(.pmd or .pmx) file
	 * @param {string|Array{string}} vmdUrl - url(s) to animation(.vmd) file
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	loadWithAnimation( modelUrl, vmdUrl, onLoad, onProgress, onError ) {

		const scope = this;

		this.load( modelUrl, function ( mesh ) {

			scope.loadAnimation( vmdUrl, mesh, function ( animation ) {

				onLoad( {
					mesh: mesh,
					animation: animation
				} );

			}, onProgress, onError );

		}, onProgress, onError );

	}

	// Load MMD assets as Object data parsed by MMDParser

	/**
	 * Loads .pmd file as an Object.
	 *
	 * @param {string} url - url to .pmd file
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	loadPMD( url, onLoad, onProgress, onError ) {

		const parser = this._getParser();

		this.loader
			.setMimeType( undefined )
			.setPath( this.path )
			.setResponseType( 'arraybuffer' )
			.setRequestHeader( this.requestHeader )
			.setWithCredentials( this.withCredentials )
			.load( url, function ( buffer ) {

				try {

					onLoad( parser.parsePmd( buffer, true ) );

				} catch ( e ) {

					if ( onError ) onError( e );

				}

			}, onProgress, onError );

	}

	/**
	 * Loads .pmx file as an Object.
	 *
	 * @param {string} url - url to .pmx file
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	loadPMX( url, onLoad, onProgress, onError ) {

		const parser = this._getParser();

		this.loader
			.setMimeType( undefined )
			.setPath( this.path )
			.setResponseType( 'arraybuffer' )
			.setRequestHeader( this.requestHeader )
			.setWithCredentials( this.withCredentials )
			.load( url, function ( buffer ) {

				try {

					onLoad( parser.parsePmx( buffer, true ) );

				} catch ( e ) {

					if ( onError ) onError( e );

				}

			}, onProgress, onError );

	}

	/**
	 * Loads .vmd file as an Object. If two or more files are specified
	 * they'll be merged.
	 *
	 * @param {string|Array<string>} url - url(s) to .vmd file(s)
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	loadVMD( url, onLoad, onProgress, onError ) {

		const urls = Array.isArray( url ) ? url : [ url ];

		const vmds = [];
		const vmdNum = urls.length;

		const parser = this._getParser();

		this.loader
			.setMimeType( undefined )
			.setPath( this.animationPath )
			.setResponseType( 'arraybuffer' )
			.setRequestHeader( this.requestHeader )
			.setWithCredentials( this.withCredentials );

		for ( let i = 0, il = urls.length; i < il; i ++ ) {

			this.loader.load( urls[ i ], function ( buffer ) {

				try {

					vmds.push( parser.parseVmd( buffer, true ) );

					if ( vmds.length === vmdNum ) onLoad( parser.mergeVmds( vmds ) );

				} catch ( e ) {

					if ( onError ) onError( e );

				}

			}, onProgress, onError );

		}

	}

	/**
	 * Loads .vpd file as an Object.
	 *
	 * @param {string} url - url to .vpd file
	 * @param {boolean} isUnicode
	 * @param {function} onLoad
	 * @param {function} onProgress
	 * @param {function} onError
	 */
	loadVPD( url, isUnicode, onLoad, onProgress, onError ) {

		const parser = this._getParser();

		this.loader
			.setMimeType( isUnicode ? undefined : 'text/plain; charset=shift_jis' )
			.setPath( this.animationPath )
			.setResponseType( 'text' )
			.setRequestHeader( this.requestHeader )
			.setWithCredentials( this.withCredentials )
			.load( url, function ( text ) {

				try {

					onLoad( parser.parseVpd( text, true ) );

				} catch ( e ) {

					if ( onError ) onError( e );

				}

			}, onProgress, onError );

	}

	// private methods

	_extractModelExtension( buffer ) {

		const decoder = new TextDecoder( 'utf-8' );
		const bytes = new Uint8Array( buffer, 0, 3 );
		return decoder.decode( bytes ).toLowerCase();

	}

	_getParser() {

		if ( this.parser === null ) {

			this.parser = new MMDParser.Parser();

		}

		return this.parser;

	}

}