processBufferView( attribute, componentType, start, count, target ) {

		const json = this.json;

		if ( ! json.bufferViews ) json.bufferViews = [];

		// Create a new dataview and dump the attribute's array into it

		let componentSize;

		switch ( componentType ) {

			case WEBGL_CONSTANTS.BYTE:
			case WEBGL_CONSTANTS.UNSIGNED_BYTE:

				componentSize = 1;

				break;

			case WEBGL_CONSTANTS.SHORT:
			case WEBGL_CONSTANTS.UNSIGNED_SHORT:

				componentSize = 2;

				break;

			default:

				componentSize = 4;

		}

		let byteStride = attribute.itemSize * componentSize;

		if ( target === WEBGL_CONSTANTS.ARRAY_BUFFER ) {

			// Each element of a vertex attribute MUST be aligned to 4-byte boundaries
			// inside a bufferView
			byteStride = Math.ceil( byteStride / 4 ) * 4;

		}

		const byteLength = getPaddedBufferSize( count * byteStride );
		const dataView = new DataView( new ArrayBuffer( byteLength ) );
		let offset = 0;

		for ( let i = start; i < start + count; i ++ ) {

			for ( let a = 0; a < attribute.itemSize; a ++ ) {

				let value;

				if ( attribute.itemSize > 4 ) {

					 // no support for interleaved data for itemSize > 4

					value = attribute.array[ i * attribute.itemSize + a ];

				} else {

					if ( a === 0 ) value = attribute.getX( i );
					else if ( a === 1 ) value = attribute.getY( i );
					else if ( a === 2 ) value = attribute.getZ( i );
					else if ( a === 3 ) value = attribute.getW( i );

					if ( attribute.normalized === true ) {

						value = MathUtils.normalize( value, attribute.array );

					}

				}

				if ( componentType === WEBGL_CONSTANTS.FLOAT ) {

					dataView.setFloat32( offset, value, true );

				} else if ( componentType === WEBGL_CONSTANTS.INT ) {

					dataView.setInt32( offset, value, true );

				} else if ( componentType === WEBGL_CONSTANTS.UNSIGNED_INT ) {

					dataView.setUint32( offset, value, true );

				} else if ( componentType === WEBGL_CONSTANTS.SHORT ) {

					dataView.setInt16( offset, value, true );

				} else if ( componentType === WEBGL_CONSTANTS.UNSIGNED_SHORT ) {

					dataView.setUint16( offset, value, true );

				} else if ( componentType === WEBGL_CONSTANTS.BYTE ) {

					dataView.setInt8( offset, value );

				} else if ( componentType === WEBGL_CONSTANTS.UNSIGNED_BYTE ) {

					dataView.setUint8( offset, value );

				}

				offset += componentSize;

			}

			if ( ( offset % byteStride ) !== 0 ) {

				offset += byteStride - ( offset % byteStride );

			}

		}

		const bufferViewDef = {

			buffer: this.processBuffer( dataView.buffer ),
			byteOffset: this.byteOffset,
			byteLength: byteLength

		};

		if ( target !== undefined ) bufferViewDef.target = target;

		if ( target === WEBGL_CONSTANTS.ARRAY_BUFFER ) {

			// Only define byteStride for vertex attributes.
			bufferViewDef.byteStride = byteStride;

		}

		this.byteOffset += byteLength;

		json.bufferViews.push( bufferViewDef );

		// @TODO Merge bufferViews where possible.
		const output = {

			id: json.bufferViews.length - 1,
			byteLength: 0

		};

		return output;

	}
processBufferViewImage( blob ) {

		const writer = this;
		const json = writer.json;

		if ( ! json.bufferViews ) json.bufferViews = [];

		return new Promise( function ( resolve ) {

			const reader = new FileReader();
			reader.readAsArrayBuffer( blob );
			reader.onloadend = function () {

				const buffer = getPaddedArrayBuffer( reader.result );

				const bufferViewDef = {
					buffer: writer.processBuffer( buffer ),
					byteOffset: writer.byteOffset,
					byteLength: buffer.byteLength
				};

				writer.byteOffset += buffer.byteLength;
				resolve( json.bufferViews.push( bufferViewDef ) - 1 );

			};

		} );

	}
