package three.js.examples.jsm.renderers.webgl.utils;

import three.js.*;

class WebGLUtils {
  public var backend:Dynamic;
  public var gl:Dynamic;
  public var extensions:Dynamic;

  public function new(backend:Dynamic) {
    this.backend = backend;
    this.gl = backend.gl;
    this.extensions = backend.extensions;
  }

  public function convert(p:EnumValue, colorSpace:EnumValue = NoColorSpace):Null<Int> {
    var gl = this.gl;
    var extensions = this.extensions;

    if (p == UnsignedByteType) return gl.UNSIGNED_BYTE;
    if (p == UnsignedShort4444Type) return gl.UNSIGNED_SHORT_4_4_4_4;
    if (p == UnsignedShort5551Type) return gl.UNSIGNED_SHORT_5_5_5_1;
    if (p == UnsignedInt5999Type) return gl.UNSIGNED_INT_5_9_9_9_REV;

    if (p == ByteType) return gl.BYTE;
    if (p == ShortType) return gl.SHORT;
    if (p == UnsignedShortType) return gl.UNSIGNED_SHORT;
    if (p == IntType) return gl.INT;
    if (p == UnsignedIntType) return gl.UNSIGNED_INT;
    if (p == FloatType) return gl.FLOAT;

    if (p == HalfFloatType) return gl.HALF_FLOAT;

    if (p == AlphaFormat) return gl.ALPHA;
    if (p == RGBFormat) return gl.RGB;
    if (p == RGBAFormat) return gl.RGBA;
    if (p == LuminanceFormat) return gl.LUMINANCE;
    if (p == LuminanceAlphaFormat) return gl.LUMINANCE_ALPHA;
    if (p == DepthFormat) return gl.DEPTH_COMPONENT;
    if (p == DepthStencilFormat) return gl.DEPTH_STENCIL;

    // WebGL2 formats.

    if (p == RedFormat) return gl.RED;
    if (p == RedIntegerFormat) return gl.RED_INTEGER;
    if (p == RGFormat) return gl.RG;
    if (p == RGIntegerFormat) return gl.RG_INTEGER;
    if (p == RGBAIntegerFormat) return gl.RGBA_INTEGER;

    // S3TC

    if (p == RGB_S3TC_DXT1_Format || p == RGBA_S3TC_DXT1_Format || p == RGBA_S3TC_DXT3_Format || p == RGBA_S3TC_DXT5_Format) {
      if (colorSpace == SRGBColorSpace) {
        var extension = extensions.get('WEBGL_compressed_texture_s3tc_srgb');
        if (extension != null) {
          if (p == RGB_S3TC_DXT1_Format) return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
          if (p == RGBA_S3TC_DXT1_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
          if (p == RGBA_S3TC_DXT3_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
          if (p == RGBA_S3TC_DXT5_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
        } else {
          return null;
        }
      } else {
        var extension = extensions.get('WEBGL_compressed_texture_s3tc');
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
      var extension = extensions.get('WEBGL_compressed_texture_pvrtc');
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
      var extension = extensions.get('WEBGL_compressed_texture_etc');
      if (extension != null) {
        if (p == RGB_ETC1_Format || p == RGB_ETC2_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
        if (p == RGBA_ETC2_EAC_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
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
      var extension = extensions.get('WEBGL_compressed_texture_astc');
      if (extension != null) {
        if (p == RGBA_ASTC_4x4_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
        if (p == RGBA_ASTC_5x4_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
        if (p == RGBA_ASTC_5x5_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
        if (p == RGBA_ASTC_6x5_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
        if (p == RGBA_ASTC_6x6_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
        if (p == RGBA_ASTC_8x5_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
        if (p == RGBA_ASTC_8x6_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_rgba_ASTC_8x6_KHR;
        if (p == RGBA_ASTC_8x8_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
        if (p == RGBA_ASTC_10x5_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
        if (p == RGBA_ASTC_10x6_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
        if (p == RGBA_ASTC_10x8_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
        if (p == RGBA_ASTC_10x10_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
        if (p == RGBA_ASTC_12x10_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
        if (p == RGBA_ASTC_12x12_Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
      } else {
        return null;
      }
    }

    // BPTC

    if (p == RGBA_BPTC_Format) {
      var extension = extensions.get('EXT_texture_compression_bptc');
      if (extension != null) {
        return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
      } else {
        return null;
      }
    }

    // RGTC

    if (p == RED_RGTC1_Format || p == SIGNED_RED_RGTC1_Format || p == RED_GREEN_RGTC2_Format || p == SIGNED_RED_GREEN_RGTC2_Format) {
      var extension = extensions.get('EXT_texture_compression_rgtc');
      if (extension != null) {
        if (p == RED_RGTC1_Format) return extension.COMPRESSED_RED_RGTC1_EXT;
        if (p == SIGNED_RED_RGTC1_Format) return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
        if (p == RED_GREEN_RGTC2_Format) return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
        if (p == SIGNED_RED_GREEN_RGTC2_Format) return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
      } else {
        return null;
      }
    }

    // if "p" can't be resolved, assume the user defines a WebGL constant as a string (fallback/workaround for packed RGB formats)

    return (gl[p] != null) ? gl[p] : null;
  }

  public function clientWaitAsync():Promise<Void> {
    var gl = this.gl;
    var sync = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
    gl.flush();

    return new Promise( (resolve, reject) -> {
      function test() {
        var res = gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0);
        if (res == gl.WAIT_FAILED) {
          gl.deleteSync(sync);
          reject();
          return;
        }
        if (res == gl.TIMEOUT_EXPIRED) {
          haxe.Timer.delay(test, 0);
          return;
        }
        gl.deleteSync(sync);
        resolve();
      }
      test();
    });
  }
}