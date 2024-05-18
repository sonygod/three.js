import three.webgpu.WebGPUConstants;
import three.webgpu.WebGPUTexturePassUtils;
import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.NearestFilter;
import three.textures.NearestMipmapNearestFilter;
import three.textures.NearestMipmapLinearFilter;
import three.textures.RepeatWrapping;
import three.textures.MirroredRepeatWrapping;
import three.textures.RGBA_ETC2_EAC_Format;
import three.textures.RGBAFormat;
import three.textures.RGBFormat;
import three.textures.RedFormat;
import three.textures.RGFormat;
import three.textures.RGBA_S3TC_DXT1_Format;
import three.textures.RGBA_S3TC_DXT3_Format;
import three.textures.RGBA_S3TC_DXT5_Format;
import three.textures.UnsignedByteType;
import three.textures.FloatType;
import three.textures.HalfFloatType;
import three.textures.SRGBColorSpace;
import three.textures.DepthFormat;
import three.textures.DepthStencilFormat;
import three.textures.RGBA_ASTC_4x4_Format;
import three.textures.RGBA_ASTC_5x4_Format;
import three.textures.RGBA_ASTC_5x5_Format;
import three.textures.RGBA_ASTC_6x5_Format;
import three.textures.RGBA_ASTC_6x6_Format;
import three.textures.RGBA_ASTC_8x5_Format;
import three.textures.RGBA_ASTC_8x6_Format;
import three.textures.RGBA_ASTC_8x8_Format;
import three.textures.RGBA_ASTC_10x5_Format;
import three.textures.RGBA_ASTC_10x6_Format;
import three.textures.RGBA_ASTC_10x8_Format;
import three.textures.RGBA_ASTC_10x10_Format;
import three.textures.RGBA_ASTC_12x10_Format;
import three.textures.RGBA_ASTC_12x12_Format;
import three.textures.UnsignedIntType;
import three.textures.UnsignedShortType;
import three.textures.UnsignedInt248Type;
import three.textures.UnsignedInt5999Type;
import three.textures.NeverCompare;
import three.textures.AlwaysCompare;
import three.textures.LessCompare;
import three.textures.LessEqualCompare;
import three.textures.EqualCompare;
import three.textures.GreaterEqualCompare;
import three.textures.GreaterCompare;
import three.textures.NotEqualCompare;
import three.textures.IntType;
import three.textures.RedIntegerFormat;
import three.textures.RGIntegerFormat;
import three.textures.RGBAIntegerFormat;
import three.textures.CubeReflectionMapping;
import three.textures.CubeRefractionMapping;
import three.textures.EquirectangularReflectionMapping;
import three.textures.EquirectangularRefractionMapping;
import three.textures.DepthTexture;

class WebGPUTextureUtils {
	private var _passUtils: WebGPUTexturePassUtils;
	private var defaultTexture: Dict<Texture>;
	private var defaultCubeTexture: Dict<CubeTexture>;
	private var colorBuffer: gpu.Texture;
	private var depthTexture: DepthTexture;

	public function new(backend: Backend) {
		this._passUtils = null;
		this.defaultTexture = {};
		this.defaultCubeTexture = {};
		this.colorBuffer = null;
		this.depthTexture = new DepthTexture();
		this.depthTexture.name = 'depthBuffer';
	}

	public function createSampler(texture: Texture): Void {
		var device = backend.device;
		var textureGPU = backend.get(texture);

		var samplerDescriptorGPU = {
			addressModeU: this._convertAddressMode(texture.wrapS),
			addressModeV: this._convertAddressMode(texture.wrapT),
			addressModeW: this._convertAddressMode(texture.wrapR),
			magFilter: this._convertFilterMode(texture.magFilter),
			minFilter: this._convertFilterMode(texture.minFilter),
			mipmapFilter: this._convertFilterMode(texture.minFilter),
			maxAnisotropy: texture.anisotropy
		};

		if (texture.isDepthTexture && texture.compareFunction !== null) {
			samplerDescriptorGPU.compare = _compareToWebGPU[texture.compareFunction];
		}

		textureGPU.sampler = device.createSampler(samplerDescriptorGPU);
	}

