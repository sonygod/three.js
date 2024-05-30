import js.webgpu.GPUTextureFormat;
import js.webgpu.GPUAddressMode;
import js.webgpu.GPUFilterMode;
import js.webgpu.GPUTextureDimension;
import js.webgpu.GPUFeatureName;

import js.three.CubeTexture;
import js.three.Texture;
import js.three.NearestFilter;
import js.three.NearestMipmapNearestFilter;
import js.three.NearestMipmapLinearFilter;
import js.three.RepeatWrapping;
import js.three.MirroredRepeatWrapping;
import js.three.RGB_ETC2_Format;
import js.three.RGBA_ETC2_EAC_Format;
import js.three.RGBAFormat;
import js.three.RGBFormat;
import js.three.RedFormat;
import js.three.RGFormat;
import js.three.RGBA_S3TC_DXT1_Format;
import js.three.RGBA_S3TC_DXT3_Format;
import js.three.RGBA_S3TC_DXT5_Format;
import js.three.UnsignedByteType;
import js.three.FloatType;
import js.three.HalfFloatType;
import js.three.SRGBColorSpace;
import js.three.DepthFormat;
import js.three.DepthStencilFormat;
import js.three.RGBA_ASTC_4x4_Format;
import js.three.RGBA_ASTC_5x4_Format;
import js.three.RGBA_ASTC_5x5_Format;
import js.three.RGBA_ASTC_6x5_Format;
import js.three.RGBA_ASTC_6x6_Format;
import js.three.RGBA_ASTC_8x5_Format;
import js.three.RGBA_ASTC_8x6_Format;
import js.three.RGBA_ASTC_8x8_Format;
import js.three.RGBA_ASTC_10x5_Format;
import js.three.RGBA_ASTC_10x6_Format;
import js.three.RGBA_ASTC_10x8_Format;
import js.three.RGBA_ASTC_10x10_Format;
import js.three.RGBA_ASTC_12x10_Format;
import js.three.RGBA_ASTC_12x12_Format;
import js.three.UnsignedIntType;
import js.three.UnsignedShortType;
import js.three.UnsignedInt248Type;
import js.three.UnsignedInt5999Type;
import js.three.NeverCompare;
import js.three.AlwaysCompare;
import js.three.LessCompare;
import js.three.LessEqualCompare;
import js.three.EqualCompare;
import js.three.GreaterEqualCompare;
import js.three.GreaterCompare;
import js.three.NotEqualCompare;
import js.three.IntType;
import js.three.RedIntegerFormat;
import js.three.RGIntegerFormat;
import js.three.RGBAIntegerFormat;
import js.three.CubeReflectionMapping;
import js.three.CubeRefractionMapping;
import js.three.EquirectangularReflectionMapping;
import js.three.EquirectangularRefractionMapping;
import js.three.DepthTexture;

import js.three.WebGPUTexturePassUtils;

class WebGPUTextureUtils {
	public var backend:Dynamic;
	public var _passUtils:WebGPUTexturePassUtils;
	public var defaultTexture:Map<GPUTextureFormat, Texture>;
	public var defaultCubeTexture:Map<GPUTextureFormat, CubeTexture>;
	public var colorBuffer:Dynamic;
	public var depthTexture:DepthTexture;

	public function new(backend:Dynamic) {
		this.backend = backend;
		this._passUtils = null;
		this.defaultTexture = Map();
		this.defaultCubeTexture = Map();
		this.colorBuffer = null;
		this.depthTexture = new DepthTexture();
		this.depthTexture.name = 'depthBuffer';
	}

	public function createSampler(texture:Texture) {
		var backend = this.backend;
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

		if (texture.isDepthTexture && texture.compareFunction != null) {
			samplerDescriptorGPU.compare = _compareToWebGPU[texture.compareFunction];
		}

		textureGPU.sampler = device.createSampler(samplerDescriptorGPU);
	}

	public function createDefaultTexture(texture:Texture) {
		var textureGPU:Dynamic;
		var format = getFormat(texture);

		if (texture.isCubeTexture) {
			textureGPU = this._getDefaultCubeTextureGPU(format);
		} else {
			textureGPU = this._getDefaultTextureGPU(format);
		}

		this.backend.get(texture).texture = textureGPU;
	}

