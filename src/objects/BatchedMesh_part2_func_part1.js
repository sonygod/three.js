class BatchedMesh extends Mesh {

	get maxGeometryCount() {

		return this._maxGeometryCount;

	}

	constructor( maxGeometryCount, maxVertexCount, maxIndexCount = maxVertexCount * 2, material ) {

		super( new BufferGeometry(), material );

		this.isBatchedMesh = true;
		this.perObjectFrustumCulled = true;
		this.sortObjects = true;
		this.boundingBox = null;
		this.boundingSphere = null;
		this.customSort = null;

		this._drawRanges = [];
		this._reservedRanges = [];

		this._visibility = [];
		this._active = [];
		this._bounds = [];

		this._maxGeometryCount = maxGeometryCount;
		this._maxVertexCount = maxVertexCount;
		this._maxIndexCount = maxIndexCount;

		this._geometryInitialized = false;
		this._geometryCount = 0;
		this._multiDrawCounts = new Int32Array( maxGeometryCount );
		this._multiDrawStarts = new Int32Array( maxGeometryCount );
		this._multiDrawCount = 0;
		this._multiDrawInstances = null;
		this._visibilityChanged = true;

		// Local matrix per geometry by using data texture
		this._matricesTexture = null;

		this._initMatricesTexture();

		// Local color per geometry by using data texture
		this._colorsTexture = null;

	}
_initMatricesTexture() {

		// layout (1 matrix = 4 pixels)
		//      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
		//  with  8x8  pixel texture max   16 matrices * 4 pixels =  (8 * 8)
		//       16x16 pixel texture max   64 matrices * 4 pixels = (16 * 16)
		//       32x32 pixel texture max  256 matrices * 4 pixels = (32 * 32)
		//       64x64 pixel texture max 1024 matrices * 4 pixels = (64 * 64)

		let size = Math.sqrt( this._maxGeometryCount * 4 ); // 4 pixels needed for 1 matrix
		size = Math.ceil( size / 4 ) * 4;
		size = Math.max( size, 4 );

		const matricesArray = new Float32Array( size * size * 4 ); // 4 floats per RGBA pixel
		const matricesTexture = new DataTexture( matricesArray, size, size, RGBAFormat, FloatType );

		this._matricesTexture = matricesTexture;

	}
_initColorsTexture() {

		let size = Math.sqrt( this._maxGeometryCount );
		size = Math.ceil( size );

		const colorsArray = new Float32Array( size * size * 4 ); // 4 floats per RGBA pixel
		const colorsTexture = new DataTexture( colorsArray, size, size, RGBAFormat, FloatType );
		colorsTexture.colorSpace = ColorManagement.workingColorSpace;

		this._colorsTexture = colorsTexture;

	}
_initializeGeometry( reference ) {

		const geometry = this.geometry;
		const maxVertexCount = this._maxVertexCount;
		const maxGeometryCount = this._maxGeometryCount;
		const maxIndexCount = this._maxIndexCount;
		if ( this._geometryInitialized === false ) {

			for ( const attributeName in reference.attributes ) {

				const srcAttribute = reference.getAttribute( attributeName );
				const { array, itemSize, normalized } = srcAttribute;

				const dstArray = new array.constructor( maxVertexCount * itemSize );
				const dstAttribute = new BufferAttribute( dstArray, itemSize, normalized );

				geometry.setAttribute( attributeName, dstAttribute );

			}

			if ( reference.getIndex() !== null ) {

				const indexArray = maxVertexCount > 65536
					? new Uint32Array( maxIndexCount )
					: new Uint16Array( maxIndexCount );

				geometry.setIndex( new BufferAttribute( indexArray, 1 ) );

			}

			const idArray = maxGeometryCount > 65536
				? new Uint32Array( maxVertexCount )
				: new Uint16Array( maxVertexCount );
			geometry.setAttribute( ID_ATTR_NAME, new BufferAttribute( idArray, 1 ) );

			this._geometryInitialized = true;

		}

	}
_validateGeometry( geometry ) {

		// check that the geometry doesn't have a version of our reserved id attribute
		if ( geometry.getAttribute( ID_ATTR_NAME ) ) {

			throw new Error( `BatchedMesh: Geometry cannot use attribute "${ ID_ATTR_NAME }"` );

		}

		// check to ensure the geometries are using consistent attributes and indices
		const batchGeometry = this.geometry;
		if ( Boolean( geometry.getIndex() ) !== Boolean( batchGeometry.getIndex() ) ) {

			throw new Error( 'BatchedMesh: All geometries must consistently have "index".' );

		}

		for ( const attributeName in batchGeometry.attributes ) {

			if ( attributeName === ID_ATTR_NAME ) {

				continue;

			}

			if ( ! geometry.hasAttribute( attributeName ) ) {

				throw new Error( `BatchedMesh: Added geometry missing "${ attributeName }". All geometries must have consistent attributes.` );

			}

			const srcAttribute = geometry.getAttribute( attributeName );
			const dstAttribute = batchGeometry.getAttribute( attributeName );
			if ( srcAttribute.itemSize !== dstAttribute.itemSize || srcAttribute.normalized !== dstAttribute.normalized ) {

				throw new Error( 'BatchedMesh: All attributes must have a consistent itemSize and normalized value.' );

			}

		}

	}
setCustomSort( func ) {

		this.customSort = func;
		return this;

	}
computeBoundingBox() {

		if ( this.boundingBox === null ) {

			this.boundingBox = new Box3();

		}

		const geometryCount = this._geometryCount;
		const boundingBox = this.boundingBox;
		const active = this._active;

		boundingBox.makeEmpty();
		for ( let i = 0; i < geometryCount; i ++ ) {

			if ( active[ i ] === false ) continue;

			this.getMatrixAt( i, _matrix );
			this.getBoundingBoxAt( i, _box ).applyMatrix4( _matrix );
			boundingBox.union( _box );

		}

	}
computeBoundingSphere() {

		if ( this.boundingSphere === null ) {

			this.boundingSphere = new Sphere();

		}

		const geometryCount = this._geometryCount;
		const boundingSphere = this.boundingSphere;
		const active = this._active;

		boundingSphere.makeEmpty();
		for ( let i = 0; i < geometryCount; i ++ ) {

			if ( active[ i ] === false ) continue;

			this.getMatrixAt( i, _matrix );
			this.getBoundingSphereAt( i, _sphere ).applyMatrix4( _matrix );
			boundingSphere.union( _sphere );

		}

	}
addGeometry( geometry, vertexCount = - 1, indexCount = - 1 ) {

		this._initializeGeometry( geometry );

		this._validateGeometry( geometry );

		// ensure we're not over geometry
		if ( this._geometryCount >= this._maxGeometryCount ) {

			throw new Error( 'BatchedMesh: Maximum geometry count reached.' );

		}

		// get the necessary range fo the geometry
		const reservedRange = {
			vertexStart: - 1,
			vertexCount: - 1,
			indexStart: - 1,
			indexCount: - 1,
		};

		let lastRange = null;
		const reservedRanges = this._reservedRanges;
		const drawRanges = this._drawRanges;
		const bounds = this._bounds;
		if ( this._geometryCount !== 0 ) {

			lastRange = reservedRanges[ reservedRanges.length - 1 ];

		}

		if ( vertexCount === - 1 ) {

			reservedRange.vertexCount = geometry.getAttribute( 'position' ).count;

		} else {

			reservedRange.vertexCount = vertexCount;

		}

		if ( lastRange === null ) {

			reservedRange.vertexStart = 0;

		} else {

			reservedRange.vertexStart = lastRange.vertexStart + lastRange.vertexCount;

		}

		const index = geometry.getIndex();
		const hasIndex = index !== null;
		if ( hasIndex ) {

			if ( indexCount	=== - 1 ) {

				reservedRange.indexCount = index.count;

			} else {

				reservedRange.indexCount = indexCount;

			}

			if ( lastRange === null ) {

				reservedRange.indexStart = 0;

			} else {

				reservedRange.indexStart = lastRange.indexStart + lastRange.indexCount;

			}

		}

		if (
			reservedRange.indexStart !== - 1 &&
			reservedRange.indexStart + reservedRange.indexCount > this._maxIndexCount ||
			reservedRange.vertexStart + reservedRange.vertexCount > this._maxVertexCount
		) {

			throw new Error( 'BatchedMesh: Reserved space request exceeds the maximum buffer size.' );

		}

		const visibility = this._visibility;
		const active = this._active;
		const matricesTexture = this._matricesTexture;
		const matricesArray = this._matricesTexture.image.data;

		// push new visibility states
		visibility.push( true );
		active.push( true );

		// update id
		const geometryId = this._geometryCount;
		this._geometryCount ++;

		// initialize matrix information
		_identityMatrix.toArray( matricesArray, geometryId * 16 );
		matricesTexture.needsUpdate = true;

		// add the reserved range and draw range objects
		reservedRanges.push( reservedRange );
		drawRanges.push( {
			start: hasIndex ? reservedRange.indexStart : reservedRange.vertexStart,
			count: - 1
		} );
		bounds.push( {
			boxInitialized: false,
			box: new Box3(),

			sphereInitialized: false,
			sphere: new Sphere()
		} );

		// set the id for the geometry
		const idAttribute = this.geometry.getAttribute( ID_ATTR_NAME );
		for ( let i = 0; i < reservedRange.vertexCount; i ++ ) {

			idAttribute.setX( reservedRange.vertexStart + i, geometryId );

		}

		idAttribute.needsUpdate = true;

		// update the geometry
		this.setGeometryAt( geometryId, geometry );

		return geometryId;

	}
setGeometryAt( id, geometry ) {

		if ( id >= this._geometryCount ) {

			throw new Error( 'BatchedMesh: Maximum geometry count reached.' );

		}

		this._validateGeometry( geometry );

		const batchGeometry = this.geometry;
		const hasIndex = batchGeometry.getIndex() !== null;
		const dstIndex = batchGeometry.getIndex();
		const srcIndex = geometry.getIndex();
		const reservedRange = this._reservedRanges[ id ];
		if (
			hasIndex &&
			srcIndex.count > reservedRange.indexCount ||
			geometry.attributes.position.count > reservedRange.vertexCount
		) {

			throw new Error( 'BatchedMesh: Reserved space not large enough for provided geometry.' );

		}

		// copy geometry over
		const vertexStart = reservedRange.vertexStart;
		const vertexCount = reservedRange.vertexCount;
		for ( const attributeName in batchGeometry.attributes ) {

			if ( attributeName === ID_ATTR_NAME ) {

				continue;

			}

			// copy attribute data
			const srcAttribute = geometry.getAttribute( attributeName );
			const dstAttribute = batchGeometry.getAttribute( attributeName );
			copyAttributeData( srcAttribute, dstAttribute, vertexStart );

			// fill the rest in with zeroes
			const itemSize = srcAttribute.itemSize;
			for ( let i = srcAttribute.count, l = vertexCount; i < l; i ++ ) {

				const index = vertexStart + i;
				for ( let c = 0; c < itemSize; c ++ ) {

					dstAttribute.setComponent( index, c, 0 );

				}

			}

			dstAttribute.needsUpdate = true;
			dstAttribute.addUpdateRange( vertexStart * itemSize, vertexCount * itemSize );

		}

		// copy index
		if ( hasIndex ) {

			const indexStart = reservedRange.indexStart;

			// copy index data over
			for ( let i = 0; i < srcIndex.count; i ++ ) {

				dstIndex.setX( indexStart + i, vertexStart + srcIndex.getX( i ) );

			}

			// fill the rest in with zeroes
			for ( let i = srcIndex.count, l = reservedRange.indexCount; i < l; i ++ ) {

				dstIndex.setX( indexStart + i, vertexStart );

			}

			dstIndex.needsUpdate = true;
			dstIndex.addUpdateRange( indexStart, reservedRange.indexCount );

		}

		// store the bounding boxes
		const bound = this._bounds[ id ];
		if ( geometry.boundingBox !== null ) {

			bound.box.copy( geometry.boundingBox );
			bound.boxInitialized = true;

		} else {

			bound.boxInitialized = false;

		}

		if ( geometry.boundingSphere !== null ) {

			bound.sphere.copy( geometry.boundingSphere );
			bound.sphereInitialized = true;

		} else {

			bound.sphereInitialized = false;

		}

		// set drawRange count
		const drawRange = this._drawRanges[ id ];
		const posAttr = geometry.getAttribute( 'position' );
		drawRange.count = hasIndex ? srcIndex.count : posAttr.count;
		this._visibilityChanged = true;

		return id;

	}
deleteGeometry( geometryId ) {

		// Note: User needs to call optimize() afterward to pack the data.

		const active = this._active;
		if ( geometryId >= active.length || active[ geometryId ] === false ) {

			return this;

		}

		active[ geometryId ] = false;
		this._visibilityChanged = true;

		return this;

	}
getInstanceCountAt( id ) {

		if ( this._multiDrawInstances === null ) return null;

		return this._multiDrawInstances[ id ];

	}