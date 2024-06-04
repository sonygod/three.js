import webgpu.GPUTextureFormat;
import webgpu.GPUAddressMode;
import webgpu.GPUFilterMode;
import webgpu.GPUTextureDimension;
import webgpu.GPUFeatureName;
import webgpu.GPUTextureUsage;
import webgpu.GPUMapMode;
import webgpu.GPUBufferUsage;
import three.Texture;
import three.CubeTexture;
import three.NearestFilter;
import three.NearestMipmapNearestFilter;
import three.NearestMipmapLinearFilter;
import three.RepeatWrapping;
import three.MirroredRepeatWrapping;
import three.RGB_ETC2_Format;
import three.RGBA_ETC2_EAC_Format;
import three.RGBAFormat;
import three.RGBFormat;
import three.RedFormat;
import three.RGFormat;
import three.RGBA_S3TC_DXT1_Format;
import three.RGBA_S3TC_DXT3_Format;
import three.RGBA_S3TC_DXT5_Format;
import three.UnsignedByteType;
import three.FloatType;
import three.HalfFloatType;
import three.SRGBColorSpace;
import three.DepthFormat;
import three.DepthStencilFormat;
import three.RGBA_ASTC_4x4_Format;
import three.RGBA_ASTC_5x4_Format;
import three.RGBA_ASTC_5x5_Format;
import three.RGBA_ASTC_6x5_Format;
import three.RGBA_ASTC_6x6_Format;
import three.RGBA_ASTC_8x5_Format;
import three.RGBA_ASTC_8x6_Format;
import three.RGBA_ASTC_8x8_Format;
import three.RGBA_ASTC_10x5_Format;
import three.RGBA_ASTC_10x6_Format;
import three.RGBA_ASTC_10x8_Format;
import three.RGBA_ASTC_10x10_Format;
import three.RGBA_ASTC_12x10_Format;
import three.RGBA_ASTC_12x12_Format;
import three.UnsignedIntType;
import three.UnsignedShortType;
import three.UnsignedInt248Type;
import three.UnsignedInt5999Type;
import three.NeverCompare;
import three.AlwaysCompare;
import three.LessCompare;
import three.LessEqualCompare;
import three.EqualCompare;
import three.GreaterEqualCompare;
import three.GreaterCompare;
import three.NotEqualCompare;
import three.IntType;
import three.RedIntegerFormat;
import three.RGIntegerFormat;
import three.RGBAIntegerFormat;
import three.CubeReflectionMapping;
import three.CubeRefractionMapping;
import three.EquirectangularReflectionMapping;
import three.EquirectangularRefractionMapping;
import three.DepthTexture;
import webgpu.GPUDevice;
import webgpu.GPUSamplerDescriptor;
import webgpu.GPUTextureDescriptor;
import webgpu.GPUTexture;
import webgpu.GPUCommandEncoder;
import webgpu.GPUBuffer;
import webgpu.GPUBufferDescriptor;
import webgpu.GPUCommandBuffer;
import webgpu.GPUQueue;
import webgpu.VideoFrame;
import webgpu.GPUExtent3D;

class WebGPUTextureUtils {

	var backend:Dynamic;
	var _passUtils:Dynamic;
	var defaultTexture:Map<GPUTextureFormat,Texture>;
	var defaultCubeTexture:Map<GPUTextureFormat,CubeTexture>;
	var colorBuffer:GPUTexture;
	var depthTexture:DepthTexture;

	public function new(backend:Dynamic) {
		this.backend = backend;
		this._passUtils = null;
		this.defaultTexture = new Map();
		this.defaultCubeTexture = new Map();
		this.colorBuffer = null;
		this.depthTexture = new DepthTexture();
		this.depthTexture.name = "depthBuffer";
	}

