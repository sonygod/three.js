class LDrawParsedCache {

	constructor( loader ) {

		this.loader = loader;
		this._cache = {};

	}

	cloneResult( original ) {

		const result = {};

		// vertices are transformed and normals computed before being converted to geometry
		// so these pieces must be cloned.
		result.faces = original.faces.map( face => {

			return {
				colorCode: face.colorCode,
				material: face.material,
				vertices: face.vertices.map( v => v.clone() ),
				normals: face.normals.map( () => null ),
				faceNormal: null
			};

		} );

		result.conditionalSegments = original.conditionalSegments.map( face => {

			return {
				colorCode: face.colorCode,
				material: face.material,
				vertices: face.vertices.map( v => v.clone() ),
				controlPoints: face.controlPoints.map( v => v.clone() )
			};

		} );

		result.lineSegments = original.lineSegments.map( face => {

			return {
				colorCode: face.colorCode,
				material: face.material,
				vertices: face.vertices.map( v => v.clone() )
			};

		} );

		// none if this is subsequently modified
		result.type = original.type;
		result.category = original.category;
		result.keywords = original.keywords;
		result.author = original.author;
		result.subobjects = original.subobjects;
		result.fileName = original.fileName;
		result.totalFaces = original.totalFaces;
		result.startingBuildingStep = original.startingBuildingStep;
		result.materials = original.materials;
		result.group = null;
		return result;

	}

	async fetchData( fileName ) {

		let triedLowerCase = false;
		let locationState = FILE_LOCATION_TRY_PARTS;
		while ( locationState !== FILE_LOCATION_NOT_FOUND ) {

			let subobjectURL = fileName;
			switch ( locationState ) {

				case FILE_LOCATION_AS_IS:
					locationState = locationState + 1;
					break;

				case FILE_LOCATION_TRY_PARTS:
					subobjectURL = 'parts/' + subobjectURL;
					locationState = locationState + 1;
					break;

				case FILE_LOCATION_TRY_P:
					subobjectURL = 'p/' + subobjectURL;
					locationState = locationState + 1;
					break;

				case FILE_LOCATION_TRY_MODELS:
					subobjectURL = 'models/' + subobjectURL;
					locationState = locationState + 1;
					break;

				case FILE_LOCATION_TRY_RELATIVE:
					subobjectURL = fileName.substring( 0, fileName.lastIndexOf( '/' ) + 1 ) + subobjectURL;
					locationState = locationState + 1;
					break;

				case FILE_LOCATION_TRY_ABSOLUTE:

					if ( triedLowerCase ) {

						// Try absolute path
						locationState = FILE_LOCATION_NOT_FOUND;

					} else {

						// Next attempt is lower case
						fileName = fileName.toLowerCase();
						subobjectURL = fileName;
						triedLowerCase = true;
						locationState = FILE_LOCATION_TRY_PARTS;

					}

					break;

			}

			const loader = this.loader;
			const fileLoader = new FileLoader( loader.manager );
			fileLoader.setPath( loader.partsLibraryPath );
			fileLoader.setRequestHeader( loader.requestHeader );
			fileLoader.setWithCredentials( loader.withCredentials );

			try {

				const text = await fileLoader.loadAsync( subobjectURL );
				return text;

			} catch ( _ ) {

				continue;

			}

		}

		throw new Error( 'LDrawLoader: Subobject "' + fileName + '" could not be loaded.' );

	}

	parse( text, fileName = null ) {

		const loader = this.loader;

		// final results
		const faces = [];
		const lineSegments = [];
		const conditionalSegments = [];
		const subobjects = [];
		const materials = {};

		const getLocalMaterial = colorCode => {

			return materials[ colorCode ] || null;

		};

		let type = 'Model';
		let category = null;
		let keywords = null;
		let author = null;
		let totalFaces = 0;

		// split into lines
		if ( text.indexOf( '\r\n' ) !== - 1 ) {

			// This is faster than String.split with regex that splits on both
			text = text.replace( /\r\n/g, '\n' );

		}

		const lines = text.split( '\n' );
		const numLines = lines.length;

		let parsingEmbeddedFiles = false;
		let currentEmbeddedFileName = null;
		let currentEmbeddedText = null;

		let bfcCertified = false;
		let bfcCCW = true;
		let bfcInverted = false;
		let bfcCull = true;

		let startingBuildingStep = false;

		// Parse all line commands
		for ( let lineIndex = 0; lineIndex < numLines; lineIndex ++ ) {

			const line = lines[ lineIndex ];

			if ( line.length === 0 ) continue;

			if ( parsingEmbeddedFiles ) {

				if ( line.startsWith( '0 FILE ' ) ) {

					// Save previous embedded file in the cache
					this.setData( currentEmbeddedFileName, currentEmbeddedText );

					// New embedded text file
					currentEmbeddedFileName = line.substring( 7 );
					currentEmbeddedText = '';

				} else {

					currentEmbeddedText += line + '\n';

				}

				continue;

			}

			const lp = new LineParser( line, lineIndex + 1 );
			lp.seekNonSpace();

			if ( lp.isAtTheEnd() ) {

				// Empty line
				continue;

			}

			// Parse the line type
			const lineType = lp.getToken();

			let material;
			let colorCode;
			let segment;
			let ccw;
			let doubleSided;
			let v0, v1, v2, v3, c0, c1;

			switch ( lineType ) {

				// Line type 0: Comment or META
				case '0':

					// Parse meta directive
					const meta = lp.getToken();

					if ( meta ) {

						switch ( meta ) {

							case '!LDRAW_ORG':

								type = lp.getToken();
								break;

							case '!COLOUR':

								material = loader.parseColorMetaDirective( lp );
								if ( material ) {

									materials[ material.userData.code ] = material;

								}	else {

									console.warn( 'LDrawLoader: Error parsing material' + lp.getLineNumberString() );

								}

								break;

							case '!CATEGORY':

								category = lp.getToken();
								break;

							case '!KEYWORDS':

								const newKeywords = lp.getRemainingString().split( ',' );
								if ( newKeywords.length > 0 ) {

									if ( ! keywords ) {

										keywords = [];

									}

									newKeywords.forEach( function ( keyword ) {

										keywords.push( keyword.trim() );

									} );

								}

								break;

							case 'FILE':

								if ( lineIndex > 0 ) {

									// Start embedded text files parsing
									parsingEmbeddedFiles = true;
									currentEmbeddedFileName = lp.getRemainingString();
									currentEmbeddedText = '';

									bfcCertified = false;
									bfcCCW = true;

								}

								break;

							case 'BFC':

								// Changes to the backface culling state
								while ( ! lp.isAtTheEnd() ) {

									const token = lp.getToken();

									switch ( token ) {

										case 'CERTIFY':
										case 'NOCERTIFY':

											bfcCertified = token === 'CERTIFY';
											bfcCCW = true;

											break;

										case 'CW':
										case 'CCW':

											bfcCCW = token === 'CCW';

											break;

										case 'INVERTNEXT':

											bfcInverted = true;

											break;

										case 'CLIP':
										case 'NOCLIP':

											bfcCull = token === 'CLIP';

											break;

										default:

											console.warn( 'THREE.LDrawLoader: BFC directive "' + token + '" is unknown.' );

											break;

									}

								}

								break;

							case 'STEP':

								startingBuildingStep = true;

								break;

							case 'Author:':

								author = lp.getToken();

								break;

							default:
								// Other meta directives are not implemented
								break;

						}

					}

					break;

					// Line type 1: Sub-object file
				case '1':

					colorCode = lp.getToken();
					material = getLocalMaterial( colorCode );

					const posX = parseFloat( lp.getToken() );
					const posY = parseFloat( lp.getToken() );
					const posZ = parseFloat( lp.getToken() );
					const m0 = parseFloat( lp.getToken() );
					const m1 = parseFloat( lp.getToken() );
					const m2 = parseFloat( lp.getToken() );
					const m3 = parseFloat( lp.getToken() );
					const m4 = parseFloat( lp.getToken() );
					const m5 = parseFloat( lp.getToken() );
					const m6 = parseFloat( lp.getToken() );
					const m7 = parseFloat( lp.getToken() );
					const m8 = parseFloat( lp.getToken() );

					const matrix = new Matrix4().set(
						m0, m1, m2, posX,
						m3, m4, m5, posY,
						m6, m7, m8, posZ,
						0, 0, 0, 1
					);

					let fileName = lp.getRemainingString().trim().replace( /\\/g, '/' );

					if ( loader.fileMap[ fileName ] ) {

						// Found the subobject path in the preloaded file path map
						fileName = loader.fileMap[ fileName ];

					} else {

						// Standardized subfolders
						if ( fileName.startsWith( 's/' ) ) {

							fileName = 'parts/' + fileName;

						} else if ( fileName.startsWith( '48/' ) ) {

							fileName = 'p/' + fileName;

						}

					}

					subobjects.push( {
						material: material,
						colorCode: colorCode,
						matrix: matrix,
						fileName: fileName,
						inverted: bfcInverted,
						startingBuildingStep: startingBuildingStep
					} );

					startingBuildingStep = false;
					bfcInverted = false;

					break;

					// Line type 2: Line segment
				case '2':

					colorCode = lp.getToken();
					material = getLocalMaterial( colorCode );
					v0 = lp.getVector();
					v1 = lp.getVector();

					segment = {
						material: material,
						colorCode: colorCode,
						vertices: [ v0, v1 ],
					};

					lineSegments.push( segment );

					break;

					// Line type 5: Conditional Line segment
				case '5':

					colorCode = lp.getToken();
					material = getLocalMaterial( colorCode );
					v0 = lp.getVector();
					v1 = lp.getVector();
					c0 = lp.getVector();
					c1 = lp.getVector();

					segment = {
						material: material,
						colorCode: colorCode,
						vertices: [ v0, v1 ],
						controlPoints: [ c0, c1 ],
					};

					conditionalSegments.push( segment );

					break;

					// Line type 3: Triangle
				case '3':

					colorCode = lp.getToken();
					material = getLocalMaterial( colorCode );
					ccw = bfcCCW;
					doubleSided = ! bfcCertified || ! bfcCull;

					if ( ccw === true ) {

						v0 = lp.getVector();
						v1 = lp.getVector();
						v2 = lp.getVector();

					} else {

						v2 = lp.getVector();
						v1 = lp.getVector();
						v0 = lp.getVector();

					}

					faces.push( {
						material: material,
						colorCode: colorCode,
						faceNormal: null,
						vertices: [ v0, v1, v2 ],
						normals: [ null, null, null ],
					} );
					totalFaces ++;

					if ( doubleSided === true ) {

						faces.push( {
							material: material,
							colorCode: colorCode,
							faceNormal: null,
							vertices: [ v2, v1, v0 ],
							normals: [ null, null, null ],
						} );
						totalFaces ++;

					}

					break;

					// Line type 4: Quadrilateral
				case '4':

					colorCode = lp.getToken();
					material = getLocalMaterial( colorCode );
					ccw = bfcCCW;
					doubleSided = ! bfcCertified || ! bfcCull;

					if ( ccw === true ) {

						v0 = lp.getVector();
						v1 = lp.getVector();
						v2 = lp.getVector();
						v3 = lp.getVector();

					} else {

						v3 = lp.getVector();
						v2 = lp.getVector();
						v1 = lp.getVector();
						v0 = lp.getVector();

					}

					// specifically place the triangle diagonal in the v0 and v1 slots so we can
					// account for the doubling of vertices later when smoothing normals.
					faces.push( {
						material: material,
						colorCode: colorCode,
						faceNormal: null,
						vertices: [ v0, v1, v2, v3 ],
						normals: [ null, null, null, null ],
					} );
					totalFaces += 2;

					if ( doubleSided === true ) {

						faces.push( {
							material: material,
							colorCode: colorCode,
							faceNormal: null,
							vertices: [ v3, v2, v1, v0 ],
							normals: [ null, null, null, null ],
						} );
						totalFaces += 2;

					}

					break;

				default:
					throw new Error( 'LDrawLoader: Unknown line type "' + lineType + '"' + lp.getLineNumberString() + '.' );

			}

		}

		if ( parsingEmbeddedFiles ) {

			this.setData( currentEmbeddedFileName, currentEmbeddedText );

		}

		return {
			faces,
			conditionalSegments,
			lineSegments,
			type,
			category,
			keywords,
			author,
			subobjects,
			totalFaces,
			startingBuildingStep,
			materials,
			fileName,
			group: null
		};

	}

	// returns an (optionally cloned) instance of the data
	getData( fileName, clone = true ) {

		const key = fileName.toLowerCase();
		const result = this._cache[ key ];
		if ( result === null || result instanceof Promise ) {

			return null;

		}

		if ( clone ) {

			return this.cloneResult( result );

		} else {

			return result;

		}

	}

	// kicks off a fetch and parse of the requested data if it hasn't already been loaded. Returns when
	// the data is ready to use and can be retrieved synchronously with "getData".
	async ensureDataLoaded( fileName ) {

		const key = fileName.toLowerCase();
		if ( ! ( key in this._cache ) ) {

			// replace the promise with a copy of the parsed data for immediate processing
			this._cache[ key ] = this.fetchData( fileName ).then( text => {

				const info = this.parse( text, fileName );
				this._cache[ key ] = info;
				return info;

			} );

		}

		await this._cache[ key ];

	}

	// sets the data in the cache from parsed data
	setData( fileName, text ) {

		const key = fileName.toLowerCase();
		this._cache[ key ] = this.parse( text, fileName );

	}

}