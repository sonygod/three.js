import three.js.src.constants.RGBA_ASTC_4x4_Format;
import three.js.src.constants.RGBA_ASTC_5x4_Format;
import three.js.src.constants.RGBA_ASTC_5x5_Format;
import three.js.src.constants.RGBA_ASTC_6x5_Format;
import three.js.src.constants.RGBA_ASTC_6x6_Format;
import three.js.src.constants.RGBA_ASTC_8x5_Format;
import three.js.src.constants.RGBA_ASTC_8x6_Format;
import three.js.src.constants.RGBA_ASTC_8x8_Format;
import three.js.src.constants.RGBA_ASTC_10x5_Format;
import three.js.src.constants.RGBA_ASTC_10x6_Format;
import three.js.src.constants.RGBA_ASTC_10x8_Format;
import three.js.src.constants.RGBA_ASTC_10x10_Format;
import three.js.src.constants.RGBA_ASTC_12x10_Format;
import three.js.src.constants.RGBA_ASTC_12x12_Format;
import three.js.src.constants.RGB_ETC1_Format;
import three.js.src.constants.RGB_ETC2_Format;
import three.js.src.constants.RGBA_ETC2_EAC_Format;
import three.js.src.constants.RGBA_PVRTC_2BPPV1_Format;
import three.js.src.constants.RGBA_PVRTC_4BPPV1_Format;
import three.js.src.constants.RGB_PVRTC_2BPPV1_Format;
import three.js.src.constants.RGB_PVRTC_4BPPV1_Format;
import three.js.src.constants.RGBA_S3TC_DXT5_Format;
import three.js.src.constants.RGBA_S3TC_DXT3_Format;
import three.js.src.constants.RGBA_S3TC_DXT1_Format;
import three.js.src.constants.RGB_S3TC_DXT1_Format;
import three.js.src.constants.DepthFormat;
import three.js.src.constants.DepthStencilFormat;
import three.js.src.constants.LuminanceAlphaFormat;
import three.js.src.constants.LuminanceFormat;
import three.js.src.constants.RedFormat;
import three.js.src.constants.RGBAFormat;
import three.js.src.constants.AlphaFormat;
import three.js.src.constants.RedIntegerFormat;
import three.js.src.constants.RGFormat;
import three.js.src.constants.RGIntegerFormat;
import three.js.src.constants.RGBAIntegerFormat;
import three.js.src.constants.HalfFloatType;
import three.js.src.constants.FloatType;
import three.js.src.constants.UnsignedIntType;
import three.js.src.constants.IntType;
import three.js.src.constants.UnsignedShortType;
import three.js.src.constants.ShortType;
import three.js.src.constants.ByteType;
import three.js.src.constants.UnsignedInt248Type;
import three.js.src.constants.UnsignedShort5551Type;
import three.js.src.constants.UnsignedShort4444Type;
import three.js.src.constants.UnsignedByteType;
import three.js.src.constants.RGBA_BPTC_Format;
import three.js.src.constants.RGB_BPTC_SIGNED_Format;
import three.js.src.constants.RGB_BPTC_UNSIGNED_Format;
import three.js.src.constants.RED_RGTC1_Format;
import three.js.src.constants.SIGNED_RED_RGTC1_Format;
import three.js.src.constants.RED_GREEN_RGTC2_Format;
import three.js.src.constants.SIGNED_RED_GREEN_RGTC2_Format;
import three.js.src.constants.NoColorSpace;
import three.js.src.constants.SRGBTransfer;
import three.js.src.constants.UnsignedInt5999Type;
import three.js.src.math.ColorManagement;

class WebGLUtils {
    var gl:WebGLRenderingContext;
    var extensions:Map<String, Dynamic>;

    public function new(gl:WebGLRenderingContext, extensions:Map<String, Dynamic>) {
        this.gl = gl;
        this.extensions = extensions;
    }

