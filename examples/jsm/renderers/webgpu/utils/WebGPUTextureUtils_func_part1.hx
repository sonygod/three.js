package three.js.examples.webgpu.utils;

import three.js.WebGPUConstants;
import three.js.Texture;
import three.js.CubeTexture;
import three.js.DepthTexture;
import three.js.NearestFilter;
import three.js.NearestMipmapNearestFilter;
import three.js.NearestMipmapLinearFilter;
import three.js.RepeatWrapping;
import three.js.MirroredRepeatWrapping;
import three.js.RGB_ETC2_Format;
import three.js.RGBA_ETC2_EAC_Format;
import three.js.RGBFormat;
import three.js.RGFormat;
import three.js.RedFormat;
import three.js.Rgba_S3TC_DXT1_Format;
import three.js.Rgba_S3TC_DXT3_Format;
import three.js.Rgba_S3TC_DXT5_Format;
import three.js.UnsignedByteType;
import three.js.FloatType;
import three.js.HalfFloatType;
import three.js.SRGBColorSpace;
import three.js.DepthFormat;
import three.js.DepthStencilFormat;
import three.js.RGBA_ASTC_4x4_Format;
import three.js.RGBA_ASTC_5x4_Format;
import three.js.RGBA_ASTC_5x5_Format;
import three.js.RGBA_ASTC_6x5_Format;
import three.js.RGBA_ASTC_6x6_Format;
import three.js.RGBA_ASTC_8x5_Format;
import three.js.RGBA_ASTC_8x6_Format;
import three.js.RGBA_ASTC_8x8_Format;
import three.js.RGBA_ASTC_10x5_Format;
import three.js.RGBA_ASTC_10x6_Format;
import three.js.RGBA_ASTC_10x8_Format;
import three.js.RGBA_ASTC_10x10_Format;
import three.js.RGBA_ASTC_12x10_Format;
import three.js.RGBA_ASTC_12x12_Format;
import three.js.UnsignedIntType;
import three.js.UnsignedShortType;
import three.js.UnsignedInt248Type;
import three.js.UnsignedInt5999Type;
import three.js.NeverCompare;
import three.js.AlwaysCompare;
import three.js.LessCompare;
import three.js.EqualCompare;
import three.js.LessEqualCompare;
import three.js.GreaterCompare;
import three.js.GreaterEqualCompare;
import three.js.NotEqualCompare;
import three.js.IntType;
import three.js.RedIntegerFormat;
import three.js.RGIntegerFormat;
import three.js.RGBAIntegerFormat;

class WebGPUTextureUtils {
    private var backend:WebGPUBackend;
    private var _passUtils:WebGPUTexturePassUtils;
    private var defaultTexture:Map<Int, Texture>;
    private var defaultCubeTexture:Map<Int, CubeTexture>;
    private var colorBuffer:Texture;
    private var depthTexture:DepthTexture;

    public function new(backend:WebGPUBackend) {
        this.backend = backend;
        _passUtils = null;
        defaultTexture = new Map<Int, Texture>();
        defaultCubeTexture = new Map<Int, CubeTexture>();
        colorBuffer = null;
        depthTexture = new DepthTexture();
        depthTexture.name = 'depthBuffer';
    }

    public function createSampler(texture:Texture):Void {
        var device:WebGPUDevice = backend.device;
        var textureGPU:WebGPUGPUTexture = backend.get(texture);
        var samplerDescriptorGPU:WebGPUSamplerDescriptor = {
            addressModeU: _convertAddressMode(texture.wrapS),
            addressModeV: _convertAddressMode(texture.wrapT),
            addressModeW: _convertAddressMode(texture.wrapR),
            magFilter: _convertFilterMode(texture.magFilter),
            minFilter: _convertFilterMode(texture.minFilter),
            mipmapFilter: _convertFilterMode(texture.minFilter),
            maxAnisotropy: texture.anisotropy
        };
        if (texture.isDepthTexture && texture.compareFunction != null) {
            samplerDescriptorGPU.compare = _compareToWebGPU[texture.compareFunction];
        }
        textureGPU.sampler = device.createSampler(samplerDescriptorGPU);
    }

    public function createDefaultTexture(texture:Texture):Void {
        var format:Int = getFormat(texture);
        if (texture.isCubeTexture) {
            var defaultCubeTexture:CubeTexture = _getDefaultCubeTextureGPU(format);
            backend.get(texture).texture = defaultCubeTexture;
        } else {
            var defaultTexture:Texture = _getDefaultTextureGPU(format);
            backend.get(texture).texture = defaultTexture;
        }
    }

