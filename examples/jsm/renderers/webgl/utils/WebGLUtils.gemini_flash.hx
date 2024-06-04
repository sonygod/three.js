import three.constants.Constants;

class WebGLUtils {

  public var backend:Dynamic;
  public var gl:Dynamic;
  public var extensions:Dynamic;

  public function new(backend:Dynamic) {
    this.backend = backend;
    this.gl = backend.gl;
    this.extensions = backend.extensions;
  }

  public function convert(p:Dynamic, colorSpace:Dynamic = Constants.NoColorSpace):Dynamic {
    var extension:Dynamic;

    if (p == Constants.UnsignedByteType) return this.gl.UNSIGNED_BYTE;
    if (p == Constants.UnsignedShort4444Type) return this.gl.UNSIGNED_SHORT_4_4_4_4;
    if (p == Constants.UnsignedShort5551Type) return this.gl.UNSIGNED_SHORT_5_5_5_1;
    if (p == Constants.UnsignedInt5999Type) return this.gl.UNSIGNED_INT_5_9_9_9_REV;

    if (p == Constants.ByteType) return this.gl.BYTE;
    if (p == Constants.ShortType) return this.gl.SHORT;
    if (p == Constants.UnsignedShortType) return this.gl.UNSIGNED_SHORT;
    if (p == Constants.IntType) return this.gl.INT;
    if (p == Constants.UnsignedIntType) return this.gl.UNSIGNED_INT;
    if (p == Constants.FloatType) return this.gl.FLOAT;

    if (p == Constants.HalfFloatType) {
      return this.gl.HALF_FLOAT;
    }

    if (p == Constants.AlphaFormat) return this.gl.ALPHA;
    if (p == Constants.RGBFormat) return this.gl.RGB;
    if (p == Constants.RGBAFormat) return this.gl.RGBA;
    if (p == Constants.LuminanceFormat) return this.gl.LUMINANCE;
    if (p == Constants.LuminanceAlphaFormat) return this.gl.LUMINANCE_ALPHA;
    if (p == Constants.DepthFormat) return this.gl.DEPTH_COMPONENT;
    if (p == Constants.DepthStencilFormat) return this.gl.DEPTH_STENCIL;

    // WebGL2 formats.

    if (p == Constants.RedFormat) return this.gl.RED;
    if (p == Constants.RedIntegerFormat) return this.gl.RED_INTEGER;
    if (p == Constants.RGFormat) return this.gl.RG;
    if (p == Constants.RGIntegerFormat) return this.gl.RG_INTEGER;
    if (p == Constants.RGBAIntegerFormat) return this.gl.RGBA_INTEGER;

    // S3TC

    if (p == Constants.RGB_S3TC_DXT1_Format || p == Constants.RGBA_S3TC_DXT1_Format || p == Constants.RGBA_S3TC_DXT3_Format || p == Constants.RGBA_S3TC_DXT5_Format) {
      if (colorSpace == Constants.SRGBColorSpace) {
        extension = this.extensions.get('WEBGL_compressed_texture_s3tc_srgb');
        if (extension != null) {
          if (p == Constants.RGB_S3TC_DXT1_Format) return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
          if (p == Constants.RGBA_S3TC_DXT1_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
          if (p == Constants.RGBA_S3TC_DXT3_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
          if (p == Constants.RGBA_S3TC_DXT5_Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
        } else {
          return null;
        }
      } else {
        extension = this.extensions.get('WEBGL_compressed_texture_s3tc');
        if (extension != null) {
          if (p == Constants.RGB_S3TC_DXT1_Format) return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
          if (p == Constants.RGBA_S3TC_DXT1_Format) return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
          if (p == Constants.RGBA_S3TC_DXT3_Format) return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
          if (p == Constants.RGBA_S3TC_DXT5_Format) return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
        } else {
          return null;
        }
      }
    }

    // PVRTC

    if (p == Constants.RGB_PVRTC_4BPPV1_Format || p == Constants.RGB_PVRTC_2BPPV1_Format || p == Constants.RGBA_PVRTC_4BPPV1_Format || p == Constants.RGBA_PVRTC_2BPPV1_Format) {
      extension = this.extensions.get('WEBGL_compressed_texture_pvrtc');
      if (extension != null) {
        if (p == Constants.RGB_PVRTC_4BPPV1_Format) return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
        if (p == Constants.RGB_PVRTC_2BPPV1_Format) return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
        if (p == Constants.RGBA_PVRTC_4BPPV1_Format) return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
        if (p == Constants.RGBA_PVRTC_2BPPV1_Format) return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
      } else {
        return null;
      }
    }

    // ETC

    if (p == Constants.RGB_ETC1_Format || p == Constants.RGB_ETC2_Format || p == Constants.RGBA_ETC2_EAC_Format) {
      extension = this.extensions.get('WEBGL_compressed_texture_etc');
      if (extension != null) {
        if (p == Constants.RGB_ETC1_Format || p == Constants.RGB_ETC2_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
        if (p == Constants.RGBA_ETC2_EAC_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
      } else {
        return null;
      }
    }

    // ASTC

    if (p == Constants.RGBA_ASTC_4x4_Format || p == Constants.RGBA_ASTC_5x4_Format || p == Constants.RGBA_ASTC_5x5_Format ||
      p == Constants.RGBA_ASTC_6x5_Format || p == Constants.RGBA_ASTC_6x6_Format || p == Constants.RGBA_ASTC_8x5_Format ||
      p == Constants.RGBA_ASTC_8x6_Format || p == Constants.RGBA_ASTC_8x8_Format || p == Constants.RGBA_ASTC_10x5_Format ||
      p == Constants.RGBA_ASTC_10x6_Format || p == Constants.RGBA_ASTC_10x8_Format || p == Constants.RGBA_ASTC_10x10_Format ||
      p == Constants.RGBA_ASTC_12x10_Format || p == Constants.RGBA_ASTC_12x12_Format) {
      extension = this.extensions.get('WEBGL_compressed_texture_astc');
      if (extension != null) {
        if (p == Constants.RGBA_ASTC_4x4_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
        if (p == Constants.RGBA_ASTC_5x4_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
        if (p == Constants.RGBA_ASTC_5x5_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
        if (p == Constants.RGBA_ASTC_6x5_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
        if (p == Constants.RGBA_ASTC_6x6_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
        if (p == Constants.RGBA_ASTC_8x5_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
        if (p == Constants.RGBA_ASTC_8x6_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
        if (p == Constants.RGBA_ASTC_8x8_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
        if (p == Constants.RGBA_ASTC_10x5_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
        if (p == Constants.RGBA_ASTC_10x6_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
        if (p == Constants.RGBA_ASTC_10x8_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
        if (p == Constants.RGBA_ASTC_10x10_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
        if (p == Constants.RGBA_ASTC_12x10_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
        if (p == Constants.RGBA_ASTC_12x12_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
      } else {
        return null;
      }
    }

    // BPTC

    if (p == Constants.RGBA_BPTC_Format) {
      extension = this.extensions.get('EXT_texture_compression_bptc');
      if (extension != null) {
        if (p == Constants.RGBA_BPTC_Format) return (colorSpace == Constants.SRGBColorSpace) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
      } else {
        return null;
      }
    }

    // RGTC

    if (p == Constants.RED_RGTC1_Format || p == Constants.SIGNED_RED_RGTC1_Format || p == Constants.RED_GREEN_RGTC2_Format || p == Constants.SIGNED_RED_GREEN_RGTC2_Format) {
      extension = this.extensions.get('EXT_texture_compression_rgtc');
      if (extension != null) {
        if (p == Constants.RGBA_BPTC_Format) return extension.COMPRESSED_RED_RGTC1_EXT;
        if (p == Constants.SIGNED_RED_RGTC1_Format) return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
        if (p == Constants.RED_GREEN_RGTC2_Format) return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
        if (p == Constants.SIGNED_RED_GREEN_RGTC2_Format) return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
      } else {
        return null;
      }
    }

    //

    if (p == Constants.UnsignedInt248Type) {
      return this.gl.UNSIGNED_INT_24_8;
    }

    // if "p" can't be resolved, assume the user defines a WebGL constant as a string (fallback/workaround for packed RGB formats)

    return (this.gl[p] != null) ? this.gl[p] : null;
  }

  public function _clientWaitAsync():Dynamic {
    var sync = this.gl.fenceSync(this.gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
    this.gl.flush();
    return new haxe.macro.Promise(function(resolve, reject) {
      function test() {
        var res = this.gl.clientWaitSync(sync, this.gl.SYNC_FLUSH_COMMANDS_BIT, 0);
        if (res == this.gl.WAIT_FAILED) {
          this.gl.deleteSync(sync);
          reject();
          return;
        }
        if (res == this.gl.TIMEOUT_EXPIRED) {
          haxe.Timer.delay(test, 16);
          return;
        }
        this.gl.deleteSync(sync);
        resolve();
      }
      test();
    });
  }

}