import webgl.WebGLRenderingContext;
import webgl.WebGLTexture;
import webgl.WebGL2RenderingContext;
import webgl.ext.WEBGL_compressed_texture_astc;
import webgl.ext.WEBGL_compressed_texture_etc;
import webgl.ext.WEBGL_compressed_texture_pvrtc;
import webgl.ext.WEBGL_compressed_texture_s3tc;
import webgl.ext.EXT_texture_compression_bptc;
import webgl.ext.EXT_texture_compression_rgtc;
import three.math.ColorManagement;
import three.constants.NoColorSpace;
import three.constants.SRGBTransfer;
import three.constants.UnsignedByteType;
import three.constants.UnsignedShort4444Type;
import three.constants.UnsignedShort5551Type;
import three.constants.UnsignedInt5999Type;
import three.constants.ByteType;
import three.constants.ShortType;
import three.constants.UnsignedShortType;
import three.constants.IntType;
import three.constants.UnsignedIntType;
import three.constants.FloatType;
import three.constants.HalfFloatType;
import three.constants.AlphaFormat;
import three.constants.RGBFormat;
import three.constants.RGBAFormat;
import three.constants.LuminanceFormat;
import three.constants.LuminanceAlphaFormat;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.RedFormat;
import three.constants.RedIntegerFormat;
import three.constants.RGFormat;
import three.constants.RGIntegerFormat;
import three.constants.RGBAIntegerFormat;
import three.constants.RGB_ETC1_Format;
import three.constants.RGB_ETC2_Format;
import three.constants.RGBA_ETC2_EAC_Format;
import three.constants.RGBA_PVRTC_2BPPV1_Format;
import three.constants.RGBA_PVRTC_4BPPV1_Format;
import three.constants.RGB_PVRTC_2BPPV1_Format;
import three.constants.RGB_PVRTC_4BPPV1_Format;
import three.constants.RGBA_S3TC_DXT5_Format;
import three.constants.RGBA_S3TC_DXT3_Format;
import three.constants.RGBA_S3TC_DXT1_Format;
import three.constants.RGB_S3TC_DXT1_Format;
import three.constants.RGBA_ASTC_4x4_Format;
import three.constants.RGBA_ASTC_5x4_Format;
import three.constants.RGBA_ASTC_5x5_Format;
import three.constants.RGBA_ASTC_6x5_Format;
import three.constants.RGBA_ASTC_6x6_Format;
import three.constants.RGBA_ASTC_8x5_Format;
import three.constants.RGBA_ASTC_8x6_Format;
import three.constants.RGBA_ASTC_8x8_Format;
import three.constants.RGBA_ASTC_10x5_Format;
import three.constants.RGBA_ASTC_10x6_Format;
import three.constants.RGBA_ASTC_10x8_Format;
import three.constants.RGBA_ASTC_10x10_Format;
import three.constants.RGBA_ASTC_12x10_Format;
import three.constants.RGBA_ASTC_12x12_Format;
import three.constants.RGBA_BPTC_Format;
import three.constants.RGB_BPTC_SIGNED_Format;
import three.constants.RGB_BPTC_UNSIGNED_Format;
import three.constants.RED_RGTC1_Format;
import three.constants.SIGNED_RED_RGTC1_Format;
import three.constants.RED_GREEN_RGTC2_Format;
import three.constants.SIGNED_RED_GREEN_RGTC2_Format;
import three.constants.UnsignedInt248Type;

class WebGLUtils {