    public function createTexture(texture:Texture, options:Dynamic = {}):Void {
        var backend:WebGPUBackend = this.backend;
        var textureData:WebGPUGPUTexture = backend.get(texture);
        if (textureData.initialized) {
            throw new Error('WebGPUTextureUtils: Texture already initialized.');
        }
        options.needsMipmaps = options.needsMipmaps != null ? options.needsMipmaps : false;
        options.levels = options.levels != null ? options.levels : 1;
        options.depth = options.depth != null ? options.depth : 1;
        var width:Int = options.width;
        var height:Int = options.height;
        var depth:Int = options.depth;
        var levels:Int = options.levels;
        var dimension:Int = _getDimension(texture);
        var format:Int = texture.internalFormat != null ? texture.internalFormat : options.format;
        var sampleCount:Int = options.sampleCount != null ? options.sampleCount : 1;
        if (sampleCount > 1) {
            sampleCount = Math.pow(2, Math.floor(Math.log(sampleCount) / Math.log(2)));
            if (sampleCount == 2) {
                sampleCount = 4;
            }
        }
        var primarySampleCount:Int = texture.isRenderTargetTexture ? 1 : sampleCount;
        var usage:WebGPUTextureUsage = WebGPUTextureUsage.TEXTURE_BINDING | WebGPUTextureUsage.COPY_DST | WebGPUTextureUsage.COPY_SRC;
        if (texture.isStorageTexture) {
            usage |= WebGPUTextureUsage.STORAGE_BINDING;
        }
        if (!texture.isCompressedTexture) {
            usage |= WebGPUTextureUsage.RENDER_ATTACHMENT;
        }
        var textureDescriptorGPU:WebGPUGPUTextureDescriptor = {
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
            var video:Video = texture.source.data;
            var videoFrame:VideoFrame = new VideoFrame(video);
            textureDescriptorGPU.size.width = videoFrame.displayWidth;
            textureDescriptorGPU.size.height = videoFrame.displayHeight;
            videoFrame.close();
            textureData.externalTexture = video;
        } else {
            if (format == null) {
                console.warn('WebGPURenderer: Texture format not supported.');
                createDefaultTexture(texture);
                return;
            }
            textureData.texture = backend.device.createTexture(textureDescriptorGPU);
        }
        if (texture.isRenderTargetTexture && sampleCount > 1) {
            var msaaTextureDescriptorGPU:WebGPUGPUTextureDescriptor = Object.assign({}, textureDescriptorGPU);
            msaaTextureDescriptorGPU.label += '-msaa';
            msaaTextureDescriptorGPU.sampleCount = sampleCount;
            textureData.msaaTexture = backend.device.createTexture(msaaTextureDescriptorGPU);
        }
        textureData.initialized = true;
        textureData.textureDescriptorGPU = textureDescriptorGPU;
    }

    public function destroyTexture(texture:Texture):Void {
        var backend:WebGPUBackend = this.backend;
        var textureData:WebGPUGPUTexture = backend.get(texture);
        textureData.texture.destroy();
        if (textureData.msaaTexture != null) {
            textureData.msaaTexture.destroy();
        }
        backend.delete(texture);
    }

    public function destroySampler(texture:Texture):Void {
        var backend:WebGPUBackend = this.backend;
        var textureData:WebGPUGPUTexture = backend.get(texture);
        delete textureData.sampler;
    }

    public function generateMipmaps(texture:Texture):Void {
        var textureData:WebGPUGPUTexture = this.backend.get(texture);
        if (texture.isCubeTexture) {
            for (i in 0...6) {
                _generateMipmaps(textureData.texture, textureData.textureDescriptorGPU, i);
            }
        } else {
            _generateMipmaps(textureData.texture, textureData.textureDescriptorGPU);
        }
    }

    public function getColorBuffer():Texture {
        if (colorBuffer != null) colorBuffer.destroy();
        var backend:WebGPUBackend = this.backend;
        var { width, height } = backend.getDrawingBufferSize();
        colorBuffer = backend.device.createTexture({
            label: 'colorBuffer',
            size: {
                width: width,
                height: height,
                depthOrArrayLayers: 1
            },
            format: WebGPUTextureFormat.BGRA8Unorm,
            usage: WebGPUTextureUsage.RENDER_ATTACHMENT | WebGPUTextureUsage.COPY_SRC
        });
        return colorBuffer;
    }

