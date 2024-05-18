class LWOTreeParser {

	constructor( textureLoader ) {

		this.textureLoader = textureLoader;

	}

	parse( modelName ) {

		this.materials = new MaterialParser( this.textureLoader ).parse();
		this.defaultLayerName = modelName;

		this.meshes = this.parseLayers();

		return {
			materials: this.materials,
			meshes: this.meshes,
		};

	}

	parseLayers() {

		// array of all meshes for building hierarchy
		const meshes = [];

		// final array containing meshes with scene graph hierarchy set up
		const finalMeshes = [];

		const geometryParser = new GeometryParser();

		const scope = this;
		_lwoTree.layers.forEach( function ( layer ) {

			const geometry = geometryParser.parse( layer.geometry, layer );

			const mesh = scope.parseMesh( geometry, layer );

			meshes[ layer.number ] = mesh;

			if ( layer.parent === - 1 ) finalMeshes.push( mesh );
			else meshes[ layer.parent ].add( mesh );


		} );

		this.applyPivots( finalMeshes );

		return finalMeshes;

	}

	parseMesh( geometry, layer ) {

		let mesh;

		const materials = this.getMaterials( geometry.userData.matNames, layer.geometry.type );

		if ( layer.geometry.type === 'points' ) mesh = new Points( geometry, materials );
		else if ( layer.geometry.type === 'lines' ) mesh = new LineSegments( geometry, materials );
		else mesh = new Mesh( geometry, materials );

		if ( layer.name ) mesh.name = layer.name;
		else mesh.name = this.defaultLayerName + '_layer_' + layer.number;

		mesh.userData.pivot = layer.pivot;

		return mesh;

	}

	// TODO: may need to be reversed in z to convert LWO to three.js coordinates
	applyPivots( meshes ) {

		meshes.forEach( function ( mesh ) {

			mesh.traverse( function ( child ) {

				const pivot = child.userData.pivot;

				child.position.x += pivot[ 0 ];
				child.position.y += pivot[ 1 ];
				child.position.z += pivot[ 2 ];

				if ( child.parent ) {

					const parentPivot = child.parent.userData.pivot;

					child.position.x -= parentPivot[ 0 ];
					child.position.y -= parentPivot[ 1 ];
					child.position.z -= parentPivot[ 2 ];

				}

			} );

		} );

	}

	getMaterials( namesArray, type ) {

		const materials = [];

		const scope = this;

		namesArray.forEach( function ( name, i ) {

			materials[ i ] = scope.getMaterialByName( name );

		} );

		// convert materials to line or point mats if required
		if ( type === 'points' || type === 'lines' ) {

			materials.forEach( function ( mat, i ) {

				const spec = {
					color: mat.color,
				};

				if ( type === 'points' ) {

					spec.size = 0.1;
					spec.map = mat.map;
					materials[ i ] = new PointsMaterial( spec );

				} else if ( type === 'lines' ) {

					materials[ i ] = new LineBasicMaterial( spec );

				}

			} );

		}

		// if there is only one material, return that directly instead of array
		const filtered = materials.filter( Boolean );
		if ( filtered.length === 1 ) return filtered[ 0 ];

		return materials;

	}

	getMaterialByName( name ) {

		return this.materials.filter( function ( m ) {

			return m.name === name;

		} )[ 0 ];

	}

}