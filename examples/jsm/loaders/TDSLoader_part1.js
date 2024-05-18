class TDSLoader extends Loader {

	constructor( manager ) {

		super( manager );

		this.debug = false;

		this.group = null;

		this.materials = [];
		this.meshes = [];

	}

	/**
	 * Load 3ds file from url.
	 *
	 * @method load
	 * @param {[type]} url URL for the file.
	 * @param {Function} onLoad onLoad callback, receives group Object3D as argument.
	 * @param {Function} onProgress onProgress callback.
	 * @param {Function} onError onError callback.
	 */
	load( url, onLoad, onProgress, onError ) {

		const scope = this;

		const path = ( this.path === '' ) ? LoaderUtils.extractUrlBase( url ) : this.path;

		const loader = new FileLoader( this.manager );
		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( this.requestHeader );
		loader.setWithCredentials( this.withCredentials );

		loader.load( url, function ( data ) {

			try {

				onLoad( scope.parse( data, path ) );

			} catch ( e ) {

				if ( onError ) {

					onError( e );

				} else {

					console.error( e );

				}

				scope.manager.itemError( url );

			}

		}, onProgress, onError );

	}

	/**
	 * Parse arraybuffer data and load 3ds file.
	 *
	 * @method parse
	 * @param {ArrayBuffer} arraybuffer Arraybuffer data to be loaded.
	 * @param {String} path Path for external resources.
	 * @return {Group} Group loaded from 3ds file.
	 */
	parse( arraybuffer, path ) {

		this.group = new Group();
		this.materials = [];
		this.meshes = [];

		this.readFile( arraybuffer, path );

		for ( let i = 0; i < this.meshes.length; i ++ ) {

			this.group.add( this.meshes[ i ] );

		}

		return this.group;

	}

	/**
	 * Decode file content to read 3ds data.
	 *
	 * @method readFile
	 * @param {ArrayBuffer} arraybuffer Arraybuffer data to be loaded.
	 * @param {String} path Path for external resources.
	 */
	readFile( arraybuffer, path ) {

		const data = new DataView( arraybuffer );
		const chunk = new Chunk( data, 0, this.debugMessage );

		if ( chunk.id === MLIBMAGIC || chunk.id === CMAGIC || chunk.id === M3DMAGIC ) {

			let next = chunk.readChunk();

			while ( next ) {

				if ( next.id === M3D_VERSION ) {

					const version = next.readDWord();
					this.debugMessage( '3DS file version: ' + version );

				} else if ( next.id === MDATA ) {

					this.readMeshData( next, path );

				} else {

					this.debugMessage( 'Unknown main chunk: ' + next.hexId );

				}

				next = chunk.readChunk();

			}

		}

		this.debugMessage( 'Parsed ' + this.meshes.length + ' meshes' );

	}

	/**
	 * Read mesh data chunk.
	 *
	 * @method readMeshData
	 * @param {Chunk} chunk to read mesh from
	 * @param {String} path Path for external resources.
	 */
	readMeshData( chunk, path ) {

		let next = chunk.readChunk();

		while ( next ) {

			if ( next.id === MESH_VERSION ) {

				const version = + next.readDWord();
				this.debugMessage( 'Mesh Version: ' + version );

			} else if ( next.id === MASTER_SCALE ) {

				const scale = next.readFloat();
				this.debugMessage( 'Master scale: ' + scale );
				this.group.scale.set( scale, scale, scale );

			} else if ( next.id === NAMED_OBJECT ) {

				this.debugMessage( 'Named Object' );
				this.readNamedObject( next );

			} else if ( next.id === MAT_ENTRY ) {

				this.debugMessage( 'Material' );
				this.readMaterialEntry( next, path );

			} else {

				this.debugMessage( 'Unknown MDATA chunk: ' + next.hexId );

			}

			next = chunk.readChunk();

		}

	}

	/**
	 * Read named object chunk.
	 *
	 * @method readNamedObject
	 * @param {Chunk} chunk Chunk in use.
	 */
	readNamedObject( chunk ) {

		const name = chunk.readString();

		let next = chunk.readChunk();
		while ( next ) {

			if ( next.id === N_TRI_OBJECT ) {

				const mesh = this.readMesh( next );
				mesh.name = name;
				this.meshes.push( mesh );

			} else {

				this.debugMessage( 'Unknown named object chunk: ' + next.hexId );

			}

			next = chunk.readChunk( );

		}

	}

	/**
	 * Read material data chunk and add it to the material list.
	 *
	 * @method readMaterialEntry
	 * @param {Chunk} chunk Chunk in use.
	 * @param {String} path Path for external resources.
	 */
	readMaterialEntry( chunk, path ) {

		let next = chunk.readChunk();
		const material = new MeshPhongMaterial();

		while ( next ) {

			if ( next.id === MAT_NAME ) {

				material.name = next.readString();
				this.debugMessage( '   Name: ' + material.name );

			} else if ( next.id === MAT_WIRE ) {

				this.debugMessage( '   Wireframe' );
				material.wireframe = true;

			} else if ( next.id === MAT_WIRE_SIZE ) {

				const value = next.readByte();
				material.wireframeLinewidth = value;
				this.debugMessage( '   Wireframe Thickness: ' + value );

			} else if ( next.id === MAT_TWO_SIDE ) {

				material.side = DoubleSide;
				this.debugMessage( '   DoubleSided' );

			} else if ( next.id === MAT_ADDITIVE ) {

				this.debugMessage( '   Additive Blending' );
				material.blending = AdditiveBlending;

			} else if ( next.id === MAT_DIFFUSE ) {

				this.debugMessage( '   Diffuse Color' );
				material.color = this.readColor( next );

			} else if ( next.id === MAT_SPECULAR ) {

				this.debugMessage( '   Specular Color' );
				material.specular = this.readColor( next );

			} else if ( next.id === MAT_AMBIENT ) {

				this.debugMessage( '   Ambient color' );
				material.color = this.readColor( next );

			} else if ( next.id === MAT_SHININESS ) {

				const shininess = this.readPercentage( next );
				material.shininess = shininess * 100;
				this.debugMessage( '   Shininess : ' + shininess );

			} else if ( next.id === MAT_TRANSPARENCY ) {

				const transparency = this.readPercentage( next );
				material.opacity = 1 - transparency;
				this.debugMessage( '  Transparency : ' + transparency );
				material.transparent = material.opacity < 1 ? true : false;

			} else if ( next.id === MAT_TEXMAP ) {

				this.debugMessage( '   ColorMap' );
				material.map = this.readMap( next, path );

			} else if ( next.id === MAT_BUMPMAP ) {

				this.debugMessage( '   BumpMap' );
				material.bumpMap = this.readMap( next, path );

			} else if ( next.id === MAT_OPACMAP ) {

				this.debugMessage( '   OpacityMap' );
				material.alphaMap = this.readMap( next, path );

			} else if ( next.id === MAT_SPECMAP ) {

				this.debugMessage( '   SpecularMap' );
				material.specularMap = this.readMap( next, path );

			} else {

				this.debugMessage( '   Unknown material chunk: ' + next.hexId );

			}

			next = chunk.readChunk();

		}

		this.materials[ material.name ] = material;

	}

	/**
	 * Read mesh data chunk.
	 *
	 * @method readMesh
	 * @param {Chunk} chunk Chunk in use.
	 * @return {Mesh} The parsed mesh.
	 */
	readMesh( chunk ) {

		let next = chunk.readChunk( );

		const geometry = new BufferGeometry();

		const material = new MeshPhongMaterial();
		const mesh = new Mesh( geometry, material );
		mesh.name = 'mesh';

		while ( next ) {

			if ( next.id === POINT_ARRAY ) {

				const points = next.readWord( );

				this.debugMessage( '   Vertex: ' + points );

				//BufferGeometry

				const vertices = [];

				for ( let i = 0; i < points; i ++ )		{

					vertices.push( next.readFloat( ) );
					vertices.push( next.readFloat( ) );
					vertices.push( next.readFloat( ) );

				}

				geometry.setAttribute( 'position', new Float32BufferAttribute( vertices, 3 ) );

			} else if ( next.id === FACE_ARRAY ) {

				this.readFaceArray( next, mesh );

			} else if ( next.id === TEX_VERTS ) {

				const texels = next.readWord( );

				this.debugMessage( '   UV: ' + texels );

				//BufferGeometry

				const uvs = [];

				for ( let i = 0; i < texels; i ++ ) {

					uvs.push( next.readFloat( ) );
					uvs.push( next.readFloat( ) );

				}

				geometry.setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );


			} else if ( next.id === MESH_MATRIX ) {

				this.debugMessage( '   Tranformation Matrix (TODO)' );

				const values = [];
				for ( let i = 0; i < 12; i ++ ) {

					values[ i ] = next.readFloat( );

				}

				const matrix = new Matrix4();

				//X Line
				matrix.elements[ 0 ] = values[ 0 ];
				matrix.elements[ 1 ] = values[ 6 ];
				matrix.elements[ 2 ] = values[ 3 ];
				matrix.elements[ 3 ] = values[ 9 ];

				//Y Line
				matrix.elements[ 4 ] = values[ 2 ];
				matrix.elements[ 5 ] = values[ 8 ];
				matrix.elements[ 6 ] = values[ 5 ];
				matrix.elements[ 7 ] = values[ 11 ];

				//Z Line
				matrix.elements[ 8 ] = values[ 1 ];
				matrix.elements[ 9 ] = values[ 7 ];
				matrix.elements[ 10 ] = values[ 4 ];
				matrix.elements[ 11 ] = values[ 10 ];

				//W Line
				matrix.elements[ 12 ] = 0;
				matrix.elements[ 13 ] = 0;
				matrix.elements[ 14 ] = 0;
				matrix.elements[ 15 ] = 1;

				matrix.transpose();

				const inverse = new Matrix4();
				inverse.copy( matrix ).invert();
				geometry.applyMatrix4( inverse );

				matrix.decompose( mesh.position, mesh.quaternion, mesh.scale );

			} else {

				this.debugMessage( '   Unknown mesh chunk: ' + next.hexId );

			}

			next = chunk.readChunk( );

		}

		geometry.computeVertexNormals();

		return mesh;

	}

	/**
	 * Read face array data chunk.
	 *
	 * @method readFaceArray
	 * @param {Chunk} chunk Chunk in use.
	 * @param {Mesh} mesh Mesh to be filled with the data read.
	 */
	readFaceArray( chunk, mesh ) {

		const faces = chunk.readWord( );

		this.debugMessage( '   Faces: ' + faces );

		const index = [];

		for ( let i = 0; i < faces; ++ i ) {

			index.push( chunk.readWord( ), chunk.readWord( ), chunk.readWord( ) );

			chunk.readWord( ); // visibility

		}

		mesh.geometry.setIndex( index );

		//The rest of the FACE_ARRAY chunk is subchunks

		let materialIndex = 0;
		let start = 0;

		while ( ! chunk.endOfChunk ) {

			const subchunk = chunk.readChunk( );

			if ( subchunk.id === MSH_MAT_GROUP ) {

				this.debugMessage( '      Material Group' );

				const group = this.readMaterialGroup( subchunk );
				const count = group.index.length * 3; // assuming successive indices

				mesh.geometry.addGroup( start, count, materialIndex );

				start += count;
				materialIndex ++;

				const material = this.materials[ group.name ];

				if ( Array.isArray( mesh.material ) === false ) mesh.material = [];

				if ( material !== undefined )	{

					mesh.material.push( material );

				}

			} else {

				this.debugMessage( '      Unknown face array chunk: ' + subchunk.hexId );

			}

		}

		if ( mesh.material.length === 1 ) mesh.material = mesh.material[ 0 ]; // for backwards compatibility

	}

	/**
	 * Read texture map data chunk.
	 *
	 * @method readMap
	 * @param {Chunk} chunk Chunk in use.
	 * @param {String} path Path for external resources.
	 * @return {Texture} Texture read from this data chunk.
	 */
	readMap( chunk, path ) {

		let next = chunk.readChunk( );
		let texture = {};

		const loader = new TextureLoader( this.manager );
		loader.setPath( this.resourcePath || path ).setCrossOrigin( this.crossOrigin );

		while ( next ) {

			if ( next.id === MAT_MAPNAME ) {

				const name = next.readString();
				texture = loader.load( name );

				this.debugMessage( '      File: ' + path + name );

			} else if ( next.id === MAT_MAP_UOFFSET ) {

				texture.offset.x = next.readFloat( );
				this.debugMessage( '      OffsetX: ' + texture.offset.x );

			} else if ( next.id === MAT_MAP_VOFFSET ) {

				texture.offset.y = next.readFloat( );
				this.debugMessage( '      OffsetY: ' + texture.offset.y );

			} else if ( next.id === MAT_MAP_USCALE ) {

				texture.repeat.x = next.readFloat( );
				this.debugMessage( '      RepeatX: ' + texture.repeat.x );

			} else if ( next.id === MAT_MAP_VSCALE ) {

				texture.repeat.y = next.readFloat( );
				this.debugMessage( '      RepeatY: ' + texture.repeat.y );

			} else {

				this.debugMessage( '      Unknown map chunk: ' + next.hexId );

			}

			next = chunk.readChunk( );

		}

		return texture;

	}

	/**
	 * Read material group data chunk.
	 *
	 * @method readMaterialGroup
	 * @param {Chunk} chunk Chunk in use.
	 * @return {Object} Object with name and index of the object.
	 */
	readMaterialGroup( chunk ) {

		const name = chunk.readString();
		const numFaces = chunk.readWord();

		this.debugMessage( '         Name: ' + name );
		this.debugMessage( '         Faces: ' + numFaces );

		const index = [];
		for ( let i = 0; i < numFaces; ++ i ) {

			index.push( chunk.readWord( ) );

		}

		return { name: name, index: index };

	}

	/**
	 * Read a color value.
	 *
	 * @method readColor
	 * @param {Chunk} chunk Chunk.
	 * @return {Color} Color value read..
	 */
	readColor( chunk ) {

		const subChunk = chunk.readChunk( );
		const color = new Color();

		if ( subChunk.id === COLOR_24 || subChunk.id === LIN_COLOR_24 ) {

			const r = subChunk.readByte( );
			const g = subChunk.readByte( );
			const b = subChunk.readByte( );

			color.setRGB( r / 255, g / 255, b / 255 );

			this.debugMessage( '      Color: ' + color.r + ', ' + color.g + ', ' + color.b );

		}	else if ( subChunk.id === COLOR_F || subChunk.id === LIN_COLOR_F ) {

			const r = subChunk.readFloat( );
			const g = subChunk.readFloat( );
			const b = subChunk.readFloat( );

			color.setRGB( r, g, b );

			this.debugMessage( '      Color: ' + color.r + ', ' + color.g + ', ' + color.b );

		}	else {

			this.debugMessage( '      Unknown color chunk: ' + subChunk.hexId );

		}

		return color;

	}

	/**
	 * Read percentage value.
	 *
	 * @method readPercentage
	 * @param {Chunk} chunk Chunk to read data from.
	 * @return {Number} Data read from the dataview.
	 */
	readPercentage( chunk ) {

		const subChunk = chunk.readChunk( );

		switch ( subChunk.id ) {

			case INT_PERCENTAGE:
				return ( subChunk.readShort( ) / 100 );
				break;

			case FLOAT_PERCENTAGE:
				return subChunk.readFloat( );
				break;

			default:
				this.debugMessage( '      Unknown percentage chunk: ' + subChunk.hexId );
				return 0;

		}

	}

	/**
	 * Print debug message to the console.
	 *
	 * Is controlled by a flag to show or hide debug messages.
	 *
	 * @method debugMessage
	 * @param {Object} message Debug message to print to the console.
	 */
	debugMessage( message ) {

		if ( this.debug ) {

			console.log( message );

		}

	}

}