	public function createDefaultTexture(texture: Texture): Void {
		let textureGPU;
		var format = getFormat(texture);

		if (texture.isCubeTexture) {
			textureGPU = this._getDefaultCubeTextureGPU(format);
		} else {
			textureGPU = this._getDefaultTextureGPU(format);
		}

		backend.get(texture).texture = textureGPU;
	}

	public function createTexture(texture: Texture, options: Dict<Dynamic> = {}): Void {
		var backend = this.backend;
		var textureData = backend.get(texture);

		if (textureData.initialized) {
			throw new Error('WebGPUTextureUtils: Texture already initialized.');
		}

		if (options.needsMipmaps === undefined) options.needsMipmaps = false;
		if (options.levels === undefined) options.levels = 1;
		if (options.depth === undefined) options.depth = 1;

		var { width, height, depth, levels } = options;

		var dimension = this._getDimension(texture);
		var format = texture.internalFormat || options.format || getFormat(texture, backend.device);

		var sampleCount = options.sampleCount !== undefined ? options.sampleCount : 1;

		if (sampleCount > 1) {
			// WebGPU only supports power-of-two sample counts and 2 is not a valid value
			sampleCount = Math.pow(2, Math.floor(Math.log2(sampleCount)));

			if (sampleCount === 2) {
				sampleCount = 4;
			}
		}

		var primarySampleCount = texture.isRenderTargetTexture ? 1 : sampleCount;

		var usage = gpu.TextureUsage.TEXTURE_BINDING | gpu.TextureUsage.COPY_DST | gpu.TextureUsage.COPY_SRC;

		if (texture.isStorageTexture === true) {
			usage |= gpu.TextureUsage.STORAGE_BINDING;
		}

		if (texture.isCompressedTexture !== true) {
			usage |= gpu.TextureUsage.RENDER_ATTACHMENT;
		}

		var textureDescriptorGPU = {
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

		if (texture.isVideoTexture) {
			var video = texture.source.data;
			var videoFrame = new VideoFrame(video);

			textureDescriptorGPU.size.width = videoFrame.displayWidth;
			textureDescriptorGPU.size.height = videoFrame.displayHeight;

			videoFrame.close();

			textureData.externalTexture = video;

		} else {

			if (format === undefined) {
				console.warn('WebGPURenderer: Texture format not supported.');

				return this.createDefaultTexture(texture);
			}

			textureData.texture = backend.device.createTexture(textureDescriptorGPU);
		}

		if (texture.isRenderTargetTexture && sampleCount > 1) {
			var msaaTextureDescriptorGPU = Typed.object(textureDescriptorGPU);

			msaaTextureDescriptorGPU.label = msaaTextureDescriptorGPU.label + '-msaa';
			msaaTextureDescriptorGPU.sampleCount = sampleCount;

			textureData.msaaTexture = backend.device.createTexture(msaaTextureDescriptorGPU);
		}

		textureData.initialized = true;

		textureData.textureDescriptorGPU = textureDescriptorGPU;
	}

	public function destroyTexture(texture: Texture): Void {
		var backend = this.backend;
		var textureData = backend.get(texture);

		textureData.texture.destroy();

		if (textureData.msaaTexture !== undefined) textureData.msaaTexture.destroy();

		backend.delete(texture);
	}

	public function destroySampler(texture: Texture): Void {
		var backend = this.backend;
		var textureData = backend.get(texture);

		delete textureData.sampler;
	}

	public function generateMipmaps(texture: Texture): Void {
		var textureData = this.backend.get(texture);

		if (texture.isCubeTexture) {
			for (var i in 0...6) {
				this._generateMipmaps(textureData.texture, textureData.textureDescriptorGPU, i);
			}
		} else {
			this._generateMipmaps(textureData.texture, textureData.textureDescriptorGPU);
		}
	}

	public function getColorBuffer(): gpu.Texture {
		if (this.colorBuffer) this.colorBuffer.destroy();

		var backend = this.backend;
		var { width, height } = backend.getDrawingBufferSize();

		this.colorBuffer = backend.device.createTexture({
			label: 'colorBuffer',
			size: {
				width: width,
				height: height,
				depthOrArrayLayers: 1
			},
			sampleCount: backend.parameters.sampleCount,
			format: gpu.TextureFormat.BGRA8Unorm,
			usage: gpu.TextureUsage.RENDER_ATTACHMENT | gpu.TextureUsage.COPY_SRC
		});

		return this.colorBuffer;
	}

	public function getDepthBuffer(depth: Bool = true, stencil: Bool = false): gpu.Texture {
		var backend = this.backend;
		var { width, height } = backend.getDrawingBufferSize();

		var depthTexture = this.depthTexture;
		var depthTextureGPU = backend.get(depthTexture).texture;

		var format, type;

		if (stencil) {
			format = DepthStencilFormat;
			type = UnsignedInt248Type;
		} else if (depth) {
			format = DepthFormat;
			type = UnsignedIntType;
		}

		if (depthTextureGPU !== undefined) {
			if (depthTexture.image.width === width && depthTexture.image.height === height && depthTexture.format === format && depthTexture.type === type) {
				return depthTextureGPU;
			}

			this.destroyTexture(depthTexture);
		}

		depthTexture.name = 'depthBuffer';
		depthTexture.format = format;
		depthTexture.type = type;
		depthTexture.image.width = width;
		depthTexture.image.height = height;

		this.createTexture(depthTexture, { sampleCount: backend.parameters.sampleCount, width, height });

		return backend.get(depthTexture).texture;
	}

	public function updateTexture(texture: Texture, options: Dict<Dynamic>): Void {
		var textureData = this.backend.get(texture);

		var { textureDescriptorGPU } = textureData;

		if (texture.isRenderTargetTexture || (textureDescriptorGPU === undefined /* unsupported texture format */)) return;

		// transfer texture data

		if (texture.isDataTexture || texture.isData3DTexture) {
			this._copyBufferToTexture(options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY);
		} else if (texture.isDataArrayTexture) {
			for (var i in 0...options.image.depth) {
				this._copyBufferToTexture(options.image, textureData.texture, textureDescriptorGPU, i, texture.flipY, i);
			}
		} else if (texture.isCompressedTexture) {
			this._copyCompressedBufferToTexture(texture.mipmaps, textureData.texture, textureDescriptorGPU);
		} else if (texture.isCubeTexture) {
			this._copyCubeMapToTexture(options.images, textureData.texture, textureDescriptorGPU, texture.flipY);
		} else if (texture.isVideoTexture) {
			var video = texture.source.data;

			textureData.externalTexture = video;

		} else {
			this._copyImageToTexture(options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY);
		}

		//

		textureData.version = texture.version;

		if (texture.onUpdate) texture.onUpdate(texture);
	}

	public function copyTextureToBuffer(texture: Texture, x: Int, y: Int, width: Int, height: Int): ArrayBufferView {
		var device = this.backend.device;

		var textureData = this.backend.get(texture);
		var textureGPU = textureData.texture;
		var format = textureData.textureDescriptorGPU.format;
		var bytesPerTexel = this._getBytesPerTexel(format);

		var bytesPerRow = width * bytesPerTexel;
		bytesPerRow = Math.ceil(bytesPerRow / 256) * 256; // Align to 256 bytes

		var readBuffer = device.createBuffer({
			size: width * height * bytesPerTexel,
			usage: gpu.BufferUsage.COPY_DST | gpu.BufferUsage.MAP_READ
		});

		var encoder = device.createCommandEncoder();

		encoder.copyTextureToBuffer(
			{
				texture: textureGPU,
				mipLevel: 0,
			}, {
				buffer: readBuffer,
				bytesPerRow: bytesPerRow
			}, {
				width: width,
				height: height
			}

		);

		var typedArrayType = this._getTypedArrayType(format);

		device.queue.submit([encoder.finish()]);

		return readBuffer.mapAsync(gpu.MapMode.READ).then(function (event) {
			return readBuffer.getMappedRange();
		});
	}

	private function _isEnvironmentTexture(texture: Texture): Bool {
		var mapping = texture.mapping;

		return (mapping === EquirectangularReflectionMapping || mapping === EquirectangularRefractionMapping) || (mapping === CubeReflectionMapping || mapping === CubeRefractionMapping);
	}

	private function _getDefaultTextureGPU(format: Int): gpu.Texture {
		let defaultTexture = this.defaultTexture[format];

		if (defaultTexture === undefined) {
			var texture = new Texture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture(texture, { width: 1, height: 1, format });

			this.defaultTexture[format] = defaultTexture = texture;
		}

		return this.backend.get(defaultTexture).texture;
	}

	private function _getDefaultCubeTextureGPU(format: Int): gpu.Texture {
		let defaultCubeTexture = this.defaultCubeTexture[format];

		if (defaultCubeTexture === undefined) {
			var texture = new CubeTexture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture(texture, { width: 1, height: 1, depth: 6 });

			this.defaultCubeTexture[format] = defaultCubeTexture = texture;

		}

		return this.backend.get(defaultCubeTexture).texture;
	}

	private function _copyCubeMapToTexture(images: Array<Image>, textureGPU: gpu.Texture, textureDescriptorGPU: gpu.TextureDescriptor, flipY: Bool) {
		for (var i in 0...6) {
			var image = images[i];

			var flipIndex = flipY === true ? _flipMap[i] : i;

			if (image.isDataTexture) {
				this._copyBufferToTexture(image.image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
			} else {
				this._copyImageToTexture(image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
			}
		}
	}

	private function _copyImageToTexture(image: Image, textureGPU: gpu.Texture, textureDescriptorGPU: gpu.TextureDescriptor, originDepth: Int, flipY: Bool) {
		var device = this.backend.device;

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

		if (flipY === true) {
			this._flipY(textureGPU, textureDescriptorGPU, originDepth);
		}
	}

	private function _getPassUtils(): WebGPUTexturePassUtils {
		let passUtils = this._passUtils;

		if (passUtils === null) {
			this._passUtils = passUtils = new WebGPUTexturePassUtils(this.backend.device);
		}

		return passUtils;
	}

	private function _generateMipmaps(textureGPU: gpu.Texture, textureDescriptorGPU: gpu.TextureDescriptor, baseArrayLayer: Int = 0) {
		this._getPassUtils().generateMipmaps(textureGPU, textureDescriptorGPU, baseArrayLayer);
	}

	private function _flipY(textureGPU: gpu.Texture, textureDescriptorGPU: gpu.TextureDescriptor, originDepth: Int = 0) {
		this._getPassUtils().flipY(textureGPU, textureDescriptorGPU, originDepth);
	}

	private function _copyBufferToTexture(image: ArrayBufferView, textureGPU: gpu.Texture, textureDescriptorGPU: gpu.TextureDescriptor, originDepth: Int, flipY: Bool, depth: Int = 0) {
		// @TODO: Consider to use GPUCommandEncoder.copyBufferToTexture()
		// @TODO: Consider to support valid buffer layouts with other formats like RGB

		var device = this.backend.device;

		device.queue.writeTexture(
			{
				texture: textureGPU,
				mipLevel: 0,
				origin: { x: 0, y: 0, z: originDepth }
			},
			image,
			{
				offset: image.byteOffset,
				bytesPerRow: image.byteLength
			},
			{
				width: image.width,
				height: image.height,
				depthOrArrayLayers: 1
			}
		);

		if (flipY === true) {
			this._flipY(textureGPU, textureDescriptorGPU, originDepth);
		}
	}

	private function _copyCompressedBufferToTexture(mipmaps: Array<ArrayBufferView>, textureGPU: gpu.Texture, textureDescriptorGPU: gpu.TextureDescriptor) {
		// @TODO: Consider to use GPUCommandEncoder.copyBufferToTexture()

		var device = this.backend.device;

		for (var i in 0...mipmaps.length) {
			var mipmap = mipmaps[i];

			var width = mipmap.width;
			var height = mipmap.height;

			var bytesPerRow = Math.ceil(width / 4) * 16;

			device.queue.writeTexture(
				{
					texture: textureGPU,
					mipLevel: i
				},
				mipmap,
				{
					offset: 0,
					bytesPerRow
				},
				{
					width: Math.ceil(width / 4) * 4,
					height: Math.ceil(height / 4) * 4,
					depthOrArrayLayers: 1
				}
			);
		}
	}

	private function _getBlockData(format: Int): {byteLength: Int, width: Int, height: Int} {
		// this method is only relevant for compressed texture formats

		if (format === gpu.TextureFormat.BC1RGBAUnorm || format === gpu.TextureFormat.BC1RGBAUnormSRGB) return {byteLength: 8, width: 4, height: 4}; // DXT1
		if (format === gpu.TextureFormat.BC2RGBAUnorm || format === gpu.TextureFormat.BC2RGBAUnormSRGB) return {byteLength: 16, width: 4, height: 4}; // DXT3
		if (format === gpu.TextureFormat.BC3RGBAUnorm || format === gpu.TextureFormat.BC3RGBAUnormSRGB) return {byteLength: 16, width: 4, height: 4}; // DXT5
		if (format === gpu.TextureFormat.BC4RUnorm || format === gpu.TextureFormat.BC4RSNorm) return {byteLength: 8, width: 4, height: 4}; // RGTC1
		if (format === gpu.TextureFormat.BC5RGUnorm || format === gpu.TextureFormat.BC5RGSnorm) return {byteLength: 16, width: 4, height: 4}; // RGTC2
		if (format === gpu.TextureFormat.BC6HRGBUFloat || format === gpu.TextureFormat.BC6HRGBFloat) return {byteLength: 16, width: 4, height: 4}; // BPTC (float)
		if (format === gpu.TextureFormat.BC7RGBAUnorm || format === gpu.TextureFormat.BC7RGBAUnormSRGB) return {byteLength: 16, width: 4, height: 4}; // BPTC (unorm)

		if (format === gpu.TextureFormat.ETC2RGB8Unorm || format === gpu.TextureFormat.ETC2RGB8UnormSRGB) return {byteLength: 8, width: 4, height: 4};
		if (format === gpu.TextureFormat.ETC2RGB8A1Unorm || format === gpu.TextureFormat.ETC2RGB8A1UnormSRGB) return {byteLength: 8, width: 4, height: 4};
		if (format === gpu.TextureFormat.ETC2RGBA8Unorm || format === gpu.TextureFormat.ETC2RGBA8UnormSRGB) return {byteLength: 16, width: 4, height: 4};
		if (format === gpu.TextureFormat.EACR11Unorm) return {byteLength: 8, width: 4, height: 4};
		if (format === gpu.TextureFormat.EACR11Snorm) return {byteLength: 8, width: 4, height: 4};
		if (format === gpu.TextureFormat.EACRG11Unorm) return {byteLength: 16, width: 4, height: 4};
		if (format === gpu.TextureFormat.EACRG11Snorm) return {byteLength: 16, width: 4, height: 4};

		if (format === gpu.TextureFormat.ASTC4x4Unorm || format === gpu.TextureFormat.ASTC4x4UnormSRGB) return {byteLength: 16, width: 4, height: 4};
		if (format === gpu.TextureFormat.ASTC5x4Unorm || format === gpu.TextureFormat.ASTC5x4UnormSRGB) return {byteLength: 16, width: 5, height: 4};
		if (format === gpu.TextureFormat.ASTC5x5Unorm || format === gpu.TextureFormat.ASTC5x5UnormSRGB) return {byteLength: 16, width: 5, height: 5};
		if (format === gpu.TextureFormat.ASTC6x5Unorm || format === gpu.TextureFormat.ASTC6x5UnormSRGB) return {byteLength: 16, width: 6, height: 5};
		if (format === gpu.TextureFormat.ASTC6x6Unorm || format === gpu.TextureFormat.ASTC6x6UnormSRGB) return {byteLength: 16, width: 6, height: 6};
		if (format === gpu.TextureFormat.ASTC8x5Unorm || format === gpu.TextureFormat.ASTC8x5UnormSRGB) return {byteLength: 16, width: 8, height: 5};
		if (format === gpu.TextureFormat.ASTC8x6Unorm || format === gpu.TextureFormat.ASTC8x6UnormSRGB) return {byteLength: 16, width: 8, height: 6};
		if (format === gpu.TextureFormat.ASTC8x8Unorm || format === gpu.TextureFormat.ASTC8x8UnormSRGB) return {byteLength: 16, width: 8, height: 8};
		if (format === gpu.TextureFormat.ASTC10x5Unorm || format === gpu.TextureFormat.ASTC10x5UnormSRGB) return {byteLength: 16, width: 10, height: 5};
		if (format === gpu.TextureFormat.ASTC10x6Unorm || format === gpu.TextureFormat.ASTC10x6UnormSRGB) return {byteLength: 16, width: 10, height: 6};
		if (format === gpu.TextureFormat.ASTC10x8Unorm || format === gpu.TextureFormat.ASTC10x8UnormSRGB) return {byteLength: 16, width: 10, height: 8};
		if (format === gpu.TextureFormat.ASTC10x10Unorm || format === gpu.TextureFormat.ASTC10x10UnormSRGB) return {byteLength: 16, width: 10, height: 10};
		if (format === gpu.TextureFormat.ASTC12x10Unorm || format === gpu.TextureFormat.ASTC12x10UnormSRGB) return {byteLength: 16, width: 12, height: 10};
		if (format === gpu.TextureFormat.ASTC12x12Unorm || format === gpu.TextureFormat.ASTC12x12UnormSRGB) return {byteLength: 16, width: 12, height: 12};
	}

	private function _convertAddressMode(value: Int): gpu.AddressMode {
		let addressMode = gpu.AddressMode.ClampToEdge;

		if (value === RepeatWrapping) {
			addressMode = gpu.AddressMode.Repeat;
		} else if (value === MirroredRepeatWrapping) {
			addressMode = gpu.AddressMode.MirrorRepeat;
		}

		return addressMode;
	}

	private function _convertFilterMode(value: Int): gpu.FilterMode {
		let filterMode = gpu.FilterMode.Linear;

		if (value === NearestFilter || value === NearestMipmapNearestFilter || value === NearestMipmapLinearFilter) {
			filterMode = gpu.FilterMode.Nearest;
		}

		return filterMode;
	}

	private function _getBytesPerTexel(format: Int): Int {
		// 8-bit formats
		if (format === gpu.TextureFormat.R8Unorm || format === gpu.TextureFormat.R8Snorm || format === gpu.TextureFormat.R8Uint || format === gpu.TextureFormat.R8Sint) return 1;

		// 16-bit formats
		if (format === gpu.TextureFormat.R16Uint || format === gpu.TextureFormat.R16Sint || format === gpu.TextureFormat.R16Float || format === gpu.TextureFormat.RG8Unorm || format === gpu.TextureFormat.RG8Snorm || format === gpu.TextureFormat.RG8Uint || format === gpu.TextureFormat.RG8Sint) return 2;

		// 32-bit formats
		if (format === gpu.TextureFormat.R32Uint || format === gpu.TextureFormat.R32Sint || format === gpu.TextureFormat.R32Float || format === gpu.TextureFormat.RG16Uint || format === gpu.TextureFormat.RG16Sint || format === gpu.TextureFormat.RG16Float || format === gpu.TextureFormat.RGBA8Unorm || format === gpu.TextureFormat.RGBA8UnormSRGB || format === gpu.TextureFormat.RGBA8Snorm || format === gpu.TextureFormat.RGBA8Uint || format === gpu.TextureFormat.RGBA8Sint || format === gpu.TextureFormat.BGRA8Unorm || format === gpu.TextureFormat.BGRA8UnormSRGB) return 4;

		// 64-bit formats
		if (format === gpu.TextureFormat.RG32Uint || format === gpu.TextureFormat.RG32Sint || format === gpu.TextureFormat.RG32Float || format === gpu.TextureFormat.RGBA16Uint || format === gpu.TextureFormat.RGBA16Sint || format === gpu.TextureFormat.RGBA16Float) return 8;

		// 128-bit formats
		if (format === gpu.TextureFormat.RGBA32Uint || format === gpu.TextureFormat.RGBA32Sint || format === gpu.TextureFormat.RGBA32Float) return 16;

	}

	private function _getTypedArrayType(format: Int): Class<Dynamic> {
		if (format === gpu.TextureFormat.R8Uint) return Uint8Array;
		if (format === gpu.TextureFormat.R8Sint) return Int8Array;
		if (format === gpu.TextureFormat.R8Unorm) return Uint8Array;
		if (format === gpu.TextureFormat.R8Snorm) return Int8Array;
		if (format === gpu.TextureFormat.RG8Uint) return Uint8Array;
		if (format === gpu.TextureFormat.RG8Sint) return Int8Array;
		if (format === gpu.TextureFormat