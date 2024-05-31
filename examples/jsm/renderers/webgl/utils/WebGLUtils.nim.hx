import three.examples.jsm.renderers.webgl.utils.WebGLUtils;

class WebGLUtils {

	public var backend:WebGLBackend;
	public var gl:WebGLRenderingContext;
	public var extensions:Map<String, WebGLExtension>;

	public function new(backend:WebGLBackend) {
		this.backend = backend;
		this.gl = this.backend.gl;
		this.extensions = this.backend.extensions;
	}

	public function convert(p:Dynamic, colorSpace:Dynamic = NoColorSpace):Dynamic {
		var gl = this.gl;
		var extensions = this.extensions;

		switch (p) {
			case UnsignedByteType:
				return gl.UNSIGNED_BYTE;
			case UnsignedShort4444Type:
				return gl.UNSIGNED_SHORT_4_4_4_4;
			case UnsignedShort5551Type:
				return gl.UNSIGNED_SHORT_5_5_5_1;
			case UnsignedInt5999Type:
				return gl.UNSIGNED_INT_5_9_9_9_REV;
			case ByteType:
				return gl.BYTE;
			case ShortType:
				return gl.SHORT;
			case UnsignedShortType:
				return gl.UNSIGNED_SHORT;
			case IntType:
				return gl.INT;
			case UnsignedIntType:
				return gl.UNSIGNED_INT;
			case FloatType:
				return gl.FLOAT;
			case HalfFloatType:
				return gl.HALF_FLOAT;
			case AlphaFormat:
				return gl.ALPHA;
			case RGBFormat:
				return gl.RGB;
			case RGBAFormat:
				return gl.RGBA;
			case LuminanceFormat:
				return gl.LUMINANCE;
			case LuminanceAlphaFormat:
				return gl.LUMINANCE_ALPHA;
			case DepthFormat:
				return gl.DEPTH_COMPONENT;
			case DepthStencilFormat:
				return gl.DEPTH_STENCIL;
			case RedFormat:
				return gl.RED;
			case RedIntegerFormat:
				return gl.RED_INTEGER;
			case RGFormat:
				return gl.RG;
			case RGIntegerFormat:
				return gl.RG_INTEGER;
			case RGBAIntegerFormat:
				return gl.RGBA_INTEGER;
			case RGB_S3TC_DXT1_Format:
			case RGBA_S3TC_DXT1_Format:
			case RGBA_S3TC_DXT3_Format:
			case RGBA_S3TC_DXT5_Format:
				if (colorSpace === SRGBColorSpace) {
					var extension = extensions.get("WEBGL_compressed_texture_s3tc_srgb");
					if (extension != null) {
						switch (p) {
							case RGB_S3TC_DXT1_Format:
								return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
							case RGBA_S3TC_DXT1_Format:
								return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
							case RGBA_S3TC_DXT3_Format:
								return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
							case RGBA_S3TC_DXT5_Format:
								return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
						}
					} else {
						return null;
					}
				} else {
					var extension = extensions.get("WEBGL_compressed_texture_s3tc");
					if (extension != null) {
						switch (p) {
							case RGB_S3TC_DXT1_Format:
								return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
							case RGBA_S3TC_DXT1_Format:
								return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
							case RGBA_S3TC_DXT3_Format:
								return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
							case RGBA_S3TC_DXT5_Format:
								return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
						}
					} else {
						return null;
					}
				}
			case RGB_PVRTC_4BPPV1_Format:
			case RGB_PVRTC_2BPPV1_Format:
			case RGBA_PVRTC_4BPPV1_Format:
			case RGBA_PVRTC_2BPPV1_Format:
				var extension = extensions.get("WEBGL_compressed_texture_pvrtc");
				if (extension != null) {
					switch (p) {
						case RGB_PVRTC_4BPPV1_Format:
							return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
						case RGB_PVRTC_2BPPV1_Format:
							return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
						case RGBA_PVRTC_4BPPV1_Format:
							return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
						case RGBA_PVRTC_2BPPV1_Format:
							return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
					}
				} else {
					return null;
				}
			case RGB_ETC1_Format:
			case RGB_ETC2_Format:
			case RGBA_ETC2_EAC_Format:
				var extension = extensions.get("WEBGL_compressed_texture_etc");
				if (extension != null) {
					switch (p) {
						case RGB_ETC1_Format:
						case RGB_ETC2_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
						case RGBA_ETC2_EAC_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
					}
				} else {
					return null;
				}
			case RGBA_ASTC_4x4_Format:
			case RGBA_ASTC_5x4_Format:
			case RGBA_ASTC_5x5_Format:
			case RGBA_ASTC_6x5_Format:
			case RGBA_ASTC_6x6_Format:
			case RGBA_ASTC_8x5_Format:
			case RGBA_ASTC_8x6_Format:
			case RGBA_ASTC_8x8_Format:
			case RGBA_ASTC_10x5_Format:
			case RGBA_ASTC_10x6_Format:
			case RGBA_ASTC_10x8_Format:
			case RGBA_ASTC_10x10_Format:
			case RGBA_ASTC_12x10_Format:
			case RGBA_ASTC_12x12_Format:
				var extension = extensions.get("WEBGL_compressed_texture_astc");
				if (extension != null) {
					switch (p) {
						case RGBA_ASTC_4x4_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
						case RGBA_ASTC_5x4_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
						case RGBA_ASTC_5x5_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
						case RGBA_ASTC_6x5_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
						case RGBA_ASTC_6x6_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
						case RGBA_ASTC_8x5_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
						case RGBA_ASTC_8x6_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
						case RGBA_ASTC_8x8_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
						case RGBA_ASTC_10x5_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
						case RGBA_ASTC_10x6_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
						case RGBA_ASTC_10x8_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
						case RGBA_ASTC_10x10_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
						case RGBA_ASTC_12x10_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
						case RGBA_ASTC_12x12_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
					}
				} else {
					return null;
				}
			case RGBA_BPTC_Format:
				var extension = extensions.get("EXT_texture_compression_bptc");
				if (extension != null) {
					switch (p) {
						case RGBA_BPTC_Format:
							return (colorSpace === SRGBColorSpace) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
					}
				} else {
					return null;
				}
			case RED_RGTC1_Format:
			case SIGNED_RED_RGTC1_Format:
			case RED_GREEN_RGTC2_Format:
			case SIGNED_RED_GREEN_RGTC2_Format:
				var extension = extensions.get("EXT_texture_compression_rgtc");
				if (extension != null) {
					switch (p) {
						case RED_RGTC1_Format:
							return extension.COMPRESSED_RED_RGTC1_EXT;
						case SIGNED_RED_RGTC1_Format:
							return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
						case RED_GREEN_RGTC2_Format:
							return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
						case SIGNED_RED_GREEN_RGTC2_Format:
							return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
					}
				} else {
					return null;
				}
			case UnsignedInt248Type:
				return gl.UNSIGNED_INT_24_8;
			default:
				return (gl[p] != undefined) ? gl[p] : null;
		}
	}

	public function _clientWaitAsync():Promise<Void> {
		var gl = this.gl;
		var sync = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
		gl.flush();
		return new Promise((resolve, reject) -> {
			function test() {
				var res = gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0);
				if (res == gl.WAIT_FAILED) {
					gl.deleteSync(sync);
					reject();
					return;
				}
				if (res == gl.TIMEOUT_EXPIRED) {
					requestAnimationFrame(test);
					return;
				}
				gl.deleteSync(sync);
				resolve();
			}
			test();
		});
	}

}