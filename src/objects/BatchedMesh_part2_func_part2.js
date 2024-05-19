setInstanceCountAt( id, instanceCount ) {

		if ( this._multiDrawInstances === null ) {

			this._multiDrawInstances = new Int32Array( this._maxGeometryCount ).fill( 1 );

		}

		this._multiDrawInstances[ id ] = instanceCount;

		return id;

	}
getBoundingBoxAt( id, target ) {

		const active = this._active;
		if ( active[ id ] === false ) {

			return null;

		}

		// compute bounding box
		const bound = this._bounds[ id ];
		const box = bound.box;
		const geometry = this.geometry;
		if ( bound.boxInitialized === false ) {

			box.makeEmpty();

			const index = geometry.index;
			const position = geometry.attributes.position;
			const drawRange = this._drawRanges[ id ];
			for ( let i = drawRange.start, l = drawRange.start + drawRange.count; i < l; i ++ ) {

				let iv = i;
				if ( index ) {

					iv = index.getX( iv );

				}

				box.expandByPoint( _vector.fromBufferAttribute( position, iv ) );

			}

			bound.boxInitialized = true;

		}

		target.copy( box );
		return target;

	}
getBoundingSphereAt( id, target ) {

		const active = this._active;
		if ( active[ id ] === false ) {

			return null;

		}

		// compute bounding sphere
		const bound = this._bounds[ id ];
		const sphere = bound.sphere;
		const geometry = this.geometry;
		if ( bound.sphereInitialized === false ) {

			sphere.makeEmpty();

			this.getBoundingBoxAt( id, _box );
			_box.getCenter( sphere.center );

			const index = geometry.index;
			const position = geometry.attributes.position;
			const drawRange = this._drawRanges[ id ];

			let maxRadiusSq = 0;
			for ( let i = drawRange.start, l = drawRange.start + drawRange.count; i < l; i ++ ) {

				let iv = i;
				if ( index ) {

					iv = index.getX( iv );

				}

				_vector.fromBufferAttribute( position, iv );
				maxRadiusSq = Math.max( maxRadiusSq, sphere.center.distanceToSquared( _vector ) );

			}

			sphere.radius = Math.sqrt( maxRadiusSq );
			bound.sphereInitialized = true;

		}

		target.copy( sphere );
		return target;

	}
setMatrixAt( geometryId, matrix ) {

		// @TODO: Map geometryId to index of the arrays because
		//        optimize() can make geometryId mismatch the index

		const active = this._active;
		const matricesTexture = this._matricesTexture;
		const matricesArray = this._matricesTexture.image.data;
		const geometryCount = this._geometryCount;
		if ( geometryId >= geometryCount || active[ geometryId ] === false ) {

			return this;

		}

		matrix.toArray( matricesArray, geometryId * 16 );
		matricesTexture.needsUpdate = true;

		return this;

	}
getMatrixAt( geometryId, matrix ) {

		const active = this._active;
		const matricesArray = this._matricesTexture.image.data;
		const geometryCount = this._geometryCount;
		if ( geometryId >= geometryCount || active[ geometryId ] === false ) {

			return null;

		}

		return matrix.fromArray( matricesArray, geometryId * 16 );

	}
setColorAt( geometryId, color ) {

		if ( this._colorsTexture === null ) {

			this._initColorsTexture();

		}

		// @TODO: Map geometryId to index of the arrays because
		//        optimize() can make geometryId mismatch the index

		const active = this._active;
		const colorsTexture = this._colorsTexture;
		const colorsArray = this._colorsTexture.image.data;
		const geometryCount = this._geometryCount;
		if ( geometryId >= geometryCount || active[ geometryId ] === false ) {

			return this;

		}

		color.toArray( colorsArray, geometryId * 4 );
		colorsTexture.needsUpdate = true;

		return this;

	}
getColorAt( geometryId, color ) {

		const active = this._active;
		const colorsArray = this._colorsTexture.image.data;
		const geometryCount = this._geometryCount;
		if ( geometryId >= geometryCount || active[ geometryId ] === false ) {

			return null;

		}

		return color.fromArray( colorsArray, geometryId * 4 );

	}