processAccessor( attribute, geometry, start, count ) {

		const json = this.json;

		const types = {

			1: 'SCALAR',
			2: 'VEC2',
			3: 'VEC3',
			4: 'VEC4',
			9: 'MAT3',
			16: 'MAT4'

		};

		let componentType;

		// Detect the component type of the attribute array
		if ( attribute.array.constructor === Float32Array ) {

			componentType = WEBGL_CONSTANTS.FLOAT;

		} else if ( attribute.array.constructor === Int32Array ) {

			componentType = WEBGL_CONSTANTS.INT;

		} else if ( attribute.array.constructor === Uint32Array ) {

			componentType = WEBGL_CONSTANTS.UNSIGNED_INT;

		} else if ( attribute.array.constructor === Int16Array ) {

			componentType = WEBGL_CONSTANTS.SHORT;

		} else if ( attribute.array.constructor === Uint16Array ) {

			componentType = WEBGL_CONSTANTS.UNSIGNED_SHORT;

		} else if ( attribute.array.constructor === Int8Array ) {

			componentType = WEBGL_CONSTANTS.BYTE;

		} else if ( attribute.array.constructor === Uint8Array ) {

			componentType = WEBGL_CONSTANTS.UNSIGNED_BYTE;

		} else {

			throw new Error( 'THREE.GLTFExporter: Unsupported bufferAttribute component type: ' + attribute.array.constructor.name );

		}

		if ( start === undefined ) start = 0;
		if ( count === undefined || count === Infinity ) count = attribute.count;

		// Skip creating an accessor if the attribute doesn't have data to export
		if ( count === 0 ) return null;

		const minMax = getMinMax( attribute, start, count );
		let bufferViewTarget;

		// If geometry isn't provided, don't infer the target usage of the bufferView. For
		// animation samplers, target must not be set.
		if ( geometry !== undefined ) {

			bufferViewTarget = attribute === geometry.index ? WEBGL_CONSTANTS.ELEMENT_ARRAY_BUFFER : WEBGL_CONSTANTS.ARRAY_BUFFER;

		}

		const bufferView = this.processBufferView( attribute, componentType, start, count, bufferViewTarget );

		const accessorDef = {

			bufferView: bufferView.id,
			byteOffset: bufferView.byteOffset,
			componentType: componentType,
			count: count,
			max: minMax.max,
			min: minMax.min,
			type: types[ attribute.itemSize ]

		};

		if ( attribute.normalized === true ) accessorDef.normalized = true;
		if ( ! json.accessors ) json.accessors = [];

		return json.accessors.push( accessorDef ) - 1;

	}
