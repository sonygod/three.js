import {
	GPUTextureFormat, GPUAddressMode, GPUFilterMode, GPUTextureDimension, GPUFeatureName
} from './WebGPUConstants.js';

import {
	CubeTexture, Texture,
	NearestFilter, NearestMipmapNearestFilter, NearestMipmapLinearFilter,
	RepeatWrapping, MirroredRepeatWrapping,
	RGB_ETC2_Format, RGBA_ETC2_EAC_Format,
	RGBAFormat, RGBFormat, RedFormat, RGFormat, RGBA_S3TC_DXT1_Format, RGBA_S3TC_DXT3_Format, RGBA_S3TC_DXT5_Format, UnsignedByteType, FloatType, HalfFloatType, SRGBColorSpace, DepthFormat, DepthStencilFormat,
	RGBA_ASTC_4x4_Format, RGBA_ASTC_5x4_Format, RGBA_ASTC_5x5_Format, RGBA_ASTC_6x5_Format, RGBA_ASTC_6x6_Format, RGBA_ASTC_8x5_Format, RGBA_ASTC_8x6_Format, RGBA_ASTC_8x8_Format, RGBA_ASTC_10x5_Format,
	RGBA_ASTC_10x6_Format, RGBA_ASTC_10x8_Format, RGBA_ASTC_10x10_Format, RGBA_ASTC_12x10_Format, RGBA_ASTC_12x12_Format, UnsignedIntType, UnsignedShortType, UnsignedInt248Type, UnsignedInt5999Type,
	NeverCompare, AlwaysCompare, LessCompare, LessEqualCompare, EqualCompare, GreaterEqualCompare, GreaterCompare, NotEqualCompare, IntType, RedIntegerFormat, RGIntegerFormat, RGBAIntegerFormat
} from 'three';

import { CubeReflectionMapping, CubeRefractionMapping, EquirectangularReflectionMapping, EquirectangularRefractionMapping, DepthTexture } from 'three';

import WebGPUTexturePassUtils from './WebGPUTexturePassUtils.js';

const _compareToWebGPU = {
	[ NeverCompare ]: 'never',
	[ LessCompare ]: 'less',
	[ EqualCompare ]: 'equal',
	[ LessEqualCompare ]: 'less-equal',
	[ GreaterCompare ]: 'greater',
	[ GreaterEqualCompare ]: 'greater-equal',
	[ AlwaysCompare ]: 'always',
	[ NotEqualCompare ]: 'not-equal'
};

const _flipMap = [ 0, 1, 3, 2, 4, 5 ];


class WebGPUTextureUtils {

