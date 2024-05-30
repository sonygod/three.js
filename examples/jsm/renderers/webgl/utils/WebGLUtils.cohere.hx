package;

import js.html.WebGLRenderingContext;
import js.html.WebGL2RenderingContext;
import js.html.WebGLActiveInfo;
import js.html.WebGLShaderPrecisionFormat;
import js.html.WebGLContextAttributes;
import js.html.ImageBitmap;

class WebGLUtils {
    public var backend:Dynamic;
    public var gl:WebGLRenderingContext;
    public var extensions:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = backend.gl;
        this.extensions = backend.extensions;
    }

    public function convert(p:Int, colorSpace:Int = 0) {
        if (p == 5121) return gl.UNSIGNED_BYTE;
        if (p == 32849) return gl.UNSIGNED_SHORT_4_4_4_4;
        if (p == 32855) return gl.UNSIGNED_SHORT_5_5_5_1;
        if (p == 33640) return gl.UNSIGNED_INT_5_9_9_9_REV;
        if (p == 5120) return gl.BYTE;
        if (p == 5122) return gl.SHORT;
        if (p == 5123) return gl.UNSIGNED_SHORT;
        if (p == 5124) return gl.INT;
        if (p == 5125) return gl.UNSIGNED_INT;
        if (p == 5126) return gl.FLOAT;
        if (p == 36193) return gl.HALF_FLOAT;
        if (p == 6406) return gl.ALPHA;
        if (p == 6407) return gl.RGB;
        if (p == 6408) return gl.RGBA;
        if (p == 6409) return gl.LUMINANCE;
        if (p == 6410) return gl.LUMINANCE_ALPHA;
        if (p == 6402) return gl.DEPTH_COMPONENT;
        if (p == 34041) return gl.DEPTH_STENCIL;
        if (p == 33333) return gl.RED;
        if (p == 33334) return gl.RED_INTEGER;
        if (p == 33335) return gl.RG;
        if (p == 33336) return gl.RG_INTEGER;
        if (p == 33337) return gl.RGBA_INTEGER;
        if (p == 33776) {
            if (colorSpace == 1) {
                var extension = extensions.get("WEBGL_compressed_texture_s3tc_srgb");
                if (extension != null) {
                    if (p == 33777) return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
                    if (p == 33778) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
                    if (p == 33779) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
                    if (p == 33780) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
                } else {
                    return null;
                }
            } else {
                var extension = extensions.get("WEBGL_compressed_texture_s3tc");
                if (extension != null) {
                    if (p == 33777) return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
                    if (p == 33778) return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
                    if (p == 33779) return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
                    if (p == 33780) return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
                } else {
                    return null;
                }
            }
        }
        if (p == 35840) {
            var extension = extensions.get("WEBGL_compressed_texture_pvrtc");
            if (extension != null) {
                if (p == 35841) return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
                if (p == 35842) return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
                if (p == 35843) return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
                if (p == 35844) return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
            } else {
                return null;
            }
        }
        if (p == 36196) {
            var extension = extensions.get("WEBGL_compressed_texture_etc");
            if (extension != null) {
                if (p == 36196 || p == 37492) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
                if (p == 37496) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
            } else {
                return null;
            }
        }
        if (p == 37808) {
            var extension = extensions.get("WEBGL_compressed_texture_astc");
            if (extension != null) {
                if (p == 37808) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
                if (p == 37809) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
                if (p == 37810) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
                if (p == 37811) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
                if (p == 37812) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
                if (p == 37813) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
                if (p == 37814) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
                if (p == 37815) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
                if (p == 37816) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
                if (p == 37817) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
                if (p == 37818) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
                if (p == 37819) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
                if (p == 37820) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
                if (p == 37821) return (colorSpace == 1) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
            } else {
                return null;
            }
        }
        if (p == 37493) {
            var extension = extensions.get("EXT_texture_compression_bptc");
            if (extension != null) {
                if (p == 37493) return (colorSpace == 1) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
            } else {
                return null;
            }
        }
        if (p == 36283) {
            var extension = extensions.get("EXT_texture_compression_rgtc");
            if (extension != null) {
                if (p == 36283) return extension.COMPRESSED_RED_RGTC1_EXT;
                if (p == 36284) return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
                if (p == 36285) return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
                if (p == 36286) return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
            } else {
                return null;
            }
        }
        if (p == 34037) return gl.UNSIGNED_INT_24_8;
        return (gl[p] != null) ? gl[p] : null;
    }

    public function _clientWaitAsync() {
        var sync = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
        gl.flush();
        return new Promise<Void>(function(resolve, reject) {
            function test() {
                var res = gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0);
                if (res == gl.WAIT_FAILED) {
                    gl.deleteSync(sync);
                    reject();
                    return;
                }
                if (res == gl.TIMEOUT_EXPIRED) {
                    window.requestAnimationFrame(test);
                    return;
                }
                gl.deleteSync(sync);
                resolve();
            }
            test();
        });
    }
}