	public function createSampler(texture:Texture) {
		var backend = this.backend;
		var device = backend.device;
		var textureGPU = backend.get(texture);
		var samplerDescriptorGPU:GPUSamplerDescriptor = {
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
		var textureGPU:GPUTexture;
		var format = getFormat(texture);
		if (texture.isCubeTexture) {
			textureGPU = this._getDefaultCubeTextureGPU(format);
		} else {
			textureGPU = this._getDefaultTextureGPU(format);
		}
		this.backend.get(texture).texture = textureGPU;
	}

	public function createTexture(texture:Texture, options:Dynamic = {}) {
		var backend = this.backend;
		var textureData = backend.get(texture);
		if (textureData.initialized) {
			throw new Error("WebGPUTextureUtils: Texture already initialized.");
		}
		if (options.needsMipmaps == null) options.needsMipmaps = false;
		if (options.levels == null) options.levels = 1;
		if (options.depth == null) options.depth = 1;
		var width = options.width;
		var height = options.height;
		var depth = options.depth;
		var levels = options.levels;
		var dimension = this._getDimension(texture);
		var format = texture.internalFormat || options.format || getFormat(texture, backend.device);
		var sampleCount = options.sampleCount != null ? options.sampleCount : 1;
		if (sampleCount > 1) {
			sampleCount = Math.pow(2, Math.floor(Math.log2(sampleCount)));
			if (sampleCount == 2) {
				sampleCount = 4;
			}
		}
		var primarySampleCount = texture.isRenderTargetTexture ? 1 : sampleCount;
		var usage = GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.COPY_SRC;
		if (texture.isStorageTexture == true) {
			usage |= GPUTextureUsage.STORAGE_BINDING;
		}
		if (texture.isCompressedTexture != true) {
			usage |= GPUTextureUsage.RENDER_ATTACHMENT;
		}
		var textureDescriptorGPU:GPUTextureDescriptor = {
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
		if (texture.isVideoTexture) {
			var video = texture.source.data;
			var videoFrame = new VideoFrame(video);
			textureDescriptorGPU.size.width = videoFrame.displayWidth;
			textureDescriptorGPU.size.height = videoFrame.displayHeight;
			videoFrame.close();
			textureData.externalTexture = video;
		} else {
			if (format == null) {
				console.warn("WebGPURenderer: Texture format not supported.");
				return this.createDefaultTexture(texture);
			}
			textureData.texture = backend.device.createTexture(textureDescriptorGPU);
		}
		if (texture.isRenderTargetTexture && sampleCount > 1) {
			var msaaTextureDescriptorGPU:GPUTextureDescriptor = {
				label: textureDescriptorGPU.label + "-msaa",
				size: textureDescriptorGPU.size,
				mipLevelCount: textureDescriptorGPU.mipLevelCount,
				sampleCount: sampleCount,
				dimension: textureDescriptorGPU.dimension,
				format: textureDescriptorGPU.format,
				usage: textureDescriptorGPU.usage
			};
			textureData.msaaTexture = backend.device.createTexture(msaaTextureDescriptorGPU);
		}
		textureData.initialized = true;
		textureData.textureDescriptorGPU = textureDescriptorGPU;
	}

	public function destroyTexture(texture:Texture) {
		var backend = this.backend;
		var textureData = backend.get(texture);
		textureData.texture.destroy();
		if (textureData.msaaTexture != null) textureData.msaaTexture.destroy();
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
			for (var i in 0...6) {
				this._generateMipmaps(textureData.texture, textureData.textureDescriptorGPU, i);
			}
		} else {
			this._generateMipmaps(textureData.texture, textureData.textureDescriptorGPU);
		}
	}

	public function getColorBuffer():GPUTexture {
		if (this.colorBuffer != null) this.colorBuffer.destroy();
		var backend = this.backend;
		var width = backend.getDrawingBufferSize().width;
		var height = backend.getDrawingBufferSize().height;
		this.colorBuffer = backend.device.createTexture({
			label: "colorBuffer",
			size: {
				width: width,
				height: height,
				depthOrArrayLayers: 1
			},
			sampleCount: backend.parameters.sampleCount,
			format: GPUTextureFormat.BGRA8Unorm,
			usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC
		});
		return this.colorBuffer;
	}

	public function getDepthBuffer(depth:Bool = true, stencil:Bool = false):GPUTexture {
		var backend = this.backend;
		var width = backend.getDrawingBufferSize().width;
		var height = backend.getDrawingBufferSize().height;
		var depthTexture = this.depthTexture;
		var depthTextureGPU = backend.get(depthTexture).texture;
		var format:GPUTextureFormat;
		var type:Int;
		if (stencil) {
			format = DepthStencilFormat;
			type = UnsignedInt248Type;
		} else if (depth) {
			format = DepthFormat;
			type = UnsignedIntType;
		}
		if (depthTextureGPU != null) {
			if (depthTexture.image.width == width && depthTexture.image.height == height && depthTexture.format == format && depthTexture.type == type) {
				return depthTextureGPU;
			}
			this.destroyTexture(depthTexture);
		}
		depthTexture.name = "depthBuffer";
		depthTexture.format = format;
		depthTexture.type = type;
		depthTexture.image.width = width;
		depthTexture.image.height = height;
		this.createTexture(depthTexture, {
			sampleCount: backend.parameters.sampleCount,
			width: width,
			height: height
		});
		return backend.get(depthTexture).texture;
	}

	public function updateTexture(texture:Texture, options:Dynamic) {
		var textureData = this.backend.get(texture);
		var textureDescriptorGPU = textureData.textureDescriptorGPU;
		if (texture.isRenderTargetTexture || (textureDescriptorGPU == null)) return;
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
		textureData.version = texture.version;
		if (texture.onUpdate != null) texture.onUpdate(texture);
	}

	public async function copyTextureToBuffer(texture:Texture, x:Int, y:Int, width:Int, height:Int):Dynamic {
		var device = this.backend.device;
		var textureData = this.backend.get(texture);
		var textureGPU = textureData.texture;
		var format = textureData.textureDescriptorGPU.format;
		var bytesPerTexel = this._getBytesPerTexel(format);
		var bytesPerRow = width * bytesPerTexel;
		bytesPerRow = Math.ceil(bytesPerRow / 256) * 256;
		var readBuffer = device.createBuffer({
			size: width * height * bytesPerTexel,
			usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ
		});
		var encoder = device.createCommandEncoder();
		encoder.copyTextureToBuffer({
			texture: textureGPU,
			origin: {
				x: x,
				y: y
			}
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

	public function _isEnvironmentTexture(texture:Texture):Bool {
		var mapping = texture.mapping;
		return (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) || (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
	}

	public function _getDefaultTextureGPU(format:GPUTextureFormat):GPUTexture {
		var defaultTexture = this.defaultTexture.get(format);
		if (defaultTexture == null) {
			var texture = new Texture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;
			this.createTexture(texture, {
				width: 1,
				height: 1,
				format: format
			});
			this.defaultTexture.set(format, texture);
			defaultTexture = texture;
		}
		return this.backend.get(defaultTexture).texture;
	}

	public function _getDefaultCubeTextureGPU(format:GPUTextureFormat):GPUTexture {
		var defaultCubeTexture = this.defaultCubeTexture.get(format);
		if (defaultCubeTexture == null) {
			var texture = new CubeTexture();
			texture.minFilter = NearestFilter;
			texture.magFilter = NearestFilter;
			this.createTexture(texture, {
				width: 1,
				height: 1,
				depth: 6
			});
			this.defaultCubeTexture.set(format, texture);
			defaultCubeTexture = texture;
		}
		return this.backend.get(defaultCubeTexture).texture;
	}

	public function _copyCubeMapToTexture(images:Array<Dynamic>, textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, flipY:Bool) {
		for (var i in 0...6) {
			var image = images[i];
			var flipIndex = flipY == true ? _flipMap[i] : i;
			if (image.isDataTexture) {
				this._copyBufferToTexture(image.image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
			} else {
				this._copyImageToTexture(image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
			}
		}
	}

	public function _copyImageToTexture(image:Dynamic, textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, originDepth:Int, flipY:Bool) {
		var device = this.backend.device;
		device.queue.copyExternalImageToTexture({
			source: image
		}, {
			texture: textureGPU,
			mipLevel: 0,
			origin: {
				x: 0,
				y: 0,
				z: originDepth
			}
		}, {
			width: image.width,
			height: image.height,
			depthOrArrayLayers: 1
		});
		if (flipY == true) {
			this._flipY(textureGPU, textureDescriptorGPU, originDepth);
		}
	}

	public function _getPassUtils():Dynamic {
		var passUtils = this._passUtils;
		if (passUtils == null) {
			this._passUtils = passUtils = new WebGPUTexturePassUtils(this.backend.device);
		}
		return passUtils;
	}

	public function _generateMipmaps(textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, baseArrayLayer:Int = 0) {
		this._getPassUtils().generateMipmaps(textureGPU, textureDescriptorGPU, baseArrayLayer);
	}

	public function _flipY(textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, originDepth:Int = 0) {
		this._getPassUtils().flipY(textureGPU, textureDescriptorGPU, originDepth);
	}

	public function _copyBufferToTexture(image:Dynamic, textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, originDepth:Int, flipY:Bool, depth:Int = 0) {
		var device = this.backend.device;
		var data = image.data;
		var bytesPerTexel = this._getBytesPerTexel(textureDescriptorGPU.format);
		var bytesPerRow = image.width * bytesPerTexel;
		device.queue.writeTexture({
			texture: textureGPU,
			mipLevel: 0,
			origin: {
				x: 0,
				y: 0,
				z: originDepth
			}
		}, data, {
			offset: image.width * image.height * bytesPerTexel * depth,
			bytesPerRow: bytesPerRow
		}, {
			width: image.width,
			height: image.height,
			depthOrArrayLayers: 1
		});
		if (flipY == true) {
			this._flipY(textureGPU, textureDescriptorGPU, originDepth);
		}
	}

	public function _copyCompressedBufferToTexture(mipmaps:Array<Dynamic>, textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor) {
		var device = this.backend.device;
		var blockData = this._getBlockData(textureDescriptorGPU.format);
		for (var i in 0...mipmaps.length) {
			var mipmap = mipmaps[i];
			var width = mipmap.width;
			var height = mipmap.height;
			var bytesPerRow = Math.ceil(width / blockData.width) * blockData.byteLength;
			device.queue.writeTexture({
				texture: textureGPU,
				mipLevel: i
			}, mipmap.data, {
				offset: 0,
				bytesPerRow: bytesPerRow
			}, {
				width: Math.ceil(width / blockData.width) * blockData.width,
				height: Math.ceil(height / blockData.width) * blockData.width,
				depthOrArrayLayers: 1
			});
		}
	}

	public function _getBlockData(format:GPUTextureFormat):Dynamic {
		if (format == GPUTextureFormat.BC1RGBAUnorm || format == GPUTextureFormat.BC1RGBAUnormSRGB) return {
			byteLength: 8,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.BC2RGBAUnorm || format == GPUTextureFormat.BC2RGBAUnormSRGB) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.BC3RGBAUnorm || format == GPUTextureFormat.BC3RGBAUnormSRGB) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.BC4RUnorm || format == GPUTextureFormat.BC4RSNorm) return {
			byteLength: 8,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.BC5RGUnorm || format == GPUTextureFormat.BC5RGSnorm) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.BC6HRGBUFloat || format == GPUTextureFormat.BC6HRGBFloat) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.BC7RGBAUnorm || format == GPUTextureFormat.BC7RGBAUnormSRGB) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.ETC2RGB8Unorm || format == GPUTextureFormat.ETC2RGB8UnormSRGB) return {
			byteLength: 8,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.ETC2RGB8A1Unorm || format == GPUTextureFormat.ETC2RGB8A1UnormSRGB) return {
			byteLength: 8,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.ETC2RGBA8Unorm || format == GPUTextureFormat.ETC2RGBA8UnormSRGB) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.EACR11Unorm) return {
			byteLength: 8,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.EACR11Snorm) return {
			byteLength: 8,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.EACRG11Unorm) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.EACRG11Snorm) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.ASTC4x4Unorm || format == GPUTextureFormat.ASTC4x4UnormSRGB) return {
			byteLength: 16,
			width: 4,
			height: 4
		};
		if (format == GPUTextureFormat.ASTC5x4Unorm || format == GPUTextureFormat.ASTC5x4UnormSRGB) return {
			byteLength: 16,
			width: 5,
			height: 4
		};
		if (format == GPUTextureFormat.ASTC5x5Unorm || format == GPUTextureFormat.ASTC5x5UnormSRGB) return {
			byteLength: 16,
			width: 5,
			height: 5
		};
		if (format == GPUTextureFormat.ASTC6x5Unorm || format == GPUTextureFormat.ASTC6x5UnormSRGB) return {
			byteLength: 16,
			width: 6,
			height: 5
		};
		if (format == GPUTextureFormat.ASTC6x6Unorm || format == GPUTextureFormat.ASTC6x6UnormSRGB) return {
			byteLength: 16,
			width: 6,
			height: 6
		};
		if (format == GPUTextureFormat.ASTC8x5Unorm || format == GPUTextureFormat.ASTC8x5UnormSRGB) return {
			byteLength: 16,
			width: 8,
			height: 5
		};
		if (format == GPUTextureFormat.ASTC8x6Unorm || format == GPUTextureFormat.ASTC8x6UnormSRGB) return {
			byteLength: 16,
			width: 8,
			height: 6
		};
		if (format == GPUTextureFormat.ASTC8x8Unorm || format == GPUTextureFormat.ASTC8x8UnormSRGB) return {
			byteLength: 16,
			width: 8,
			height: 8
		};
		if (format == GPUTextureFormat.ASTC10x5Unorm || format == GPUTextureFormat.ASTC10x5UnormSRGB) return {
			byteLength: 16,
			width: 10,
			height: 5
		};
		if (format == GPUTextureFormat.ASTC10x6Unorm || format == GPUTextureFormat.ASTC10x6UnormSRGB) return {
			byteLength: 16,
			width: 10,
			height: 6
		};
		if (format == GPUTextureFormat.ASTC10x8Unorm || format == GPUTextureFormat.ASTC10x8UnormSRGB) return {
			byteLength: 16,
			width: 10,
			height: 8
		};
		if (format == GPUTextureFormat.ASTC10x10Unorm || format == GPUTextureFormat.ASTC10x10UnormSRGB) return {
			byteLength: 16,
			width: 10,
			height: 10
		};
		if (format == GPUTextureFormat.ASTC12x10Unorm || format == GPUTextureFormat.ASTC12x10UnormSRGB) return {
			byteLength: 16,
			width: 12,
			height: 10
		};
		if (format == GPUTextureFormat.ASTC12x12Unorm || format == GPUTextureFormat.ASTC12x12UnormSRGB) return {
			byteLength: 16,
			width: 12,
			height: 12
		};
	}

	public function _convertAddressMode(value:Int):GPUAddressMode {
		var addressMode = GPUAddressMode.ClampToEdge;
		if (value == RepeatWrapping) {
			addressMode = GPUAddressMode.Repeat;
		} else if (value == MirroredRepeatWrapping) {
			addressMode = GPUAddressMode.MirrorRepeat;
		}
		return addressMode;
	}

	public function _convertFilterMode(value:Int):GPUFilterMode {
		var filterMode = GPUFilterMode.Linear;
		if (value == NearestFilter || value == NearestMipmapNearestFilter || value == NearestMipmapLinearFilter) {
			filterMode = GPUFilterMode.Nearest;
		}
		return filterMode;
	}

	public function _getBytesPerTexel(format:GPUTextureFormat):Int {
		if (format == GPUTextureFormat.R8Unorm || format == GPUTextureFormat.R8Snorm || format == GPUTextureFormat.R8Uint || format == GPUTextureFormat.R8Sint) return 1;
		if (format == GPUTextureFormat.R16Uint || format == GPUTextureFormat.R16Sint || format == GPUTextureFormat.R16Float || format == GPUTextureFormat.RG8Unorm || format == GPUTextureFormat.RG8Snorm || format == GPUTextureFormat.RG8Uint || format == GPUTextureFormat.RG8Sint) return 2;
		if (format == GPUTextureFormat.R32Uint || format == GPUTextureFormat.R32Sint || format == GPUTextureFormat.R32Float || format == GPUTextureFormat.RG16Uint || format == GPUTextureFormat.RG16Sint || format == GPUTextureFormat.RG16Float || format == GPUTextureFormat.RGBA8Unorm || format == GPUTextureFormat.RGBA8UnormSRGB || format == GPUTextureFormat.RGBA8Snorm || format == GPUTextureFormat.RGBA8Uint || format == GPUTextureFormat.RGBA8Sint || format == GPUTextureFormat.BGRA8Unorm || format == GPUTextureFormat.BGRA8UnormSRGB || format == GPUTextureFormat.RGB9E5UFloat || format == GPUTextureFormat.RGB10A2Unorm || format == GPUTextureFormat.RG11B10UFloat || format == GPUTextureFormat.Depth32Float || format == GPUTextureFormat.Depth24Plus || format == GPUTextureFormat.Depth24PlusStencil8 || format == GPUTextureFormat.Depth32FloatStencil8) return 4;
		if (format == GPUTextureFormat.RG32Uint || format == GPUTextureFormat.RG32Sint || format == GPUTextureFormat.RG32Float || format == GPUTextureFormat.RGBA16Uint || format == GPUTextureFormat.RGBA16Sint || format == GPUTextureFormat.RGBA16Float) return 8;
		if (format == GPUTextureFormat.RGBA32Uint || format == GPUTextureFormat.RGBA32Sint || format == GPUTextureFormat.RGBA32Float) return 16;
		return 0;
	}

	public function _getTypedArrayType(format:GPUTextureFormat):Dynamic {
		if (format == GPUTextureFormat.R8Uint) return Uint8Array;
		if (format == GPUTextureFormat.R8Sint) return Int8Array;
		if (format == GPUTextureFormat.R8Unorm) return Uint8Array;
		if (format == GPUTextureFormat.R8Snorm) return Int8Array;
		if (format == GPUTextureFormat.RG8Uint) return Uint8Array;
		if (format == GPUTextureFormat.RG8Sint) return Int8Array;
		if (format == GPUTextureFormat.RG8Unorm) return Uint8Array;
		if (format == GPUTextureFormat.RG8Snorm) return Int8Array;
		if (format == GPUTextureFormat.RGBA8Uint) return Uint8Array;
		if (format == GPUTextureFormat.RGBA8Sint) return Int8Array;
		if (format == GPUTextureFormat.RGBA8Unorm) return Uint8Array;
		if (format == GPUTextureFormat.RGBA8Snorm) return Int8Array;
		if (format == GPUTextureFormat.R16Uint) return Uint16Array;
		if (format == GPUTextureFormat.R16Sint) return Int16Array;
		if (format == GPUTextureFormat.RG16Uint) return Uint16Array;
		if (format == GPUTextureFormat.RG16Sint) return Int16Array;
		if (format == GPUTextureFormat.RGBA16Uint) return Uint16Array;
		if (format == GPUTextureFormat.RGBA16Sint) return Int16Array;
		if (format == GPUTextureFormat.R16Float) return Float32Array;
		if (format == GPUTextureFormat.RG16Float) return Float32Array;
		if (format == GPUTextureFormat.RGBA16Float) return Float32Array;
		if (format == GPUTextureFormat.R32Uint) return Uint32Array;
		if (format == GPUTextureFormat.R32Sint) return Int32Array;
		if (format == GPUTextureFormat.R32Float) return Float32Array;
		if (format == GPUTextureFormat.RG32Uint) return Uint32Array;
		if (format == GPUTextureFormat.RG32Sint) return Int32Array;
		if (format == GPUTextureFormat.RG32Float) return Float32Array;
		if (format == GPUTextureFormat.RGBA32Uint) return Uint32Array;
		if (format == GPUTextureFormat.RGBA32Sint) return Int32Array;
		if (format == GPUTextureFormat.RGBA32Float) return Float32Array;
		if (format == GPUTextureFormat.BGRA8Unorm) return Uint8Array;
		if (format == GPUTextureFormat.BGRA8UnormSRGB) return Uint8Array;
		if (format == GPUTextureFormat.RGB10A2Unorm) return Uint32Array;
		if (format == GPUTextureFormat.RGB9E5UFloat) return
		if (format == GPUTextureFormat.RGB9E5UFloat) return Uint32Array;
		if (format == GPUTextureFormat.RG11B10UFloat) return Uint32Array;
		if (format == GPUTextureFormat.Depth32Float) return Float32Array;
		if (format == GPUTextureFormat.Depth24Plus) return Uint32Array;
		if (format == GPUTextureFormat.Depth24PlusStencil8) return Uint32Array;
		if (format == GPUTextureFormat.Depth32FloatStencil8) return Float32Array;
		return null;
	}

	public function _getDimension(texture:Texture):GPUTextureDimension {
		var dimension:GPUTextureDimension;
		if (texture.isData3DTexture) {
			dimension = GPUTextureDimension.ThreeD;
		} else {
			dimension = GPUTextureDimension.TwoD;
		}
		return dimension;
	}

}

