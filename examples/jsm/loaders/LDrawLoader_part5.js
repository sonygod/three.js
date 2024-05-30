class LDrawPartsGeometryCache {

	constructor( loader ) {

		this.loader = loader;
		this.parseCache = new LDrawParsedCache( loader );
		this._cache = {};

	}

	// Convert the given file information into a mesh by processing subobjects.
	async processIntoMesh( info ) {

		const loader = this.loader;
		const parseCache = this.parseCache;
		const faceMaterials = new Set();

		// Processes the part subobject information to load child parts and merge geometry onto part
		// piece object.
		const processInfoSubobjects = async ( info, subobject = null ) => {

			const subobjects = info.subobjects;
			const promises = [];

			// Trigger load of all subobjects. If a subobject isn't a primitive then load it as a separate
			// group which lets instruction steps apply correctly.
			for ( let i = 0, l = subobjects.length; i < l; i ++ ) {

				const subobject = subobjects[ i ];
				const promise = parseCache.ensureDataLoaded( subobject.fileName ).then( () => {

					const subobjectInfo = parseCache.getData( subobject.fileName, false );
					if ( ! isPrimitiveType( subobjectInfo.type ) ) {

						return this.loadModel( subobject.fileName ).catch( error => {

							console.warn( error );
							return null;

						} );

					}

					return processInfoSubobjects( parseCache.getData( subobject.fileName ), subobject );

				} );

				promises.push( promise );

			}

			const group = new Group();
			group.userData.category = info.category;
			group.userData.keywords = info.keywords;
			group.userData.author = info.author;
			group.userData.type = info.type;
			group.userData.fileName = info.fileName;
			info.group = group;

			const subobjectInfos = await Promise.all( promises );
			for ( let i = 0, l = subobjectInfos.length; i < l; i ++ ) {

				const subobject = info.subobjects[ i ];
				const subobjectInfo = subobjectInfos[ i ];

				if ( subobjectInfo === null ) {

					// the subobject failed to load
					continue;

				}

				// if the subobject was loaded as a separate group then apply the parent scopes materials
				if ( subobjectInfo.isGroup ) {

					const subobjectGroup = subobjectInfo;
					subobject.matrix.decompose( subobjectGroup.position, subobjectGroup.quaternion, subobjectGroup.scale );
					subobjectGroup.userData.startingBuildingStep = subobject.startingBuildingStep;
					subobjectGroup.name = subobject.fileName;

					loader.applyMaterialsToMesh( subobjectGroup, subobject.colorCode, info.materials );
					subobjectGroup.userData.colorCode = subobject.colorCode;

					group.add( subobjectGroup );
					continue;

				}

				// add the subobject group if it has children in case it has both children and primitives
				if ( subobjectInfo.group.children.length ) {

					group.add( subobjectInfo.group );

				}

				// transform the primitives into the local space of the parent piece and append them to
				// to the parent primitives list.
				const parentLineSegments = info.lineSegments;
				const parentConditionalSegments = info.conditionalSegments;
				const parentFaces = info.faces;

				const lineSegments = subobjectInfo.lineSegments;
				const conditionalSegments = subobjectInfo.conditionalSegments;

				const faces = subobjectInfo.faces;
				const matrix = subobject.matrix;
				const inverted = subobject.inverted;
				const matrixScaleInverted = matrix.determinant() < 0;
				const colorCode = subobject.colorCode;

				const lineColorCode = colorCode === MAIN_COLOUR_CODE ? MAIN_EDGE_COLOUR_CODE : colorCode;
				for ( let i = 0, l = lineSegments.length; i < l; i ++ ) {

					const ls = lineSegments[ i ];
					const vertices = ls.vertices;
					vertices[ 0 ].applyMatrix4( matrix );
					vertices[ 1 ].applyMatrix4( matrix );
					ls.colorCode = ls.colorCode === MAIN_EDGE_COLOUR_CODE ? lineColorCode : ls.colorCode;
					ls.material = ls.material || getMaterialFromCode( ls.colorCode, ls.colorCode, info.materials, true );

					parentLineSegments.push( ls );

				}

				for ( let i = 0, l = conditionalSegments.length; i < l; i ++ ) {

					const os = conditionalSegments[ i ];
					const vertices = os.vertices;
					const controlPoints = os.controlPoints;
					vertices[ 0 ].applyMatrix4( matrix );
					vertices[ 1 ].applyMatrix4( matrix );
					controlPoints[ 0 ].applyMatrix4( matrix );
					controlPoints[ 1 ].applyMatrix4( matrix );
					os.colorCode = os.colorCode === MAIN_EDGE_COLOUR_CODE ? lineColorCode : os.colorCode;
					os.material = os.material || getMaterialFromCode( os.colorCode, os.colorCode, info.materials, true );

					parentConditionalSegments.push( os );

				}

				for ( let i = 0, l = faces.length; i < l; i ++ ) {

					const tri = faces[ i ];
					const vertices = tri.vertices;
					for ( let i = 0, l = vertices.length; i < l; i ++ ) {

						vertices[ i ].applyMatrix4( matrix );

					}

					tri.colorCode = tri.colorCode === MAIN_COLOUR_CODE ? colorCode : tri.colorCode;
					tri.material = tri.material || getMaterialFromCode( tri.colorCode, colorCode, info.materials, false );
					faceMaterials.add( tri.colorCode );

					// If the scale of the object is negated then the triangle winding order
					// needs to be flipped.
					if ( matrixScaleInverted !== inverted ) {

						vertices.reverse();

					}

					parentFaces.push( tri );

				}

				info.totalFaces += subobjectInfo.totalFaces;

			}

			// Apply the parent subobjects pass through material code to this object. This is done several times due
			// to material scoping.
			if ( subobject ) {

				loader.applyMaterialsToMesh( group, subobject.colorCode, info.materials );
				group.userData.colorCode = subobject.colorCode;

			}

			return info;

		};

		// Track material use to see if we need to use the normal smooth slow path for hard edges.
		for ( let i = 0, l = info.faces; i < l; i ++ ) {

			faceMaterials.add( info.faces[ i ].colorCode );

		}

		await processInfoSubobjects( info );

		if ( loader.smoothNormals ) {

			const checkSubSegments = faceMaterials.size > 1;
			generateFaceNormals( info.faces );
			smoothNormals( info.faces, info.lineSegments, checkSubSegments );

		}

		// Add the primitive objects and metadata.
		const group = info.group;
		if ( info.faces.length > 0 ) {

			group.add( createObject( this.loader, info.faces, 3, false, info.totalFaces ) );

		}

		if ( info.lineSegments.length > 0 ) {

			group.add( createObject( this.loader, info.lineSegments, 2 ) );

		}

		if ( info.conditionalSegments.length > 0 ) {

			group.add( createObject( this.loader, info.conditionalSegments, 2, true ) );

		}

		return group;

	}

	hasCachedModel( fileName ) {

		return fileName !== null && fileName.toLowerCase() in this._cache;

	}

	async getCachedModel( fileName ) {

		if ( fileName !== null && this.hasCachedModel( fileName ) ) {

			const key = fileName.toLowerCase();
			const group = await this._cache[ key ];
			return group.clone();

		} else {

			return null;

		}

	}

	// Loads and parses the model with the given file name. Returns a cached copy if available.
	async loadModel( fileName ) {

		const parseCache = this.parseCache;
		const key = fileName.toLowerCase();
		if ( this.hasCachedModel( fileName ) ) {

			// Return cached model if available.
			return this.getCachedModel( fileName );

		} else {

			// Otherwise parse a new model.
			// Ensure the file data is loaded and pre parsed.
			await parseCache.ensureDataLoaded( fileName );

			const info = parseCache.getData( fileName );
			const promise = this.processIntoMesh( info );

			// Now that the file has loaded it's possible that another part parse has been waiting in parallel
			// so check the cache again to see if it's been added since the last async operation so we don't
			// do unnecessary work.
			if ( this.hasCachedModel( fileName ) ) {

				return this.getCachedModel( fileName );

			}

			// Cache object if it's a part so it can be reused later.
			if ( isPartType( info.type ) ) {

				this._cache[ key ] = promise;

			}

			// return a copy
			const group = await promise;
			return group.clone();

		}

	}

	// parses the given model text into a renderable object. Returns cached copy if available.
	async parseModel( text ) {

		const parseCache = this.parseCache;
		const info = parseCache.parse( text );
		if ( isPartType( info.type ) && this.hasCachedModel( info.fileName ) ) {

			return this.getCachedModel( info.fileName );

		}

		return this.processIntoMesh( info );

	}

}