	public function createTexture(texture:Texture, ?options) {
		var backend = this.backend;
		var textureData = backend.get(texture);

		if (textureData.initialized) {
			throw new Error('WebGPUTextureUtils: Texture already initialized.');
		}

		var needsMipmaps = options.needsMipmaps ?? false;
		var levels = options.levels ?? 1;
		var depth = options.depth ?? 1;
		var width = options.width;
		var height = options.height;

		var dimension = this._getDimension(texture);
		var format = texture.internalFormat ?? options.format ?? getFormat(texture, backend.device);

		var sampleCount = options.sampleCount ?? 1;

		if (sampleCount > 1) {
			// WebGPU only supports power-of-two sample counts and 2 is not a valid value
			sampleCount = Math.pow(2, Math.floor(Math.log2(sampleCount)));

			if (sampleCount == 2) {
				sampleCount = 4;
			}
		}

		var primarySampleCount = texture.isRenderTargetTexture ? 1 : sampleCount;

		var usage = GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.COPY_SRC;

		if (texture.isStorageTexture) {
			usage |= GPUTextureUsage.STORAGE_BINDING;
		}

		if (!texture.isCompressedTexture) {
			usage |= GPUTextureUsage.RENDER_ATTACHMENT;
		}

		var textureDescriptorGPU = {
			label: texture.name,
			size: {
				width: width,
				height: height,
				depthOrArrayLayers: depth
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
			if (format == null) {
				console.warn('WebGPURenderer: Texture format not supported.');
				return this.createDefaultTexture(texture);
			}

			textureData.texture = backend.device.createTexture(textureDescriptorGPU);
		}

		if (texture.isRenderTargetTexture && sampleCount > 1) {
			var msaaTextureDescriptorGPU = Object.assign({}, textureDescriptorGPU);

			msaaTextureDescriptorGPU.label = msaaTextureDescriptorGPU.label + '-msaa';
			msaaTextureDescriptorGPU.sampleCount = sampleCount;

			textureData.msaaTexture = backend.device.createTexture(msaaTextureDescriptorGPU);
		}

		textureData.initialized = true;
		textureData.textureDescriptorGPU = textureDescriptorGPU;
	}

	public function destroyTexture(texture:Texture) {
		var backend = this.backend;
		var textureData = backend.get(texture);

		textureData.texture.destroy();

		if (textureData.msaaTexture != null) {
			textureData.msaaTexture.destroy();
		}

		backend.delete(texture);
	}

	public function destroySampler(texture:Texture) {
		var backend = this.backend;
		var textureData = backend.get(texture);

		delete textureData.sampler;
	}

	public function generateMipmaps(texture:Texture) {
		var textureData = this.backend.get(texture);

		if (texture.isCubeTexture) {
			for (i in 0...6) {
				this._generateMipmaps(textureData.texture, textureData.textureDescriptorGPU, i);
			}
		} else {
			this._generateMipmaps(textureData.texture, textureData.textureDescriptorGPU);
		}
	}

	public function getColorBuffer():Dynamic {
		if (this.colorBuffer != null) {
			this.colorBuffer.destroy();
		}

		var backend = this.backend;
		var size = backend.getDrawingBufferSize();

		this.colorBuffer = backend.device.createTexture({
			label: 'colorBuffer',
			size: {
				width: size.width,
				height: size.height,
				depthOrArrayLayers: 1
			},
			sampleCount: backend.parameters.sampleCount,
			format: GPUTextureFormat.BGRA8Unorm,
			usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC
		});

		return this.colorBuffer;
	}

	public function getDepthBuffer(depth = true, stencil = false):Dynamic {
		var backend = this.backend;
		var size = backend.getDrawingBufferSize();

		var depthTexture = this.depthTexture;
		var depthTextureGPU = backend.get(depthTexture).texture;

		var format:Dynamic, type:Dynamic;

		if (stencil) {
			format = DepthStencilFormat;
			type = UnsignedInt248Type;
		} else if (depth) {
			format = DepthFormat;
			type = UnsignedIntType;
		}

		if (depthTextureGPU != null) {
			if (depthTexture.image.width == size.width && depthTexture.image.height == size.height && depthTexture.format == format && depthTexture.type == type) {
				return depthTextureGPU;
			}

			this.destroyTexture(depthTexture);
		}

		depthTexture.name = 'depthBuffer';
		depthTexture.format = format;
		depthTexture.type = type;
		depthTexture.image.width = size.width;
		depthTexture.image.height = size.height;

		this.createTexture(depthTexture, { sampleCount: backend.parameters.sampleCount, width: size.width, height: size.height });

		return backend.get(depthTexture).texture;
	}

	public function updateTexture(texture:Texture, options:Dynamic) {
		var textureData = this.backend.get(texture);
		var textureDescriptorGPU = textureData.textureDescriptorGPU;

		if (texture.isRenderTargetTexture || textureDescriptorGPU == null) {
			return;
		}

		// transfer texture data

		if (texture.isDataTexture || texture.isData3DTexture) {
			this._copyBufferToTexture(options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY);
		} else if (texture.isDataArrayTexture) {
			for (i in 0...options.image.depth) {
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

		if (texture.onUpdate != null) {
			texture.onUpdate(texture);
		}
	}

	public async function copyTextureToBuffer(texture:Texture, x:Int, y:Int, width:Int, height:Int):Async<Dynamic> {
		var device = this.backend.device;
		var textureData = this.backend.get(texture);
		var textureGPU = textureData.texture;
		var format = textureData.textureDescriptorGPU.format;
		var bytesPerTexel = this._getBytesPerTexel(format);

		var bytesPerRow = width * bytesPerTexel;
		bytesPerRow = Math.ceil(bytesPerRow / 256) * 256; // Align to 256 bytes

		var readBuffer = device.createBuffer({
			size: width * height * bytesPerTexel,
			usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
		});

		var encoder = device.createCommandEncoder();

		encoder.copyTextureToBuffer({
			texture: textureGPU,
			origin: { x: x, y: y }
		}, {
			buffer: readBuffer,
			bytesPerRow: bytesPerRow
		}, {
			width: width,
			height: height
		});

		var typedArrayType = this._getTypedArrayType(format);

		device.queue.submit([encoder.finish()]);

		await readBuffer.mapAsync(GPUMapMode.READ);

		var buffer = readBuffer.getMappedRange();

		return new typedArrayType(buffer);
	}

	private function _isEnvironmentTexture(texture:Texture):Bool {
		var mapping = texture.mapping;

		return (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) || (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
	}

	private function _getDefaultTextureGPU(format:GPUTextureFormat):Dynamic {
		var defaultTexture = this.defaultTexture.get(format);

		if (defaultTexture == null) {
			var texture = new Texture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture(texture, { width: 1, height: 1, format: format });

			this.defaultTexture[format] = defaultTexture = texture;
		}

		return this.backend.get(defaultTexture).texture;
	}

	private function _getDefaultCubeTextureGPU(format:GPUTextureFormat):Dynamic {
		var defaultCubeTexture = this.defaultCubeTexture.get(format);

		if (defaultCubeTexture == null) {
			var texture = new CubeTexture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;

			this.createTexture(texture, { width: 1, height: 1, depth: 6, format: format });

			this.defaultCubeTexture[format] = defaultCubeTexture = texture;
		}

		return this.backend.get(defaultCubeTexture).texture;
	}

	private function _copyCubeMapToTexture(images:Array<Dynamic>, textureGPU:Dynamic, textureDescriptorGPU:Dynamic, flipY:Bool) {
		for (i in 0...6) {
			var image = images[i];
			var flipIndex = flipY ? _flipMap[i] : i;

			if (image.isDataTexture) {
				this._copyBufferToTexture(image.image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
			} else {
				this._copyImageToTexture(image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
			}
		}
	}

	private function _copyImageToTexture(image:Dynamic, textureGPU:Dynamic, textureDescriptorGPU:Dynamic, originDepth:Int, flipY:Bool) {
		var device = this.backend.device;

		device.queue.copyExternalImageToTexture({
			source: image
		}, {
			texture: textureGPU,
			mipLevel: 0