setVisibleAt( geometryId, value ) {

		const visibility = this._visibility;
		const active = this._active;
		const geometryCount = this._geometryCount;

		// if the geometry is out of range, not active, or visibility state
		// does not change then return early
		if (
			geometryId >= geometryCount ||
			active[ geometryId ] === false ||
			visibility[ geometryId ] === value
		) {

			return this;

		}

		visibility[ geometryId ] = value;
		this._visibilityChanged = true;

		return this;

	}
getVisibleAt( geometryId ) {

		const visibility = this._visibility;
		const active = this._active;
		const geometryCount = this._geometryCount;

		// return early if the geometry is out of range or not active
		if ( geometryId >= geometryCount || active[ geometryId ] === false ) {

			return false;

		}

		return visibility[ geometryId ];

	}
raycast( raycaster, intersects ) {

		const visibility = this._visibility;
		const active = this._active;
		const drawRanges = this._drawRanges;
		const geometryCount = this._geometryCount;
		const matrixWorld = this.matrixWorld;
		const batchGeometry = this.geometry;

		// iterate over each geometry
		_mesh.material = this.material;
		_mesh.geometry.index = batchGeometry.index;
		_mesh.geometry.attributes = batchGeometry.attributes;
		if ( _mesh.geometry.boundingBox === null ) {

			_mesh.geometry.boundingBox = new Box3();

		}

		if ( _mesh.geometry.boundingSphere === null ) {

			_mesh.geometry.boundingSphere = new Sphere();

		}

		for ( let i = 0; i < geometryCount; i ++ ) {

			if ( ! visibility[ i ] || ! active[ i ] ) {

				continue;

			}

			const drawRange = drawRanges[ i ];
			_mesh.geometry.setDrawRange( drawRange.start, drawRange.count );

			// ge the intersects
			this.getMatrixAt( i, _mesh.matrixWorld ).premultiply( matrixWorld );
			this.getBoundingBoxAt( i, _mesh.geometry.boundingBox );
			this.getBoundingSphereAt( i, _mesh.geometry.boundingSphere );
			_mesh.raycast( raycaster, _batchIntersects );

			// add batch id to the intersects
			for ( let j = 0, l = _batchIntersects.length; j < l; j ++ ) {

				const intersect = _batchIntersects[ j ];
				intersect.object = this;
				intersect.batchId = i;
				intersects.push( intersect );

			}

			_batchIntersects.length = 0;

		}

		_mesh.material = null;
		_mesh.geometry.index = null;
		_mesh.geometry.attributes = {};
		_mesh.geometry.setDrawRange( 0, Infinity );

	}
copy( source ) {

		super.copy( source );

		this.geometry = source.geometry.clone();
		this.perObjectFrustumCulled = source.perObjectFrustumCulled;
		this.sortObjects = source.sortObjects;
		this.boundingBox = source.boundingBox !== null ? source.boundingBox.clone() : null;
		this.boundingSphere = source.boundingSphere !== null ? source.boundingSphere.clone() : null;

		this._drawRanges = source._drawRanges.map( range => ( { ...range } ) );
		this._reservedRanges = source._reservedRanges.map( range => ( { ...range } ) );

		this._visibility = source._visibility.slice();
		this._active = source._active.slice();
		this._bounds = source._bounds.map( bound => ( {
			boxInitialized: bound.boxInitialized,
			box: bound.box.clone(),

			sphereInitialized: bound.sphereInitialized,
			sphere: bound.sphere.clone()
		} ) );

		this._maxGeometryCount = source._maxGeometryCount;
		this._maxVertexCount = source._maxVertexCount;
		this._maxIndexCount = source._maxIndexCount;

		this._geometryInitialized = source._geometryInitialized;
		this._geometryCount = source._geometryCount;
		this._multiDrawCounts = source._multiDrawCounts.slice();
		this._multiDrawStarts = source._multiDrawStarts.slice();

		this._matricesTexture = source._matricesTexture.clone();
		this._matricesTexture.image.data = this._matricesTexture.image.slice();

		if ( this._colorsTexture !== null ) {

			this._colorsTexture = source._colorsTexture.clone();
			this._colorsTexture.image.data = this._colorsTexture.image.slice();

		}

		return this;

	}