	public static function convert(p:Int, colorSpace:Int = NoColorSpace):Null<Int> {
		var extension:Null<Dynamic>;
		var transfer = ColorManagement.getTransfer(colorSpace);
		switch (p) {
			case UnsignedByteType: return WebGLRenderingContext.UNSIGNED_BYTE;
			case UnsignedShort4444Type: return WebGLRenderingContext.UNSIGNED_SHORT_4_4_4_4;
			case UnsignedShort5551Type: return WebGLRenderingContext.UNSIGNED_SHORT_5_5_5_1;
			case UnsignedInt5999Type: return WebGLRenderingContext.UNSIGNED_INT_5_9_9_9_REV;
			case ByteType: return WebGLRenderingContext.BYTE;
			case ShortType: return WebGLRenderingContext.SHORT;
			case UnsignedShortType: return WebGLRenderingContext.UNSIGNED_SHORT;
			case IntType: return WebGLRenderingContext.INT;
			case UnsignedIntType: return WebGLRenderingContext.UNSIGNED_INT;
			case FloatType: return WebGLRenderingContext.FLOAT;
			case HalfFloatType: return WebGLRenderingContext.HALF_FLOAT;
			case AlphaFormat: return WebGLRenderingContext.ALPHA;
			case RGBFormat: return WebGLRenderingContext.RGB;
			case RGBAFormat: return WebGLRenderingContext.RGBA;
			case LuminanceFormat: return WebGLRenderingContext.LUMINANCE;
			case LuminanceAlphaFormat: return WebGLRenderingContext.LUMINANCE_ALPHA;
			case DepthFormat: return WebGLRenderingContext.DEPTH_COMPONENT;
			case DepthStencilFormat: return WebGLRenderingContext.DEPTH_STENCIL;
			case RedFormat: return WebGL2RenderingContext.RED;
			case RedIntegerFormat: return WebGL2RenderingContext.RED_INTEGER;
			case RGFormat: return WebGL2RenderingContext.RG;
			case RGIntegerFormat: return WebGL2RenderingContext.RG_INTEGER;
			case RGBAIntegerFormat: return WebGL2RenderingContext.RGBA_INTEGER;
			case RGB_S3TC_DXT1_Format:
			case RGBA_S3TC_DXT1_Format:
			case RGBA_S3TC_DXT3_Format:
			case RGBA_S3TC_DXT5_Format:
				if (transfer == SRGBTransfer) {
					extension = cast(WEBGL_compressed_texture_s3tc_srgb.get('WEBGL_compressed_texture_s3tc_srgb'), Dynamic);
					if (extension != null) {
						if (p == RGB_S3TC_DXT1_Format) return cast(extension.COMPRESSED_SRGB_S3TC_DXT1_EXT, Int);
						if (p == RGBA_S3TC_DXT1_Format) return cast(extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT, Int);
						if (p == RGBA_S3TC_DXT3_Format) return cast(extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT, Int);
						if (p == RGBA_S3TC_DXT5_Format) return cast(extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT, Int);
					} else {
						return null;
					}
				} else {
					extension = cast(WEBGL_compressed_texture_s3tc.get('WEBGL_compressed_texture_s3tc'), Dynamic);
					if (extension != null) {
						if (p == RGB_S3TC_DXT1_Format) return cast(extension.COMPRESSED_RGB_S3TC_DXT1_EXT, Int);
						if (p == RGBA_S3TC_DXT1_Format) return cast(extension.COMPRESSED_RGBA_S3TC_DXT1_EXT, Int);
						if (p == RGBA_S3TC_DXT3_Format) return cast(extension.COMPRESSED_RGBA_S3TC_DXT3_EXT, Int);
						if (p == RGBA_S3TC_DXT5_Format) return cast(extension.COMPRESSED_RGBA_S3TC_DXT5_EXT, Int);
					} else {
						return null;
					}
				}
			case RGB_PVRTC_4BPPV1_Format:
			case RGB_PVRTC_2BPPV1_Format:
			case RGBA_PVRTC_4BPPV1_Format:
			case RGBA_PVRTC_2BPPV1_Format:
				extension = cast(WEBGL_compressed_texture_pvrtc.get('WEBGL_compressed_texture_pvrtc'), Dynamic);
				if (extension != null) {
					if (p == RGB_PVRTC_4BPPV1_Format) return cast(extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG, Int);
					if (p == RGB_PVRTC_2BPPV1_Format) return cast(extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG, Int);
					if (p == RGBA_PVRTC_4BPPV1_Format) return cast(extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG, Int);
					if (p == RGBA_PVRTC_2BPPV1_Format) return cast(extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG, Int);
				} else {
					return null;
				}
			case RGB_ETC1_Format:
			case RGB_ETC2_Format:
			case RGBA_ETC2_EAC_Format:
				extension = cast(WEBGL_compressed_texture_etc.get('WEBGL_compressed_texture_etc'), Dynamic);
				if (extension != null) {
					if (p == RGB_ETC1_Format || p == RGB_ETC2_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ETC2, Int) : cast(extension.COMPRESSED_RGB8_ETC2, Int);
					if (p == RGBA_ETC2_EAC_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC, Int) : cast(extension.COMPRESSED_RGBA8_ETC2_EAC, Int);
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
				extension = cast(WEBGL_compressed_texture_astc.get('WEBGL_compressed_texture_astc'), Dynamic);
				if (extension != null) {
					if (p == RGBA_ASTC_4x4_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_4x4_KHR, Int);
					if (p == RGBA_ASTC_5x4_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_5x4_KHR, Int);
					if (p == RGBA_ASTC_5x5_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_5x5_KHR, Int);
					if (p == RGBA_ASTC_6x5_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_6x5_KHR, Int);
					if (p == RGBA_ASTC_6x6_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_6x6_KHR, Int);
					if (p == RGBA_ASTC_8x5_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_8x5_KHR, Int);
					if (p == RGBA_ASTC_8x6_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_8x6_KHR, Int);
					if (p == RGBA_ASTC_8x8_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_8x8_KHR, Int);
					if (p == RGBA_ASTC_10x5_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_10x5_KHR, Int);
					if (p == RGBA_ASTC_10x6_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_10x6_KHR, Int);
					if (p == RGBA_ASTC_10x8_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_10x8_KHR, Int);
					if (p == RGBA_ASTC_10x10_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_10x10_KHR, Int);
					if (p == RGBA_ASTC_12x10_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_12x10_KHR, Int);
					if (p == RGBA_ASTC_12x12_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR, Int) : cast(extension.COMPRESSED_RGBA_ASTC_12x12_KHR, Int);
				} else {
					return null;
				}
			case RGBA_BPTC_Format:
			case RGB_BPTC_SIGNED_Format:
			case RGB_BPTC_UNSIGNED_Format:
				extension = cast(EXT_texture_compression_bptc.get('EXT_texture_compression_bptc'), Dynamic);
				if (extension != null) {
					if (p == RGBA_BPTC_Format) return (transfer == SRGBTransfer) ? cast(extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT, Int) : cast(extension.COMPRESSED_RGBA_BPTC_UNORM_EXT, Int);
					if (p == RGB_BPTC_SIGNED_Format) return cast(extension.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT, Int);
					if (p == RGB_BPTC_UNSIGNED_Format) return cast(extension.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT, Int);
				} else {
					return null;
				}
			case RED_RGTC1_Format:
			case SIGNED_RED_RGTC1_Format:
			case RED_GREEN_RGTC2_Format:
			case SIGNED_RED_GREEN_RGTC2_Format:
				extension = cast(EXT_texture_compression_rgtc.get('EXT_texture_compression_rgtc'), Dynamic);
				if (extension != null) {
					if (p == RGBA_BPTC_Format) return cast(extension.COMPRESSED_RED_RGTC1_EXT, Int);
					if (p == SIGNED_RED_RGTC1_Format) return cast(extension.COMPRESSED_SIGNED_RED_RGTC1_EXT, Int);
					if (p == RED_GREEN_RGTC2_Format) return cast(extension.COMPRESSED_RED_GREEN_RGTC2_EXT, Int);
					if (p == SIGNED_RED_GREEN_RGTC2_Format) return cast(extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT, Int);
				} else {
					return null;
				}
			case UnsignedInt248Type: return WebGLRenderingContext.UNSIGNED_INT_24_8;
			default:
				if (WebGLRenderingContext.hasOwnProperty(p)) {
					return cast(WebGLRenderingContext.get(p), Int);
				}
				return null;
		}
	}

}