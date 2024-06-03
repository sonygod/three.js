import js.html.WebGLRenderingContext;
import js.html.WebGLRenderingContextBase;
import three.constants.NoColorSpace;
import three.constants.SRGBTransfer;
import three.math.ColorManagement;

class WebGLUtils {
    private var gl:WebGLRenderingContextBase;
    private var extensions:Map<String, dynamic>;

    public function new(gl:WebGLRenderingContextBase, extensions:Map<String, dynamic>) {
        this.gl = gl;
        this.extensions = extensions;
    }

    public function convert(p:Dynamic, colorSpace:Dynamic=NoColorSpace):Dynamic {
        var extension:Dynamic;
        var transfer = ColorManagement.getTransfer(colorSpace);

        switch (p) {
            case three.constants.UnsignedByteType:
                return gl.UNSIGNED_BYTE;
            case three.constants.UnsignedShort4444Type:
                return gl.UNSIGNED_SHORT_4_4_4_4;
            case three.constants.UnsignedShort5551Type:
                return gl.UNSIGNED_SHORT_5_5_5_1;
            case three.constants.UnsignedInt5999Type:
                return gl.UNSIGNED_INT_5_9_9_9_REV;
            case three.constants.ByteType:
                return gl.BYTE;
            case three.constants.ShortType:
                return gl.SHORT;
            case three.constants.UnsignedShortType:
                return gl.UNSIGNED_SHORT;
            case three.constants.IntType:
                return gl.INT;
            case three.constants.UnsignedIntType:
                return gl.UNSIGNED_INT;
            case three.constants.FloatType:
                return gl.FLOAT;
            case three.constants.HalfFloatType:
                return gl.HALF_FLOAT;
            case three.constants.AlphaFormat:
                return gl.ALPHA;
            case three.constants.RGBFormat:
                return gl.RGB;
            case three.constants.RGBAFormat:
                return gl.RGBA;
            case three.constants.LuminanceFormat:
                return gl.LUMINANCE;
            case three.constants.LuminanceAlphaFormat:
                return gl.LUMINANCE_ALPHA;
            case three.constants.DepthFormat:
                return gl.DEPTH_COMPONENT;
            case three.constants.DepthStencilFormat:
                return gl.DEPTH_STENCIL;
            case three.constants.RedFormat:
                return gl.RED;
            case three.constants.RedIntegerFormat:
                return gl.RED_INTEGER;
            case three.constants.RGFormat:
                return gl.RG;
            case three.constants.RGIntegerFormat:
                return gl.RG_INTEGER;
            case three.constants.RGBAIntegerFormat:
                return gl.RGBA_INTEGER;
            case three.constants.UnsignedInt248Type:
                return gl.UNSIGNED_INT_24_8;
            default:
                break;
        }

        switch (p) {
            case three.constants.RGB_S3TC_DXT1_Format:
            case three.constants.RGBA_S3TC_DXT1_Format:
            case three.constants.RGBA_S3TC_DXT3_Format:
            case three.constants.RGBA_S3TC_DXT5_Format:
                if (transfer === SRGBTransfer) {
                    extension = extensions.get('WEBGL_compressed_texture_s3tc_srgb');
                    if (extension !== null) {
                        switch (p) {
                            case three.constants.RGB_S3TC_DXT1_Format:
                                return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
                            case three.constants.RGBA_S3TC_DXT1_Format:
                                return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
                            case three.constants.RGBA_S3TC_DXT3_Format:
                                return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
                            case three.constants.RGBA_S3TC_DXT5_Format:
                                return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
                        }
                    } else {
                        return null;
                    }
                } else {
                    extension = extensions.get('WEBGL_compressed_texture_s3tc');
                    if (extension !== null) {
                        switch (p) {
                            case three.constants.RGB_S3TC_DXT1_Format:
                                return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
                            case three.constants.RGBA_S3TC_DXT1_Format:
                                return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
                            case three.constants.RGBA_S3TC_DXT3_Format:
                                return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
                            case three.constants.RGBA_S3TC_DXT5_Format:
                                return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
                        }
                    } else {
                        return null;
                    }
                }
                break;
            default:
                break;
        }

        switch (p) {
            case three.constants.RGB_PVRTC_4BPPV1_Format:
            case three.constants.RGB_PVRTC_2BPPV1_Format:
            case three.constants.RGBA_PVRTC_4BPPV1_Format:
            case three.constants.RGBA_PVRTC_2BPPV1_Format:
                extension = extensions.get('WEBGL_compressed_texture_pvrtc');
                if (extension !== null) {
                    switch (p) {
                        case three.constants.RGB_PVRTC_4BPPV1_Format:
                            return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
                        case three.constants.RGB_PVRTC_2BPPV1_Format:
                            return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
                        case three.constants.RGBA_PVRTC_4BPPV1_Format:
                            return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
                        case three.constants.RGBA_PVRTC_2BPPV1_Format:
                            return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
                    }
                } else {
                    return null;
                }
                break;
            default:
                break;
        }

        switch (p) {
            case three.constants.RGB_ETC1_Format:
            case three.constants.RGB_ETC2_Format:
            case three.constants.RGBA_ETC2_EAC_Format:
                extension = extensions.get('WEBGL_compressed_texture_etc');
                if (extension !== null) {
                    switch (p) {
                        case three.constants.RGB_ETC1_Format:
                        case three.constants.RGB_ETC2_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
                        case three.constants.RGBA_ETC2_EAC_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
                    }
                } else {
                    return null;
                }
                break;
            default:
                break;
        }

        switch (p) {
            case three.constants.RGBA_ASTC_4x4_Format:
            case three.constants.RGBA_ASTC_5x4_Format:
            case three.constants.RGBA_ASTC_5x5_Format:
            case three.constants.RGBA_ASTC_6x5_Format:
            case three.constants.RGBA_ASTC_6x6_Format:
            case three.constants.RGBA_ASTC_8x5_Format:
            case three.constants.RGBA_ASTC_8x6_Format:
            case three.constants.RGBA_ASTC_8x8_Format:
            case three.constants.RGBA_ASTC_10x5_Format:
            case three.constants.RGBA_ASTC_10x6_Format:
            case three.constants.RGBA_ASTC_10x8_Format:
            case three.constants.RGBA_ASTC_10x10_Format:
            case three.constants.RGBA_ASTC_12x10_Format:
            case three.constants.RGBA_ASTC_12x12_Format:
                extension = extensions.get('WEBGL_compressed_texture_astc');
                if (extension !== null) {
                    switch (p) {
                        case three.constants.RGBA_ASTC_4x4_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
                        case three.constants.RGBA_ASTC_5x4_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
                        case three.constants.RGBA_ASTC_5x5_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
                        case three.constants.RGBA_ASTC_6x5_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
                        case three.constants.RGBA_ASTC_6x6_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
                        case three.constants.RGBA_ASTC_8x5_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
                        case three.constants.RGBA_ASTC_8x6_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
                        case three.constants.RGBA_ASTC_8x8_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
                        case three.constants.RGBA_ASTC_10x5_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
                        case three.constants.RGBA_ASTC_10x6_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
                        case three.constants.RGBA_ASTC_10x8_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
                        case three.constants.RGBA_ASTC_10x10_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
                        case three.constants.RGBA_ASTC_12x10_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
                        case three.constants.RGBA_ASTC_12x12_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
                    }
                } else {
                    return null;
                }
                break;
            default:
                break;
        }

        switch (p) {
            case three.constants.RGBA_BPTC_Format:
            case three.constants.RGB_BPTC_SIGNED_Format:
            case three.constants.RGB_BPTC_UNSIGNED_Format:
                extension = extensions.get('EXT_texture_compression_bptc');
                if (extension !== null) {
                    switch (p) {
                        case three.constants.RGBA_BPTC_Format:
                            return (transfer === SRGBTransfer) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
                        case three.constants.RGB_BPTC_SIGNED_Format:
                            return extension.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;
                        case three.constants.RGB_BPTC_UNSIGNED_Format:
                            return extension.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT;
                    }
                } else {
                    return null;
                }
                break;
            default:
                break;
        }

        switch (p) {
            case three.constants.RED_RGTC1_Format:
            case three.constants.SIGNED_RED_RGTC1_Format:
            case three.constants.RED_GREEN_RGTC2_Format:
            case three.constants.SIGNED_RED_GREEN_RGTC2_Format:
                extension = extensions.get('EXT_texture_compression_rgtc');
                if (extension !== null) {
                    switch (p) {
                        case three.constants.RED_RGTC1_Format:
                            return extension.COMPRESSED_RED_RGTC1_EXT;
                        case three.constants.SIGNED_RED_RGTC1_Format:
                            return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
                        case three.constants.RED_GREEN_RGTC2_Format:
                            return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
                        case three.constants.SIGNED_RED_GREEN_RGTC2_Format:
                            return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
                    }
                } else {
                    return null;
                }
                break;
            default:
                break;
        }

        return (gl[p] !== undefined) ? gl[p] : null;
    }
}