    public function convert(p:Dynamic, colorSpace:Dynamic = NoColorSpace):Dynamic {
        var extension:Dynamic;
        var transfer:Dynamic = ColorManagement.getTransfer(colorSpace);

        if (Std.is(p, UnsignedByteType)) return gl.UNSIGNED_BYTE;
        if (Std.is(p, UnsignedShort4444Type)) return gl.UNSIGNED_SHORT_4_4_4_4;
        if (Std.is(p, UnsignedShort5551Type)) return gl.UNSIGNED_SHORT_5_5_5_1;
        if (Std.is(p, UnsignedInt5999Type)) return gl.UNSIGNED_INT_5_9_9_9_REV;

        if (Std.is(p, ByteType)) return gl.BYTE;
        if (Std.is(p, ShortType)) return gl.SHORT;
        if (Std.is(p, UnsignedShortType)) return gl.UNSIGNED_SHORT;
        if (Std.is(p, IntType)) return gl.INT;
        if (Std.is(p, UnsignedIntType)) return gl.UNSIGNED_INT;
        if (Std.is(p, FloatType)) return gl.FLOAT;
        if (Std.is(p, HalfFloatType)) return gl.HALF_FLOAT;

        if (Std.is(p, AlphaFormat)) return gl.ALPHA;
        if (Std.is(p, RGBFormat)) return gl.RGB;
        if (Std.is(p, RGBAFormat)) return gl.RGBA;
        if (Std.is(p, LuminanceFormat)) return gl.LUMINANCE;
        if (Std.is(p, LuminanceAlphaFormat)) return gl.LUMINANCE_ALPHA;
        if (Std.is(p, DepthFormat)) return gl.DEPTH_COMPONENT;
        if (Std.is(p, DepthStencilFormat)) return gl.DEPTH_STENCIL;

        // WebGL2 formats.

        if (Std.is(p, RedFormat)) return gl.RED;
        if (Std.is(p, RedIntegerFormat)) return gl.RED_INTEGER;
        if (Std.is(p, RGFormat)) return gl.RG;
        if (Std.is(p, RGIntegerFormat)) return gl.RG_INTEGER;
        if (Std.is(p, RGBAIntegerFormat)) return gl.RGBA_INTEGER;

        // S3TC

        if (Std.is(p, RGB_S3TC_DXT1_Format) || Std.is(p, RGBA_S3TC_DXT1_Format) || Std.is(p, RGBA_S3TC_DXT3_Format) || Std.is(p, RGBA_S3TC_DXT5_Format)) {
            if (transfer == SRGBTransfer) {
                extension = extensions.get("WEBGL_compressed_texture_s3tc_srgb");
                if (extension != null) {
                    if (Std.is(p, RGB_S3TC_DXT1_Format)) return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
                    if (Std.is(p, RGBA_S3TC_DXT1_Format)) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
                    if (Std.is(p, RGBA_S3TC_DXT3_Format)) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
                    if (Std.is(p, RGBA_S3TC_DXT5_Format)) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
                } else {
                    return null;
                }
            } else {
                extension = extensions.get("WEBGL_compressed_texture_s3tc");
                if (extension != null) {
                    if (Std.is(p, RGB_S3TC_DXT1_Format)) return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
                    if (Std.is(p, RGBA_S3TC_DXT1_Format)) return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
                    if (Std.is(p, RGBA_S3TC_DXT3_Format)) return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
                    if (Std.is(p, RGBA_S3TC_DXT5_Format)) return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
                } else {
                    return null;
                }
            }
        }

        // PVRTC

        if (Std.is(p, RGB_PVRTC_4BPPV1_Format) || Std.is(p, RGB_PVRTC_2BPPV1_Format) || Std.is(p, RGBA_PVRTC_4BPPV1_Format) || Std.is(p, RGBA_PVRTC_2BPPV1_Format)) {
            extension = extensions.get("WEBGL_compressed_texture_pvrtc");
            if (extension != null) {
                if (Std.is(p, RGB_PVRTC_4BPPV1_Format)) return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
                if (Std.is(p, RGB_PVRTC_2BPPV1_Format)) return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
                if (Std.is(p, RGBA_PVRTC_4BPPV1_Format)) return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
                if (Std.is(p, RGBA_PVRTC_2BPPV1_Format)) return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
            } else {
                return null;
            }
        }

        // ETC

        if (Std.is(p, RGB_ETC1_Format) || Std.is(p, RGB_ETC2_Format) || Std.is(p, RGBA_ETC2_EAC_Format)) {
            extension = extensions.get("WEBGL_compressed_texture_etc");
            if (extension != null) {
                if (Std.is(p, RGB_ETC1_Format) || Std.is(p, RGB_ETC2_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
                if (Std.is(p, RGBA_ETC2_EAC_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
            } else {
                return null;
            }
        }

        // ASTC

        if (Std.is(p, RGBA_ASTC_4x4_Format) || Std.is(p, RGBA_ASTC_5x4_Format) || Std.is(p, RGBA_ASTC_5x5_Format) ||
            Std.is(p, RGBA_ASTC_6x5_Format) || Std.is(p, RGBA_ASTC_6x6_Format) || Std.is(p, RGBA_ASTC_8x5_Format) ||
            Std.is(p, RGBA_ASTC_8x6_Format) || Std.is(p, RGBA_ASTC_8x8_Format) || Std.is(p, RGBA_ASTC_10x5_Format) ||
            Std.is(p, RGBA_ASTC_10x6_Format) || Std.is(p, RGBA_ASTC_10x8_Format) || Std.is(p, RGBA_ASTC_10x10_Format) ||
            Std.is(p, RGBA_ASTC_12x10_Format) || Std.is(p, RGBA_ASTC_12x12_Format)) {
            extension = extensions.get("WEBGL_compressed_texture_astc");
            if (extension != null) {
                if (Std.is(p, RGBA_ASTC_4x4_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
                if (Std.is(p, RGBA_ASTC_5x4_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
                if (Std.is(p, RGBA_ASTC_5x5_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
                if (Std.is(p, RGBA_ASTC_6x5_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
                if (Std.is(p, RGBA_ASTC_6x6_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
                if (Std.is(p, RGBA_ASTC_8x5_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
                if (Std.is(p, RGBA_ASTC_8x6_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
                if (Std.is(p, RGBA_ASTC_8x8_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
                if (Std.is(p, RGBA_ASTC_10x5_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
                if (Std.is(p, RGBA_ASTC_10x6_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
                if (Std.is(p, RGBA_ASTC_10x8_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
                if (Std.is(p, RGBA_ASTC_10x10_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
                if (Std.is(p, RGBA_ASTC_12x10_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
                if (Std.is(p, RGBA_ASTC_12x12_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
            } else {
                return null;
            }
        }

        // BPTC

        if (Std.is(p, RGBA_BPTC_Format) || Std.is(p, RGB_BPTC_SIGNED_Format) || Std.is(p, RGB_BPTC_UNSIGNED_Format)) {
            extension = extensions.get("EXT_texture_compression_bptc");
            if (extension != null) {
                if (Std.is(p, RGBA_BPTC_Format)) return (transfer == SRGBTransfer) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
                if (Std.is(p, RGB_BPTC_SIGNED_Format)) return extension.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;
                if (Std.is(p, RGB_BPTC_UNSIGNED_Format)) return extension.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT;
            } else {
                return null;
            }
        }

        // RGTC

        if (Std.is(p, RED_RGTC1_Format) || Std.is(p, SIGNED_RED_RGTC1_Format) || Std.is(p, RED_GREEN_RGTC2_Format) || Std.is(p, SIGNED_RED_GREEN_RGTC2_Format)) {
            extension = extensions.get("EXT_texture_compression_rgtc");
            if (extension != null) {
                if (Std.is(p, RGBA_BPTC_Format)) return extension.COMPRESSED_RED_RGTC1_EXT;
                if (Std.is(p, SIGNED_RED_RGTC1_Format)) return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
                if (Std.is(p, RED_GREEN_RGTC2_Format)) return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
                if (Std.is(p, SIGNED_RED_GREEN_RGTC2_Format)) return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
            } else {
                return null;
            }
        }

        //

        if (Std.is(p, UnsignedInt248Type)) return gl.UNSIGNED_INT_24_8;

        // if "p" can't be resolved, assume the user defines a WebGL constant as a string (fallback/workaround for packed RGB formats)

        return (gl[p] != null) ? gl[p] : null;
    }
}