public function getFormat(texture:Texture, device:GPUDevice = null):GPUTextureFormat {
	var format = texture.format;
	var type = texture.type;
	var colorSpace = texture.colorSpace;
	var formatGPU:GPUTextureFormat;
	if (texture.isFramebufferTexture == true && texture.type == UnsignedByteType) {
		formatGPU = GPUTextureFormat.BGRA8Unorm;
	} else if (texture.isCompressedTexture == true) {
		switch (format) {
			case RGBA_S3TC_DXT1_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.BC1RGBAUnormSRGB : GPUTextureFormat.BC1RGBAUnorm;
				break;
			case RGBA_S3TC_DXT3_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.BC2RGBAUnormSRGB : GPUTextureFormat.BC2RGBAUnorm;
				break;
			case RGBA_S3TC_DXT5_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.BC3RGBAUnormSRGB : GPUTextureFormat.BC3RGBAUnorm;
				break;
			case RGB_ETC2_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ETC2RGB8UnormSRGB : GPUTextureFormat.ETC2RGB8Unorm;
				break;
			case RGBA_ETC2_EAC_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ETC2RGBA8UnormSRGB : GPUTextureFormat.ETC2RGBA8Unorm;
				break;
			case RGBA_ASTC_4x4_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC4x4UnormSRGB : GPUTextureFormat.ASTC4x4Unorm;
				break;
			case RGBA_ASTC_5x4_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC5x4UnormSRGB : GPUTextureFormat.ASTC5x4Unorm;
				break;
			case RGBA_ASTC_5x5_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC5x5UnormSRGB : GPUTextureFormat.ASTC5x5Unorm;
				break;
			case RGBA_ASTC_6x5_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC6x5UnormSRGB : GPUTextureFormat.ASTC6x5Unorm;
				break;
			case RGBA_ASTC_6x6_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC6x6UnormSRGB : GPUTextureFormat.ASTC6x6Unorm;
				break;
			case RGBA_ASTC_8x5_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC8x5UnormSRGB : GPUTextureFormat.ASTC8x5Unorm;
				break;
			case RGBA_ASTC_8x6_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC8x6UnormSRGB : GPUTextureFormat.ASTC8x6Unorm;
				break;
			case RGBA_ASTC_8x8_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC8x8UnormSRGB : GPUTextureFormat.ASTC8x8Unorm;
				break;
			case RGBA_ASTC_10x5_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC10x5UnormSRGB : GPUTextureFormat.ASTC10x5Unorm;
				break;
			case RGBA_ASTC_10x6_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC10x6UnormSRGB : GPUTextureFormat.ASTC10x6Unorm;
				break;
			case RGBA_ASTC_10x8_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC10x8UnormSRGB : GPUTextureFormat.ASTC10x8Unorm;
				break;
			case RGBA_ASTC_10x10_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC10x10UnormSRGB : GPUTextureFormat.ASTC10x10Unorm;
				break;
			case RGBA_ASTC_12x10_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC12x10UnormSRGB : GPUTextureFormat.ASTC12x10Unorm;
				break;
			case RGBA_ASTC_12x12_Format:
				formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.ASTC12x12UnormSRGB : GPUTextureFormat.ASTC12x12Unorm;
				break;
			default:
				console.error("WebGPURenderer: Unsupported texture format.", format);
		}
	} else {
		switch (format) {
			case RGBAFormat:
				switch (type) {
					case UnsignedByteType:
						formatGPU = (colorSpace == SRGBColorSpace) ? GPUTextureFormat.RGBA8UnormSRGB : GPUTextureFormat.RGBA8Unorm;
						break;
					case HalfFloatType:
						formatGPU = GPUTextureFormat.RGBA16Float;
						break;
					case FloatType:
						formatGPU = GPUTextureFormat.RGBA32Float;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RGBAFormat.", type);
				}
				break;
			case RGBFormat:
				switch (type) {
					case UnsignedInt5999Type:
						formatGPU = GPUTextureFormat.RGB9E5UFloat;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RGBFormat.", type);
				}
				break;
			case RedFormat:
				switch (type) {
					case UnsignedByteType:
						formatGPU = GPUTextureFormat.R8Unorm;
						break;
					case HalfFloatType:
						formatGPU = GPUTextureFormat.R16Float;
						break;
					case FloatType:
						formatGPU = GPUTextureFormat.R32Float;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RedFormat.", type);
				}
				break;
			case RGFormat:
				switch (type) {
					case UnsignedByteType:
						formatGPU = GPUTextureFormat.RG8Unorm;
						break;
					case HalfFloatType:
						formatGPU = GPUTextureFormat.RG16Float;
						break;
					case FloatType:
						formatGPU = GPUTextureFormat.RG32Float;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RGFormat.", type);
				}
				break;
			case DepthFormat:
				switch (type) {
					case UnsignedShortType:
						formatGPU = GPUTextureFormat.Depth16Unorm;
						break;
					case UnsignedIntType:
						formatGPU = GPUTextureFormat.Depth24Plus;
						break;
					case FloatType:
						formatGPU = GPUTextureFormat.Depth32Float;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with DepthFormat.", type);
				}
				break;
			case DepthStencilFormat:
				switch (type) {
					case UnsignedInt248Type:
						formatGPU = GPUTextureFormat.Depth24PlusStencil8;
						break;
					case FloatType:
						if (device != null && device.features.has(GPUFeatureName.Depth32FloatStencil8) == false) {
							console.error("WebGPURenderer: Depth textures with DepthStencilFormat + FloatType can only be used with the \"depth32float-stencil8\" GPU feature.");
						}
						formatGPU = GPUTextureFormat.Depth32FloatStencil8;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with DepthStencilFormat.", type);
				}
				break;
			case RedIntegerFormat:
				switch (type) {
					case IntType:
						formatGPU = GPUTextureFormat.R32Sint;
						break;
					case UnsignedIntType:
						formatGPU = GPUTextureFormat.R32Uint;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RedIntegerFormat.", type);
				}
				break;
			case RGIntegerFormat:
				switch (type) {
					case IntType:
						formatGPU = GPUTextureFormat.RG32Sint;
						break;
					case UnsignedIntType:
						formatGPU = GPUTextureFormat.RG32Uint;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RGIntegerFormat.", type);
				}
				break;
			case RGBAIntegerFormat:
				switch (type) {
					case IntType:
						formatGPU = GPUTextureFormat.RGBA32Sint;
						break;
					case UnsignedIntType:
						formatGPU = GPUTextureFormat.RGBA32Uint;
						break;
					default:
						console.error("WebGPURenderer: Unsupported texture type with RGBAIntegerFormat.", type);
				}
				break;
			default:
				console.error("WebGPURenderer: Unsupported texture format.", format);
		}
	}
	return formatGPU;
}

var _compareToWebGPU:Map<Int,String> = new Map();
_compareToWebGPU.set(NeverCompare, "never");
_compareToWebGPU.set(LessCompare, "less");
_compareToWebGPU.set(EqualCompare, "equal");
_compareToWebGPU.set(LessEqualCompare, "less-equal");
_compareToWebGPU.set(GreaterCompare, "greater");
_compareToWebGPU.set(GreaterEqualCompare, "greater-equal");
_compareToWebGPU.set(AlwaysCompare, "always");
_compareToWebGPU.set(NotEqualCompare, "not-equal");

var _flipMap:Array<Int> = [0, 1, 3, 2, 4, 5];

export default WebGPUTextureUtils;