processImage( image, format, flipY, mimeType = 'image/png' ) {

		if ( image !== null ) {

			const writer = this;
			const cache = writer.cache;
			const json = writer.json;
			const options = writer.options;
			const pending = writer.pending;

			if ( ! cache.images.has( image ) ) cache.images.set( image, {} );

			const cachedImages = cache.images.get( image );

			const key = mimeType + ':flipY/' + flipY.toString();

			if ( cachedImages[ key ] !== undefined ) return cachedImages[ key ];

			if ( ! json.images ) json.images = [];

			const imageDef = { mimeType: mimeType };

			const canvas = getCanvas();

			canvas.width = Math.min( image.width, options.maxTextureSize );
			canvas.height = Math.min( image.height, options.maxTextureSize );

			const ctx = canvas.getContext( '2d' );

			if ( flipY === true ) {

				ctx.translate( 0, canvas.height );
				ctx.scale( 1, - 1 );

			}

			if ( image.data !== undefined ) { // THREE.DataTexture

				if ( format !== RGBAFormat ) {

					console.error( 'GLTFExporter: Only RGBAFormat is supported.', format );

				}

				if ( image.width > options.maxTextureSize || image.height > options.maxTextureSize ) {

					console.warn( 'GLTFExporter: Image size is bigger than maxTextureSize', image );

				}

				const data = new Uint8ClampedArray( image.height * image.width * 4 );

				for ( let i = 0; i < data.length; i += 4 ) {

					data[ i + 0 ] = image.data[ i + 0 ];
					data[ i + 1 ] = image.data[ i + 1 ];
					data[ i + 2 ] = image.data[ i + 2 ];
					data[ i + 3 ] = image.data[ i + 3 ];

				}

				ctx.putImageData( new ImageData( data, image.width, image.height ), 0, 0 );

			} else {

				if ( ( typeof HTMLImageElement !== 'undefined' && image instanceof HTMLImageElement ) ||
					( typeof HTMLCanvasElement !== 'undefined' && image instanceof HTMLCanvasElement ) ||
					( typeof ImageBitmap !== 'undefined' && image instanceof ImageBitmap ) ||
					( typeof OffscreenCanvas !== 'undefined' && image instanceof OffscreenCanvas ) ) {

					ctx.drawImage( image, 0, 0, canvas.width, canvas.height );

				} else {

					throw new Error( 'THREE.GLTFExporter: Invalid image type. Use HTMLImageElement, HTMLCanvasElement, ImageBitmap or OffscreenCanvas.' );

				}

			}

			if ( options.binary === true ) {

				pending.push(

					getToBlobPromise( canvas, mimeType )
						.then( blob => writer.processBufferViewImage( blob ) )
						.then( bufferViewIndex => {

							imageDef.bufferView = bufferViewIndex;

						} )

				);

			} else {

				if ( canvas.toDataURL !== undefined ) {

					imageDef.uri = canvas.toDataURL( mimeType );

				} else {

					pending.push(

						getToBlobPromise( canvas, mimeType )
							.then( blob => new FileReader().readAsDataURL( blob ) )
							.then( dataURL => {

								imageDef.uri = dataURL;

							} )

					);

				}

			}

			const index = json.images.push( imageDef ) - 1;
			cachedImages[ key ] = index;
			return index;

		} else {

			throw new Error( 'THREE.GLTFExporter: No valid image data found. Unable to process texture.' );

		}

	}
processSampler( map ) {

		const json = this.json;

		if ( ! json.samplers ) json.samplers = [];

		const samplerDef = {
			magFilter: THREE_TO_WEBGL[ map.magFilter ],
			minFilter: THREE_TO_WEBGL[ map.minFilter ],
			wrapS: THREE_TO_WEBGL[ map.wrapS ],
			wrapT: THREE_TO_WEBGL[ map.wrapT ]
		};

		return json.samplers.push( samplerDef ) - 1;

	}
processTexture( map ) {

		const writer = this;
		const options = writer.options;
		const cache = this.cache;
		const json = this.json;

		if ( cache.textures.has( map ) ) return cache.textures.get( map );

		if ( ! json.textures ) json.textures = [];

		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a new texture
		if ( map instanceof CompressedTexture ) {

			map = decompress( map, options.maxTextureSize );

		}

		let mimeType = map.userData.mimeType;

		if ( mimeType === 'image/webp' ) mimeType = 'image/png';

		const textureDef = {
			sampler: this.processSampler( map ),
			source: this.processImage( map.image, map.format, map.flipY, mimeType )
		};

		if ( map.name ) textureDef.name = map.name;

		this._invokeAll( function ( ext ) {

			ext.writeTexture && ext.writeTexture( map, textureDef );

		} );

		const index = json.textures.push( textureDef ) - 1;
		cache.textures.set( map, index );
		return index;

	}