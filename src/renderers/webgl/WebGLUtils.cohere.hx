import js.Browser.Window;
import js.html.CanvasElement;
import js.html.WebGlRenderingContext as GL;
import js.html.WebGlRenderingContext.RenderingContext;
import js.html.WebGlRenderingContext.Texture;

class WebGLUtils {
    public function new(gl:GL, extensions:Dynamic) {
        function convert(p:Int, colorSpace:Int = 0) {
            var extension:Dynamic;
            var transfer = ColorManagement.getTransfer(colorSpace);

            if (p == UnsignedByteType) return GL.UNSIGNED_BYTE;
            if (p == UnsignedShort4444Type) return GL.UNSIGNED_SHORT_4_4_4_4;
            if (p == UnsignedShort5551Type) return GL.UNSIGNED_SHORT_5_5_5_1;
            if (p == UnsignedInt5999Type) return GL.UNSIGNED_INT_5_9_9_9_REV;

            if (p == ByteType) return GL.BYTE;
            if (p == ShortType) return GL.SHORT;
            if (p == UnsignedShortType) return GL.UNSIGNED_SHORT;
            if (p == IntType) return GL.INT;
            if (p == UnsignedIntType) return GL.UNSIGNED_INT;
            if (p == FloatType) return GL.FLOAT;
            if (p == HalfFloatType) return GL.HALF_FLOAT;

            if (p == AlphaFormat) return GL.ALPHA;
            if (p == RGBFormat) return GL.RGB;
            if (p == RGBAFormat) return GL.RGBA;
            if (p == LuminanceFormat) return GL.LUMINANCE;
            if (p == LuminanceAlphaFormat) return GL.LUMINANCE_ALPHA;
            if (p == DepthFormat) return GL.DEPTH_COMPONENT;
            if (p == DepthStencilFormat) return GL.DEPTH_STENCIL;

            // WebGL2 formats.

            if (p == RedFormat) return GL.RED;
            if (p == RedIntegerFormat) return GL.RED_INTEGER;
            if (p == RGFormat) return GL.RG;
            if (p == RGIntegerFormat) return GL.RG_INTEGER;
            if (p == RGBAIntegerFormat) return GL.RGBA_INTEGER;

            // S3TC

            if (p == RGB_S3TC_DXT1_Format || p == RGBA_S3TC_DXT1_Format || p == RGBA_S3TC_DXT3_Format || p == RGBA_S3TC_DXT5_Format) {
                if (transfer == SRGBTransfer) {
                    extension = extensions.get("WEBGL_compressed_texture_s3tc_srgb");
                    if (extension != null) {
                        if (p == RGB_S3TC_DXT1_Format) return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
                        if (p == RGBA_S3TC_DXT1_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
                        if (p == RGBA_S3TC_DXT3_Format) return extension.COMPRESS_ED_SRGB_ALPHA_S3TC_DXT3_EXT;
                        if (p == RGBA_S3TC_DXT5_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
                    } else {
                        return null;
                    }
                } else {
                    extension = extensions.get("WEBGL_compressed_texture_s3tc");
                    if (extension != null) {
                        if (p == RGB_S3TC_DXT1_Format) return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
                        if (p == RGBA_S3TC_DXT1_Format) return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
                        if (p == RGBA_S3TC_DXT3_Format) return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
                        if (p == RGBA_S3TC_DXT5_Format) return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
                    } else {
                        return null;
                    }
                }
            }

            // PVRTC

            if (p == RGB_PVRTC_4BPPV1_Format || p == RGB_PVRTC_2BPPV1_Format || p == RGBA_PVRTC_4BPPV1_Format || p == RGBA_PVRTC_2BPPV1_Format) {
                extension = extensions.get("WEBGL_compressed_texture_pvrtc");
                if (extension != null) {
                    if (p == RGB_PVRTC_4BPPV1_Format) return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
                    if (p == RGB_PVRTC_2BPPV1_Format) return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
                    if (p == RGBA_PVRTC_4BPPV1_Format) return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
                    if (p == RGBA_PVRTC_2BPPV1_Format) return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
                } else {
                    return null;
                }
            }

            // ETC

            if (p == RGB_ETC1_Format || p == RGB_ETC2_Format || p == RGBA_ETC2_EAC_Format) {
                extension = extensions.get("WEBGL_compressed_texture_etc");
                if (extension != null) {
                    if (p == RGB_ETC1_Format || p == RGB_ETC2_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
                    if (p == RGBA_ETC2_EAC_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
                } else {
                    return null;
                }
            }

            // ASTC

            if (p == RGBA_ASTC_4x4_Format || p == RGBA_ASTC_5x4_Format || p == RGBA_ASTC_5x5_Format ||
                p == RGBA_ASTC_6x5_Format || p == RGBA_ASTC_6x6_Format || p == RGBA_ASTC_8x5_Format ||
                p == RGBA_ASTC_8x6_Format || p == RGBA_ASTC_8x8_Format || p == RGBA_ASTC_10x5_Format ||
                p == RGBA_ASTC_10x6_Format || p == RGBA_ASTC_10x8_Format || p == RGBA_ASTC_10x10_Format ||
                p == RGBA_ASTC_12x10_Format || p == RGBA_ASTC_12x12_Format) {
                extension = extensions.get("WEBGL_compressed_texture_astc");
                if (extension != null) {
                    if (p == RGBA_ASTC_4x4_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
                    if (p == RGBA_ASTC_5x4_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
                    if (p == RGBA_ASTC_5x5_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
                    if (p == RGBA_ASTC_6x5_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
                    if (p == RGBA_ASTC_6x6_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
                    if (p == RGBA_ASTC_8x5_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
                    if (p == RGBA_ASTC_8x6_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
                    if (p == RGBA_ASTC_8x8_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
                    if (p == RGBA_ASTC_10x5_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
                    if (p == RGBA_ASTC_10x6_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
                    if (p == RGBA_ASTC_10x8_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
                    if (p == RGBA_ASTC_10x10_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
                    if (p == RGBA_ASTC_12x10_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
                    if (p == RGBA_ASTC_12x12_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
                } else {
                    return null;
                }
            }

            // BPTC

            if (p == RGBA_BPTC_Format || p == RGB_BPTC_SIGNED_Format || p == RGB_BPTC_UNSIGNED_Format) {
                extension = extensions.get("EXT_texture_compression_bptc");
                if (extension != null) {
                    if (p == RGBA_BPTC_Format) return transfer == SRGBTransfer ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
                    if (p == RGB_BPTC_SIGNED_Format) return extension.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;
                    if (p == RGB_BPTC_UNSIGNED_Format) return extension.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT;
                } else {
                    return null;
                }
            }

            // RGTC

            if (p == RED_RGTC1_Format || p == SIGNED_RED_RGTC1_Format || p == RED_GREEN_RGTC2_Format || p == SIGNED_RED_GREEN_RGTC2_Format) {
                extension = extensions.get("EXT_texture_compression_rgtc");
                if (extension != null) {
                    if (p == RGBA_BPTC_Format) return extension.COMPRESSED_RED_RGTC1_EXT;
                    if (p == SIGNED_RED_RGTC1_Format) return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
                    if (p == RED_GREEN_RGTC2_Format) return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
                    if (p == SIGNED_RED_GREEN_RGTC2_Format) return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
                } else {
                    return null;
                }
            }

            //

            if (p == UnsignedInt248Type) return GL.UNSIGNED_INT_24_8;

            // if "p" can't be resolved, assume the user defines a WebGL constant as a string (fallback/workaround for packed RGB formats)

            return if (gl[p] != null) gl[p] else null;
        }
    }
}