	constructor( backend ) {

		this.backend = backend;

		this._passUtils = null;

		this.defaultTexture = {};
		this.defaultCubeTexture = {};

		this.colorBuffer = null;

		this.depthTexture = new DepthTexture();
		this.depthTexture.name = 'depthBuffer';

	}
createSampler( texture ) {

		const backend = this.backend;
		const device = backend.device;

		const textureGPU = backend.get( texture );

		const samplerDescriptorGPU = {
			addressModeU: this._convertAddressMode( texture.wrapS ),
			addressModeV: this._convertAddressMode( texture.wrapT ),
			addressModeW: this._convertAddressMode( texture.wrapR ),
			magFilter: this._convertFilterMode( texture.magFilter ),
			minFilter: this._convertFilterMode( texture.minFilter ),
			mipmapFilter: this._convertFilterMode( texture.minFilter ),
			maxAnisotropy: texture.anisotropy
		};

		if ( texture.isDepthTexture && texture.compareFunction !== null ) {

			samplerDescriptorGPU.compare = _compareToWebGPU[ texture.compareFunction ];

		}

		textureGPU.sampler = device.createSampler( samplerDescriptorGPU );

	}
createDefaultTexture( texture ) {

		let textureGPU;

		const format = getFormat( texture );

		if ( texture.isCubeTexture ) {

			textureGPU = this._getDefaultCubeTextureGPU( format );

		} else {

			textureGPU = this._getDefaultTextureGPU( format );

		}

		this.backend.get( texture ).texture = textureGPU;

	}
createTexture( texture, options = {} ) {

		const backend = this.backend;
		const textureData = backend.get( texture );

		if ( textureData.initialized ) {

			throw new Error( 'WebGPUTextureUtils: Texture already initialized.' );

		}

		if ( options.needsMipmaps === undefined ) options.needsMipmaps = false;
		if ( options.levels === undefined ) options.levels = 1;
		if ( options.depth === undefined ) options.depth = 1;

		const { width, height, depth, levels } = options;

		const dimension = this._getDimension( texture );
		const format = texture.internalFormat || options.format || getFormat( texture, backend.device );

		let sampleCount = options.sampleCount !== undefined ? options.sampleCount : 1;

		if ( sampleCount > 1 ) {

			// WebGPU only supports power-of-two sample counts and 2 is not a valid value
			sampleCount = Math.pow( 2, Math.floor( Math.log2( sampleCount ) ) );

			if ( sampleCount === 2 ) {

				sampleCount = 4;

			}

		}

		const primarySampleCount = texture.isRenderTargetTexture ? 1 : sampleCount;

		let usage = GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.COPY_SRC;

		if ( texture.isStorageTexture === true ) {

			usage |= GPUTextureUsage.STORAGE_BINDING;

		}

		if ( texture.isCompressedTexture !== true ) {

			usage |= GPUTextureUsage.RENDER_ATTACHMENT;

		}

		const textureDescriptorGPU = {
			label: texture.name,
			size: {
				width: width,
				height: height,
				depthOrArrayLayers: depth,
			},
			mipLevelCount: levels,
			sampleCount: primarySampleCount,
			dimension: dimension,
			format: format,
			usage: usage
		};

		// texture creation

		if ( texture.isVideoTexture ) {

			const video = texture.source.data;
			const videoFrame = new VideoFrame( video );

			textureDescriptorGPU.size.width = videoFrame.displayWidth;
			textureDescriptorGPU.size.height = videoFrame.displayHeight;

			videoFrame.close();

			textureData.externalTexture = video;

		} else {

			if ( format === undefined ) {

				console.warn( 'WebGPURenderer: Texture format not supported.' );

				return this.createDefaultTexture( texture );

			}

			textureData.texture = backend.device.createTexture( textureDescriptorGPU );

		}

		if ( texture.isRenderTargetTexture && sampleCount > 1 ) {

			const msaaTextureDescriptorGPU = Object.assign( {}, textureDescriptorGPU );

			msaaTextureDescriptorGPU.label = msaaTextureDescriptorGPU.label + '-msaa';
			msaaTextureDescriptorGPU.sampleCount = sampleCount;

			textureData.msaaTexture = backend.device.createTexture( msaaTextureDescriptorGPU );

		}

		textureData.initialized = true;

		textureData.textureDescriptorGPU = textureDescriptorGPU;

	}
destroyTexture( texture ) {

		const backend = this.backend;
		const textureData = backend.get( texture );

		textureData.texture.destroy();

		if ( textureData.msaaTexture !== undefined ) textureData.msaaTexture.destroy();

		backend.delete( texture );

	}
destroySampler( texture ) {

		const backend = this.backend;
		const textureData = backend.get( texture );

		delete textureData.sampler;

	}
generateMipmaps( texture ) {

		const textureData = this.backend.get( texture );

		if ( texture.isCubeTexture ) {

			for ( let i = 0; i < 6; i ++ ) {

				this._generateMipmaps( textureData.texture, textureData.textureDescriptorGPU, i );

			}

		} else {

			this._generateMipmaps( textureData.texture, textureData.textureDescriptorGPU );

		}

	}
getColorBuffer() {

		if ( this.colorBuffer ) this.colorBuffer.destroy();

		const backend = this.backend;
		const { width, height } = backend.getDrawingBufferSize();

		this.colorBuffer = backend.device.createTexture( {
			label: 'colorBuffer',
			size: {
				width: width,
				height: height,
				depthOrArrayLayers: 1
			},
			sampleCount: backend.parameters.sampleCount,
			format: GPUTextureFormat.BGRA8Unorm,
			usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC
		} );

		return this.colorBuffer;

	}
getDepthBuffer( depth = true, stencil = false ) {

		const backend = this.backend;
		const { width, height } = backend.getDrawingBufferSize();

		const depthTexture = this.depthTexture;
		const depthTextureGPU = backend.get( depthTexture ).texture;

		let format, type;

		if ( stencil ) {

			format = DepthStencilFormat;
			type = UnsignedInt248Type;

		} else if ( depth ) {

			format = DepthFormat;
			type = UnsignedIntType;

		}

		if ( depthTextureGPU !== undefined ) {

			if ( depthTexture.image.width === width && depthTexture.image.height === height && depthTexture.format === format && depthTexture.type === type ) {

				return depthTextureGPU;

			}

			this.destroyTexture( depthTexture );

		}

		depthTexture.name = 'depthBuffer';
		depthTexture.format = format;
		depthTexture.type = type;
		depthTexture.image.width = width;
		depthTexture.image.height = height;

		this.createTexture( depthTexture, { sampleCount: backend.parameters.sampleCount, width, height } );

		return backend.get( depthTexture ).texture;

	}
updateTexture( texture, options ) {

		const textureData = this.backend.get( texture );

		const { textureDescriptorGPU } = textureData;

		if ( texture.isRenderTargetTexture || ( textureDescriptorGPU === undefined /* unsupported texture format */ ) )
			return;

		// transfer texture data

		if ( texture.isDataTexture || texture.isData3DTexture ) {

			this._copyBufferToTexture( options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY );

		} else if ( texture.isDataArrayTexture ) {

			for ( let i = 0; i < options.image.depth; i ++ ) {

				this._copyBufferToTexture( options.image, textureData.texture, textureDescriptorGPU, i, texture.flipY, i );

			}

		} else if ( texture.isCompressedTexture ) {

			this._copyCompressedBufferToTexture( texture.mipmaps, textureData.texture, textureDescriptorGPU );

		} else if ( texture.isCubeTexture ) {

			this._copyCubeMapToTexture( options.images, textureData.texture, textureDescriptorGPU, texture.flipY );

		} else if ( texture.isVideoTexture ) {

			const video = texture.source.data;

			textureData.externalTexture = video;

		} else {

			this._copyImageToTexture( options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY );

		}

		//

		textureData.version = texture.version;

		if ( texture.onUpdate ) texture.onUpdate( texture );

	}
async copyTextureToBuffer( texture, x, y, width, height ) {

		const device = this.backend.device;

		const textureData = this.backend.get( texture );
		const textureGPU = textureData.texture;
		const format = textureData.textureDescriptorGPU.format;
		const bytesPerTexel = this._getBytesPerTexel( format );

		let bytesPerRow = width * bytesPerTexel;
		bytesPerRow = Math.ceil( bytesPerRow / 256 ) * 256; // Align to 256 bytes

		const readBuffer = device.createBuffer(
			{
				size: width * height * bytesPerTexel,
				usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
			}
		);

		const encoder = device.createCommandEncoder();

		encoder.copyTextureToBuffer(
			{
				texture: textureGPU,
				origin: { x, y },
			},
			{
				buffer: readBuffer,
				bytesPerRow: bytesPerRow
			},
			{
				width: width,
				height: height
			}

		);

		const typedArrayType = this._getTypedArrayType( format );

		device.queue.submit( [ encoder.finish() ] );

		await readBuffer.mapAsync( GPUMapMode.READ );

		const buffer = readBuffer.getMappedRange();

		return new typedArrayType( buffer );

	}
_isEnvironmentTexture( texture ) {

		const mapping = texture.mapping;

		return ( mapping === EquirectangularReflectionMapping || mapping === EquirectangularRefractionMapping ) || ( mapping === CubeReflectionMapping || mapping === CubeRefractionMapping );

	}
_getDefaultTextureGPU( format ) {

		let defaultTexture = this.defaultTexture[ format ];

		if ( defaultTexture === undefined ) {

			const texture = new Texture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture( texture, { width: 1, height: 1, format } );

			this.defaultTexture[ format ] = defaultTexture = texture;

		}

		return this.backend.get( defaultTexture ).texture;

	}
_getDefaultCubeTextureGPU( format ) {

		let defaultCubeTexture = this.defaultTexture[ format ];

		if ( defaultCubeTexture === undefined ) {

			const texture = new CubeTexture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture( texture, { width: 1, height: 1, depth: 6 } );

			this.defaultCubeTexture[ format ] = defaultCubeTexture = texture;

		}

		return this.backend.get( defaultCubeTexture ).texture;

	}
_copyCubeMapToTexture( images, textureGPU, textureDescriptorGPU, flipY ) {

		for ( let i = 0; i < 6; i ++ ) {

			const image = images[ i ];

			const flipIndex = flipY === true ? _flipMap[ i ] : i;

			if ( image.isDataTexture ) {

				this._copyBufferToTexture( image.image, textureGPU, textureDescriptorGPU, flipIndex, flipY );

			} else {

				this._copyImageToTexture( image, textureGPU, textureDescriptorGPU, flipIndex, flipY );

			}

		}

	}
_copyImageToTexture( image, textureGPU, textureDescriptorGPU, originDepth, flipY ) {

		const device = this.backend.device;

		device.queue.copyExternalImageToTexture(
			{
				source: image
			}, {
				texture: textureGPU,
				mipLevel: 0,
				origin: { x: 0, y: 0, z: originDepth }
			}, {
				width: image.width,
				height: image.height,
				depthOrArrayLayers: 1
			}
		);

		if ( flipY === true ) {

			this._flipY( textureGPU, textureDescriptorGPU, originDepth );

		}

	}