class GLTFWriter {

	constructor() {

		this.plugins = [];

		this.options = {};
		this.pending = [];
		this.buffers = [];

		this.byteOffset = 0;
		this.buffers = [];
		this.nodeMap = new Map();
		this.skins = [];

		this.extensionsUsed = {};
		this.extensionsRequired = {};

		this.uids = new Map();
		this.uid = 0;

		this.json = {
			asset: {
				version: '2.0',
				generator: 'THREE.GLTFExporter r' + REVISION
			}
		};

		this.cache = {
			meshes: new Map(),
			attributes: new Map(),
			attributesNormalized: new Map(),
			materials: new Map(),
			textures: new Map(),
			images: new Map()
		};

	}
setPlugins( plugins ) {

		this.plugins = plugins;

	}
async write( input, onDone, options = {} ) {

		this.options = Object.assign( {
			// default options
			binary: false,
			trs: false,
			onlyVisible: true,
			maxTextureSize: Infinity,
			animations: [],
			includeCustomExtensions: false
		}, options );

		if ( this.options.animations.length > 0 ) {

			// Only TRS properties, and not matrices, may be targeted by animation.
			this.options.trs = true;

		}

		this.processInput( input );

		await Promise.all( this.pending );

		const writer = this;
		const buffers = writer.buffers;
		const json = writer.json;
		options = writer.options;

		const extensionsUsed = writer.extensionsUsed;
		const extensionsRequired = writer.extensionsRequired;

		// Merge buffers.
		const blob = new Blob( buffers, { type: 'application/octet-stream' } );

		// Declare extensions.
		const extensionsUsedList = Object.keys( extensionsUsed );
		const extensionsRequiredList = Object.keys( extensionsRequired );

		if ( extensionsUsedList.length > 0 ) json.extensionsUsed = extensionsUsedList;
		if ( extensionsRequiredList.length > 0 ) json.extensionsRequired = extensionsRequiredList;

		// Update bytelength of the single buffer.
		if ( json.buffers && json.buffers.length > 0 ) json.buffers[ 0 ].byteLength = blob.size;

		if ( options.binary === true ) {

			// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

			const reader = new FileReader();
			reader.readAsArrayBuffer( blob );
			reader.onloadend = function () {

				// Binary chunk.
				const binaryChunk = getPaddedArrayBuffer( reader.result );
				const binaryChunkPrefix = new DataView( new ArrayBuffer( GLB_CHUNK_PREFIX_BYTES ) );
				binaryChunkPrefix.setUint32( 0, binaryChunk.byteLength, true );
				binaryChunkPrefix.setUint32( 4, GLB_CHUNK_TYPE_BIN, true );

				// JSON chunk.
				const jsonChunk = getPaddedArrayBuffer( stringToArrayBuffer( JSON.stringify( json ) ), 0x20 );
				const jsonChunkPrefix = new DataView( new ArrayBuffer( GLB_CHUNK_PREFIX_BYTES ) );
				jsonChunkPrefix.setUint32( 0, jsonChunk.byteLength, true );
				jsonChunkPrefix.setUint32( 4, GLB_CHUNK_TYPE_JSON, true );

				// GLB header.
				const header = new ArrayBuffer( GLB_HEADER_BYTES );
				const headerView = new DataView( header );
				headerView.setUint32( 0, GLB_HEADER_MAGIC, true );
				headerView.setUint32( 4, GLB_VERSION, true );
				const totalByteLength = GLB_HEADER_BYTES
					+ jsonChunkPrefix.byteLength + jsonChunk.byteLength
					+ binaryChunkPrefix.byteLength + binaryChunk.byteLength;
				headerView.setUint32( 8, totalByteLength, true );

				const glbBlob = new Blob( [
					header,
					jsonChunkPrefix,
					jsonChunk,
					binaryChunkPrefix,
					binaryChunk
				], { type: 'application/octet-stream' } );

				const glbReader = new FileReader();
				glbReader.readAsArrayBuffer( glbBlob );
				glbReader.onloadend = function () {

					onDone( glbReader.result );

				};

			};

		} else {

			if ( json.buffers && json.buffers.length > 0 ) {

				const reader = new FileReader();
				reader.readAsDataURL( blob );
				reader.onloadend = function () {

					const base64data = reader.result;
					json.buffers[ 0 ].uri = base64data;
					onDone( json );

				};

			} else {

				onDone( json );

			}

		}


	}
serializeUserData( object, objectDef ) {

		if ( Object.keys( object.userData ).length === 0 ) return;

		const options = this.options;
		const extensionsUsed = this.extensionsUsed;

		try {

			const json = JSON.parse( JSON.stringify( object.userData ) );

			if ( options.includeCustomExtensions && json.gltfExtensions ) {

				if ( objectDef.extensions === undefined ) objectDef.extensions = {};

				for ( const extensionName in json.gltfExtensions ) {

					objectDef.extensions[ extensionName ] = json.gltfExtensions[ extensionName ];
					extensionsUsed[ extensionName ] = true;

				}

				delete json.gltfExtensions;

			}

			if ( Object.keys( json ).length > 0 ) objectDef.extras = json;

		} catch ( error ) {

			console.warn( 'THREE.GLTFExporter: userData of \'' + object.name + '\' ' +
				'won\'t be serialized because of JSON.stringify error - ' + error.message );

		}

	}
getUID( attribute, isRelativeCopy = false ) {

		if ( this.uids.has( attribute ) === false ) {

			const uids = new Map();

			uids.set( true, this.uid ++ );
			uids.set( false, this.uid ++ );

			this.uids.set( attribute, uids );

		}

		const uids = this.uids.get( attribute );

		return uids.get( isRelativeCopy );

	}
isNormalizedNormalAttribute( normal ) {

		const cache = this.cache;

		if ( cache.attributesNormalized.has( normal ) ) return false;

		const v = new Vector3();

		for ( let i = 0, il = normal.count; i < il; i ++ ) {

			// 0.0005 is from glTF-validator
			if ( Math.abs( v.fromBufferAttribute( normal, i ).length() - 1.0 ) > 0.0005 ) return false;

		}

		return true;

	}
createNormalizedNormalAttribute( normal ) {

		const cache = this.cache;

		if ( cache.attributesNormalized.has( normal ) )	return cache.attributesNormalized.get( normal );

		const attribute = normal.clone();
		const v = new Vector3();

		for ( let i = 0, il = attribute.count; i < il; i ++ ) {

			v.fromBufferAttribute( attribute, i );

			if ( v.x === 0 && v.y === 0 && v.z === 0 ) {

				// if values can't be normalized set (1, 0, 0)
				v.setX( 1.0 );

			} else {

				v.normalize();

			}

			attribute.setXYZ( i, v.x, v.y, v.z );

		}

		cache.attributesNormalized.set( normal, attribute );

		return attribute;

	}
applyTextureTransform( mapDef, texture ) {

		let didTransform = false;
		const transformDef = {};

		if ( texture.offset.x !== 0 || texture.offset.y !== 0 ) {

			transformDef.offset = texture.offset.toArray();
			didTransform = true;

		}

		if ( texture.rotation !== 0 ) {

			transformDef.rotation = texture.rotation;
			didTransform = true;

		}

		if ( texture.repeat.x !== 1 || texture.repeat.y !== 1 ) {

			transformDef.scale = texture.repeat.toArray();
			didTransform = true;

		}

		if ( didTransform ) {

			mapDef.extensions = mapDef.extensions || {};
			mapDef.extensions[ 'KHR_texture_transform' ] = transformDef;
			this.extensionsUsed[ 'KHR_texture_transform' ] = true;

		}

	}
buildMetalRoughTexture( metalnessMap, roughnessMap ) {

		if ( metalnessMap === roughnessMap ) return metalnessMap;

		function getEncodingConversion( map ) {

			if ( map.colorSpace === SRGBColorSpace ) {

				return function SRGBToLinear( c ) {

					return ( c < 0.04045 ) ? c * 0.0773993808 : Math.pow( c * 0.9478672986 + 0.0521327014, 2.4 );

				};

			}

			return function LinearToLinear( c ) {

				return c;

			};

		}

		console.warn( 'THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.' );

		if ( metalnessMap instanceof CompressedTexture ) {

			metalnessMap = decompress( metalnessMap );

		}

		if ( roughnessMap instanceof CompressedTexture ) {

			roughnessMap = decompress( roughnessMap );

		}

		const metalness = metalnessMap ? metalnessMap.image : null;
		const roughness = roughnessMap ? roughnessMap.image : null;

		const width = Math.max( metalness ? metalness.width : 0, roughness ? roughness.width : 0 );
		const height = Math.max( metalness ? metalness.height : 0, roughness ? roughness.height : 0 );

		const canvas = getCanvas();
		canvas.width = width;
		canvas.height = height;

		const context = canvas.getContext( '2d' );
		context.fillStyle = '#00ffff';
		context.fillRect( 0, 0, width, height );

		const composite = context.getImageData( 0, 0, width, height );

		if ( metalness ) {

			context.drawImage( metalness, 0, 0, width, height );

			const convert = getEncodingConversion( metalnessMap );
			const data = context.getImageData( 0, 0, width, height ).data;

			for ( let i = 2; i < data.length; i += 4 ) {

				composite.data[ i ] = convert( data[ i ] / 256 ) * 256;

			}

		}

		if ( roughness ) {

			context.drawImage( roughness, 0, 0, width, height );

			const convert = getEncodingConversion( roughnessMap );
			const data = context.getImageData( 0, 0, width, height ).data;

			for ( let i = 1; i < data.length; i += 4 ) {

				composite.data[ i ] = convert( data[ i ] / 256 ) * 256;

			}

		}

		context.putImageData( composite, 0, 0 );

		//

		const reference = metalnessMap || roughnessMap;

		const texture = reference.clone();

		texture.source = new Source( canvas );
		texture.colorSpace = NoColorSpace;
		texture.channel = ( metalnessMap || roughnessMap ).channel;

		if ( metalnessMap && roughnessMap && metalnessMap.channel !== roughnessMap.channel ) {

			console.warn( 'THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.' );

		}

		return texture;

	}
processBuffer( buffer ) {

		const json = this.json;
		const buffers = this.buffers;

		if ( ! json.buffers ) json.buffers = [ { byteLength: 0 } ];

		// All buffers are merged before export.
		buffers.push( buffer );

		return 0;

	}