dispose() {

		// Assuming the geometry is not shared with other meshes
		this.geometry.dispose();

		this._matricesTexture.dispose();
		this._matricesTexture = null;

		if ( this._colorsTexture !== null ) {

			this._colorsTexture.dispose();
			this._colorsTexture = null;

		}

		return this;

	}
onBeforeRender( renderer, scene, camera, geometry, material/*, _group*/ ) {

		// if visibility has not changed and frustum culling and object sorting is not required
		// then skip iterating over all items
		if ( ! this._visibilityChanged && ! this.perObjectFrustumCulled && ! this.sortObjects ) {

			return;

		}

		// the indexed version of the multi draw function requires specifying the start
		// offset in bytes.
		const index = geometry.getIndex();
		const bytesPerElement = index === null ? 1 : index.array.BYTES_PER_ELEMENT;

		const active = this._active;
		const visibility = this._visibility;
		const multiDrawStarts = this._multiDrawStarts;
		const multiDrawCounts = this._multiDrawCounts;
		const drawRanges = this._drawRanges;
		const perObjectFrustumCulled = this.perObjectFrustumCulled;

		// prepare the frustum in the local frame
		if ( perObjectFrustumCulled ) {

			_projScreenMatrix
				.multiplyMatrices( camera.projectionMatrix, camera.matrixWorldInverse )
				.multiply( this.matrixWorld );
			_frustum.setFromProjectionMatrix(
				_projScreenMatrix,
				renderer.coordinateSystem
			);

		}

		let count = 0;
		if ( this.sortObjects ) {

			// get the camera position in the local frame
			_invMatrixWorld.copy( this.matrixWorld ).invert();
			_vector.setFromMatrixPosition( camera.matrixWorld ).applyMatrix4( _invMatrixWorld );

			for ( let i = 0, l = visibility.length; i < l; i ++ ) {

				if ( visibility[ i ] && active[ i ] ) {

					// get the bounds in world space
					this.getMatrixAt( i, _matrix );
					this.getBoundingSphereAt( i, _sphere ).applyMatrix4( _matrix );

					// determine whether the batched geometry is within the frustum
					let culled = false;
					if ( perObjectFrustumCulled ) {

						culled = ! _frustum.intersectsSphere( _sphere );

					}

					if ( ! culled ) {

						// get the distance from camera used for sorting
						const z = _vector.distanceTo( _sphere.center );
						_renderList.push( drawRanges[ i ], z );

					}

				}

			}

			// Sort the draw ranges and prep for rendering
			const list = _renderList.list;
			const customSort = this.customSort;
			if ( customSort === null ) {

				list.sort( material.transparent ? sortTransparent : sortOpaque );

			} else {

				customSort.call( this, list, camera );

			}

			for ( let i = 0, l = list.length; i < l; i ++ ) {

				const item = list[ i ];
				multiDrawStarts[ count ] = item.start * bytesPerElement;
				multiDrawCounts[ count ] = item.count;
				count ++;

			}

			_renderList.reset();

		} else {

			for ( let i = 0, l = visibility.length; i < l; i ++ ) {

				if ( visibility[ i ] && active[ i ] ) {

					// determine whether the batched geometry is within the frustum
					let culled = false;
					if ( perObjectFrustumCulled ) {

						// get the bounds in world space
						this.getMatrixAt( i, _matrix );
						this.getBoundingSphereAt( i, _sphere ).applyMatrix4( _matrix );
						culled = ! _frustum.intersectsSphere( _sphere );

					}

					if ( ! culled ) {

						const range = drawRanges[ i ];
						multiDrawStarts[ count ] = range.start * bytesPerElement;
						multiDrawCounts[ count ] = range.count;
						count ++;

					}

				}

			}

		}

		this._multiDrawCount = count;
		this._visibilityChanged = false;

	}
onBeforeShadow( renderer, object, camera, shadowCamera, geometry, depthMaterial/* , group */ ) {

		this.onBeforeRender( renderer, null, shadowCamera, geometry, depthMaterial );

	}


}