    public function getDepthBuffer(depth:Bool = true, stencil:Bool = false):WebGPUGPUTexture {
        var backend:WebGPUBackend = this.backend;
        var { width, height } = backend.getDrawingBufferSize();
        var depthTexture:DepthTexture = this.depthTexture;
        var depthTextureGPU:WebGPUGPUTexture = backend.get(depthTexture).texture;
        var format:Int;
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
            destroyTexture(depthTexture);
        }
        depthTexture.name = 'depthBuffer';
        depthTexture.format = format;
        depthTexture.type = type;
        depthTexture.image.width = width;
        depthTexture.image.height = height;
        createTexture(depthTexture, { sampleCount: backend.parameters.sampleCount, width: width, height: height });
        return backend.get(depthTexture).texture;
    }

    public function updateTexture(texture:Texture, options:Dynamic):Void {
        var textureData:WebGPUGPUTexture = this.backend.get(texture);
        var { textureDescriptorGPU } = textureData;
        if (texture.isRenderTargetTexture || textureDescriptorGPU == null) {
            return;
        }
        if (texture.isDataTexture || texture.isData3DTexture) {
            _copyBufferToTexture(options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY);
        } else if (texture.isDataArrayTexture) {
            for (i in 0...options.image.depth) {
                _copyBufferToTexture(options.image, textureData.texture, textureDescriptorGPU, i, texture.flipY, i);
            }
        } else if (texture.isCompressedTexture) {
            _copyCompressedBufferToTexture(texture.mipmaps, textureData.texture, textureDescriptorGPU);
        } else if (texture.isCubeTexture) {
            _copyCubeMapToTexture(options.images, textureData.texture, textureDescriptorGPU, texture.flipY);
        } else if (texture.isVideoTexture) {
            var video:Video = texture.source.data;
            textureData.externalTexture = video;
        } else {
            _copyImageToTexture(options.image, textureData.texture, textureDescriptorGPU, 0, texture.flipY);
        }
        textureData.version = texture.version;
        if (texture.onUpdate != null) texture.onUpdate(texture);
    }

    public function copyTextureToBuffer(texture:Texture, x:Int, y:Int, width:Int, height:Int):Array<Byte> {
        var device:WebGPUDevice = this.backend.device;
        var textureData:WebGPUGPUTexture = this.backend.get(texture);
        var textureGPU:WebGPUGPUTexture = textureData.texture;
        var format:Int = textureData.textureDescriptorGPU.format;
        var bytesPerTexel:Int = _getBytesPerTexel(format);
        var bytesPerRow:Int = width * bytesPerTexel;
        bytesPerRow = Math.ceil(bytesPerRow / 256) * 256;
        var readBuffer:WebGPUBuffer = device.createBuffer({
            size: width * height * bytesPerTexel,
            usage: WebGPUBufferUsage.COPY_DST | WebGPUBufferUsage.MAP_READ
        });
        var encoder:WebGPUEncoder = device.createCommandEncoder();
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
        device.queue.submit([encoder.finish()]);
        readBuffer.mapAsync(WebGPUMapMode.READ);
        var buffer:Array<Byte> = readBuffer.getMappedRange();
        return buffer;
    }

    private function _isEnvironmentTexture(texture:Texture):Bool {
        var mapping:Int = texture.mapping;
        return (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) || (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
    }

    private function _getDefaultTextureGPU(format:Int):Texture {
        var defaultTexture:Texture = defaultTexture[format];
        if (defaultTexture == null) {
            var texture:Texture = new Texture();
            texture.minFilter = NearestFilter;
            texture.magFilter = NearestFilter;
            createTexture(texture, { width: 1, height: 1, format });
            defaultTexture[format] = defaultTexture = texture;
        }
        return backend.get(defaultTexture).texture;
    }

    private function _getDefaultCubeTextureGPU(format:Int):CubeTexture {
        var defaultCubeTexture:CubeTexture = defaultCubeTexture[format];
        if (defaultCubeTexture == null) {
            var texture:CubeTexture = new CubeTexture();
            texture.minFilter = NearestFilter;
            texture.magFilter = NearestFilter;
            createTexture(texture, { width: 1, height: 1, depth: 6 });
            defaultCubeTexture[format] = defaultCubeTexture = texture;
        }
        return backend.get(defaultCubeTexture).texture;
    }

    private function _copyCubeMapToTexture(images:Array<Texture>, textureGPU:WebGPUGPUTexture, textureDescriptorGPU:WebGPUGPUTextureDescriptor, flipY:Bool):Void {
        for (i in 0...6) {
            var image:Texture = images[i];
            var flipIndex:Int = flipY ? _flipMap[i] : i;
            if (image.isDataTexture) {
                _copyBufferToTexture(image.image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
            } else {
                _copyImageToTexture(image, textureGPU, textureDescriptorGPU, flipIndex, flipY);
            }
        }
    }

    private function _copyImageToTexture(image:Texture, textureGPU:WebGPUGPUTexture, textureDescriptorGPU:WebGPUGPUTextureDescriptor, originDepth:Int, flipY:Bool):Void {
        var device:WebGPUDevice = this.backend.device;
        device.queue.copyExternalImageToTexture({
            source: image
        }, {
            texture: textureGPU,
            mipLevel: 0,
            origin: { x: 0, y: 0, z: originDepth }
        }, {
            width: image.width,
            height: image.height,
            depthOrArrayLayers: 1
        });
        if (flipY) {
            _flipY(textureGPU, textureDescriptorGPU, originDepth);
        }
    }
}