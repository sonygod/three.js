class LDrawLoader extends Loader {

	constructor( manager ) {

		super( manager );

		// Array of THREE.Material
		this.materials = [];
		this.materialLibrary = {};
		this.edgeMaterialCache = new WeakMap();
		this.conditionalEdgeMaterialCache = new WeakMap();

		// This also allows to handle the embedded text files ("0 FILE" lines)
		this.partsCache = new LDrawPartsGeometryCache( this );

		// This object is a map from file names to paths. It agilizes the paths search. If it is not set then files will be searched by trial and error.
		this.fileMap = {};

		// Initializes the materials library with default materials
		this.setMaterials( [] );

		// If this flag is set to true the vertex normals will be smoothed.
		this.smoothNormals = true;

		// The path to load parts from the LDraw parts library from.
		this.partsLibraryPath = '';

		// Material assigned to not available colors for meshes and edges
		this.missingColorMaterial = new MeshStandardMaterial( { name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0 } );
		this.missingEdgeColorMaterial = new LineBasicMaterial( { name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF } );
		this.missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial( { name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF } );
		this.edgeMaterialCache.set( this.missingColorMaterial, this.missingEdgeColorMaterial );
		this.conditionalEdgeMaterialCache.set( this.missingEdgeColorMaterial, this.missingConditionalEdgeColorMaterial );

	}

	setPartsLibraryPath( path ) {

		this.partsLibraryPath = path;
		return this;

	}

	async preloadMaterials( url ) {

		const fileLoader = new FileLoader( this.manager );
		fileLoader.setPath( this.path );
		fileLoader.setRequestHeader( this.requestHeader );
		fileLoader.setWithCredentials( this.withCredentials );

		const text = await fileLoader.loadAsync( url );
		const colorLineRegex = /^0 !COLOUR/;
		const lines = text.split( /[\n\r]/g );
		const materials = [];
		for ( let i = 0, l = lines.length; i < l; i ++ ) {

			const line = lines[ i ];
			if ( colorLineRegex.test( line ) ) {

				const directive = line.replace( colorLineRegex, '' );
				const material = this.parseColorMetaDirective( new LineParser( directive ) );
				materials.push( material );

			}

		}

		this.setMaterials( materials );

	}

	load( url, onLoad, onProgress, onError ) {

		const fileLoader = new FileLoader( this.manager );
		fileLoader.setPath( this.path );
		fileLoader.setRequestHeader( this.requestHeader );
		fileLoader.setWithCredentials( this.withCredentials );
		fileLoader.load( url, text => {

			this.partsCache
				.parseModel( text, this.materialLibrary )
				.then( group => {

					this.applyMaterialsToMesh( group, MAIN_COLOUR_CODE, this.materialLibrary, true );
					this.computeBuildingSteps( group );
					group.userData.fileName = url;
					onLoad( group );

				} )
				.catch( onError );

		}, onProgress, onError );

	}

	parse( text, onLoad, onError ) {

		this.partsCache
			.parseModel( text, this.materialLibrary )
			.then( group => {

				this.applyMaterialsToMesh( group, MAIN_COLOUR_CODE, this.materialLibrary, true );
				this.computeBuildingSteps( group );
				group.userData.fileName = '';
				onLoad( group );

			} )
			.catch( onError );

	}

	setMaterials( materials ) {

		this.materialLibrary = {};
		this.materials = [];
		for ( let i = 0, l = materials.length; i < l; i ++ ) {

			this.addMaterial( materials[ i ] );

		}

		// Add default main triangle and line edge materials (used in pieces that can be colored with a main color)
		this.addMaterial( this.parseColorMetaDirective( new LineParser( 'Main_Colour CODE 16 VALUE #FF8080 EDGE #333333' ) ) );
		this.addMaterial( this.parseColorMetaDirective( new LineParser( 'Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333' ) ) );

		return this;

	}

	setFileMap( fileMap ) {

		this.fileMap = fileMap;

		return this;

	}

	addMaterial( material ) {

		// Adds a material to the material library which is on top of the parse scopes stack. And also to the materials array

		const matLib = this.materialLibrary;
		if ( ! matLib[ material.userData.code ] ) {

			this.materials.push( material );
			matLib[ material.userData.code ] = material;

		}

		return this;

	}

	getMaterial( colorCode ) {

		if ( colorCode.startsWith( '0x2' ) ) {

			// Special 'direct' material value (RGB color)
			const color = colorCode.substring( 3 );

			return this.parseColorMetaDirective( new LineParser( 'Direct_Color_' + color + ' CODE -1 VALUE #' + color + ' EDGE #' + color + '' ) );

		}

		return this.materialLibrary[ colorCode ] || null;

	}

	// Applies the appropriate materials to a prebuilt hierarchy of geometry. Assumes that color codes are present
	// in the material array if they need to be filled in.
	applyMaterialsToMesh( group, parentColorCode, materialHierarchy, finalMaterialPass = false ) {

		// find any missing materials as indicated by a color code string and replace it with a material from the current material lib
		const loader = this;
		const parentIsPassthrough = parentColorCode === MAIN_COLOUR_CODE;
		group.traverse( c => {

			if ( c.isMesh || c.isLineSegments ) {

				if ( Array.isArray( c.material ) ) {

					for ( let i = 0, l = c.material.length; i < l; i ++ ) {

						if ( ! c.material[ i ].isMaterial ) {

							c.material[ i ] = getMaterial( c, c.material[ i ] );

						}

					}

				} else if ( ! c.material.isMaterial ) {

					c.material = getMaterial( c, c.material );

				}

			}

		} );


		// Returns the appropriate material for the object (line or face) given color code. If the code is "pass through"
		// (24 for lines, 16 for edges) then the pass through color code is used. If that is also pass through then it's
		// simply returned for the subsequent material application.
		function getMaterial( c, colorCode ) {

			// if our parent is a passthrough color code and we don't have the current material color available then
			// return early.
			if ( parentIsPassthrough && ! ( colorCode in materialHierarchy ) && ! finalMaterialPass ) {

				return colorCode;

			}

			const forEdge = c.isLineSegments || c.isConditionalLine;
			const isPassthrough = ! forEdge && colorCode === MAIN_COLOUR_CODE || forEdge && colorCode === MAIN_EDGE_COLOUR_CODE;
			if ( isPassthrough ) {

				colorCode = parentColorCode;

			}

			let material = null;
			if ( colorCode in materialHierarchy ) {

				material = materialHierarchy[ colorCode ];

			} else if ( finalMaterialPass ) {

				// see if we can get the final material from from the "getMaterial" function which will attempt to
				// parse the "direct" colors
				material = loader.getMaterial( colorCode );
				if ( material === null ) {

					// otherwise throw a warning if this is final opportunity to set the material
					console.warn( `LDrawLoader: Material properties for code ${ colorCode } not available.` );

					// And return the 'missing color' material
					material = loader.missingColorMaterial;

				}


			} else {

				return colorCode;

			}

			if ( c.isLineSegments ) {

				material = loader.edgeMaterialCache.get( material );

				if ( c.isConditionalLine ) {

					material = loader.conditionalEdgeMaterialCache.get( material );

				}

			}

			return material;

		}

	}

	getMainMaterial() {

		return this.getMaterial( MAIN_COLOUR_CODE );

	}

	getMainEdgeMaterial() {

		const mat = this.getMaterial( MAIN_EDGE_COLOUR_CODE );
		return mat ? this.edgeMaterialCache.get( mat ) : null;

	}

	parseColorMetaDirective( lineParser ) {

		// Parses a color definition and returns a THREE.Material

		let code = null;

		// Triangle and line colors
		let fillColor = '#FF00FF';
		let edgeColor = '#FF00FF';

		// Transparency
		let alpha = 1;
		let isTransparent = false;
		// Self-illumination:
		let luminance = 0;

		let finishType = FINISH_TYPE_DEFAULT;

		let edgeMaterial = null;

		const name = lineParser.getToken();
		if ( ! name ) {

			throw new Error( 'LDrawLoader: Material name was expected after "!COLOUR tag' + lineParser.getLineNumberString() + '.' );

		}

		// Parse tag tokens and their parameters
		let token = null;
		while ( true ) {

			token = lineParser.getToken();

			if ( ! token ) {

				break;

			}

			if ( ! parseLuminance( token ) ) {

				switch ( token.toUpperCase() ) {

					case 'CODE':

						code = lineParser.getToken();
						break;

					case 'VALUE':

						fillColor = lineParser.getToken();
						if ( fillColor.startsWith( '0x' ) ) {

							fillColor = '#' + fillColor.substring( 2 );

						} else if ( ! fillColor.startsWith( '#' ) ) {

							throw new Error( 'LDrawLoader: Invalid color while parsing material' + lineParser.getLineNumberString() + '.' );

						}

						break;

					case 'EDGE':

						edgeColor = lineParser.getToken();
						if ( edgeColor.startsWith( '0x' ) ) {

							edgeColor = '#' + edgeColor.substring( 2 );

						} else if ( ! edgeColor.startsWith( '#' ) ) {

							// Try to see if edge color is a color code
							edgeMaterial = this.getMaterial( edgeColor );
							if ( ! edgeMaterial ) {

								throw new Error( 'LDrawLoader: Invalid edge color while parsing material' + lineParser.getLineNumberString() + '.' );

							}

							// Get the edge material for this triangle material
							edgeMaterial = this.edgeMaterialCache.get( edgeMaterial );

						}

						break;

					case 'ALPHA':

						alpha = parseInt( lineParser.getToken() );

						if ( isNaN( alpha ) ) {

							throw new Error( 'LDrawLoader: Invalid alpha value in material definition' + lineParser.getLineNumberString() + '.' );

						}

						alpha = Math.max( 0, Math.min( 1, alpha / 255 ) );

						if ( alpha < 1 ) {

							isTransparent = true;

						}

						break;

					case 'LUMINANCE':

						if ( ! parseLuminance( lineParser.getToken() ) ) {

							throw new Error( 'LDrawLoader: Invalid luminance value in material definition' + LineParser.getLineNumberString() + '.' );

						}

						break;

					case 'CHROME':
						finishType = FINISH_TYPE_CHROME;
						break;

					case 'PEARLESCENT':
						finishType = FINISH_TYPE_PEARLESCENT;
						break;

					case 'RUBBER':
						finishType = FINISH_TYPE_RUBBER;
						break;

					case 'MATTE_METALLIC':
						finishType = FINISH_TYPE_MATTE_METALLIC;
						break;

					case 'METAL':
						finishType = FINISH_TYPE_METAL;
						break;

					case 'MATERIAL':
						// Not implemented
						lineParser.setToEnd();
						break;

					default:
						throw new Error( 'LDrawLoader: Unknown token "' + token + '" while parsing material' + lineParser.getLineNumberString() + '.' );

				}

			}

		}

		let material = null;

		switch ( finishType ) {

			case FINISH_TYPE_DEFAULT:

				material = new MeshStandardMaterial( { roughness: 0.3, metalness: 0 } );
				break;

			case FINISH_TYPE_PEARLESCENT:

				// Try to imitate pearlescency by making the surface glossy
				material = new MeshStandardMaterial( { roughness: 0.3, metalness: 0.25 } );
				break;

			case FINISH_TYPE_CHROME:

				// Mirror finish surface
				material = new MeshStandardMaterial( { roughness: 0, metalness: 1 } );
				break;

			case FINISH_TYPE_RUBBER:

				// Rubber finish
				material = new MeshStandardMaterial( { roughness: 0.9, metalness: 0 } );
				break;

			case FINISH_TYPE_MATTE_METALLIC:

				// Brushed metal finish
				material = new MeshStandardMaterial( { roughness: 0.8, metalness: 0.4 } );
				break;

			case FINISH_TYPE_METAL:

				// Average metal finish
				material = new MeshStandardMaterial( { roughness: 0.2, metalness: 0.85 } );
				break;

			default:
				// Should not happen
				break;

		}

		material.color.setStyle( fillColor, COLOR_SPACE_LDRAW );
		material.transparent = isTransparent;
		material.premultipliedAlpha = true;
		material.opacity = alpha;
		material.depthWrite = ! isTransparent;

		material.polygonOffset = true;
		material.polygonOffsetFactor = 1;

		if ( luminance !== 0 ) {

			material.emissive.setStyle( fillColor, COLOR_SPACE_LDRAW ).multiplyScalar( luminance );

		}

		if ( ! edgeMaterial ) {

			// This is the material used for edges
			edgeMaterial = new LineBasicMaterial( {
				color: new Color().setStyle( edgeColor, COLOR_SPACE_LDRAW ),
				transparent: isTransparent,
				opacity: alpha,
				depthWrite: ! isTransparent
			} );
			edgeMaterial.color;
			edgeMaterial.userData.code = code;
			edgeMaterial.name = name + ' - Edge';

			// This is the material used for conditional edges
			const conditionalEdgeMaterial = new LDrawConditionalLineMaterial( {

				fog: true,
				transparent: isTransparent,
				depthWrite: ! isTransparent,
				color: new Color().setStyle( edgeColor, COLOR_SPACE_LDRAW ),
				opacity: alpha,

			} );
			conditionalEdgeMaterial.userData.code = code;
			conditionalEdgeMaterial.name = name + ' - Conditional Edge';

			this.conditionalEdgeMaterialCache.set( edgeMaterial, conditionalEdgeMaterial );

		}

		material.userData.code = code;
		material.name = name;

		this.edgeMaterialCache.set( material, edgeMaterial );

		this.addMaterial( material );

		return material;

		function parseLuminance( token ) {

			// Returns success

			let lum;

			if ( token.startsWith( 'LUMINANCE' ) ) {

				lum = parseInt( token.substring( 9 ) );

			} else {

				lum = parseInt( token );

			}

			if ( isNaN( lum ) ) {

				return false;

			}

			luminance = Math.max( 0, Math.min( 1, lum / 255 ) );

			return true;

		}

	}

	computeBuildingSteps( model ) {

		// Sets userdata.buildingStep number in Group objects and userData.numBuildingSteps number in the root Group object.

		let stepNumber = 0;

		model.traverse( c => {

			if ( c.isGroup ) {

				if ( c.userData.startingBuildingStep ) {

					stepNumber ++;

				}

				c.userData.buildingStep = stepNumber;

			}

		} );

		model.userData.numBuildingSteps = stepNumber + 1;

	}

}