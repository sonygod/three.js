Here is the converted Haxe code:
```
package three.js.examples.jsm.renderers.webgl.utils;

import three.js.RgbaAstc4x4Format;
import three.js.RgbaAstc5x4Format;
import three.js.RgbaAstc5x5Format;
import three.js.RgbaAstc6x5Format;
import three.js.RgbaAstc6x6Format;
import three.js.RgbaAstc8x5Format;
import three.js.RgbaAstc8x6Format;
import three.js.RgbaAstc8x8Format;
import three.js.RgbaAstc10x5Format;
import three.js.RgbaAstc10x6Format;
import three.js.RgbaAstc10x8Format;
import three.js.RgbaAstc10x10Format;
import three.js.RgbaAstc12x10Format;
import three.js.RgbaAstc12x12Format;
import three.js.RgbEtc1Format;
import three.js.RgbEtc2Format;
import three.js.RgbaEtc2EacFormat;
import three.js.RgbaPvrtc2bppv1Format;
import three.js.RgbaPvrtc4bppv1Format;
import three.js.RgbPvrtc2bppv1Format;
import three.js.RgbPvrtc4bppv1Format;
import three.js.RgbaS3tcDxt5Format;
import three.js.RgbaS3tcDxt3Format;
import three.js.RgbaS3tcDxt1Format;
import three.js.RgbS3tcDxt1Format;
import three.js.DepthFormat;
import three.js.DepthStencilFormat;
import three.js.LuminanceAlphaFormat;
import three.js.LuminanceFormat;
import three.js.RedFormat;
import three.js.RgbFormat;
import three.js.RgbaFormat;
import three.js.AlphaFormat;
import three.js.RedIntegerFormat;
import three.js.RgFormat;
import three.js.RgIntegerFormat;
import three.js.RgbaIntegerFormat;
import three.js.HalfFloatType;
import three.js.FloatType;
import three.js.UnsignedIntType;
import three.js.IntType;
import three.js.UnsignedShortType;
import three.js.ShortType;
import three.js.ByteType;
import three.js.UnsignedInt248Type;
import three.js.UnsignedInt5999Type;
import three.js.UnsignedShort5551Type;
import three.js.UnsignedShort4444Type;
import three.js.UnsignedByteType;
import three.js.RgbaBptcFormat;
import three.js.RedRgtc1Format;
import three.js.SignedRedRgtc1Format;
import three.js.RedGreenRgtc2Format;
import three.js.SignedRedGreenRgtc2Format;
import three.js.SRGBColorSpace;
import three.js.NoColorSpace;

class WebGLUtils {
  public var backend:Dynamic;
  public var gl:Dynamic;
  public var extensions:Dynamic;

  public function new(backend:Dynamic) {
    this.backend = backend;
    this.gl = this.backend.gl;
    this.extensions = backend.extensions;
  }

  public function convert(p:Dynamic, colorSpace:Dynamic = NoColorSpace):Dynamic {
    var gl:Dynamic = this.gl;
    var extensions:Dynamic = this.extensions;

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

    if (p == HalfFloatType) {
      return gl.HALF_FLOAT;
    }

    if (p == AlphaFormat) return gl.ALPHA;
    if (p == RgbFormat) return gl.RGB;
    if (p == RgbaFormat) return gl.RGBA;
    if (p == LuminanceFormat) return gl.LUMINANCE;
    if (p == LuminanceAlphaFormat) return gl.LUMINANCE_ALPHA;
    if (p == DepthFormat) return gl.DEPTH_COMPONENT;
    if (p == DepthStencilFormat) return gl.DEPTH_STENCIL;

    if (p == RedFormat) return gl.RED;
    if (p == RedIntegerFormat) return gl.RED_INTEGER;
    if (p == RgFormat) return gl.RG;
    if (p == RgIntegerFormat) return gl.RG_INTEGER;
    if (p == RgbaIntegerFormat) return gl.RGBA_INTEGER;

    if (p == RgbS3tcDxt1Format || p == RgbaS3tcDxt1Format || p == RgbaS3tcDxt3Format || p == RgbaS3tcDxt5Format) {
      var extension = extensions.get('WEBGL_compressed_texture_s3tc');

      if (extension != null) {
        if (colorSpace == SRGBColorSpace) {
          if (p == RgbS3tcDxt1Format) return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
          if (p == RgbaS3tcDxt1Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
          if (p == RgbaS3tcDxt3Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
          if (p == RgbaS3tcDxt5Format) return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
        } else {
          if (p == RgbS3tcDxt1Format) return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
          if (p == RgbaS3tcDxt1Format) return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
          if (p == RgbaS3tcDxt3Format) return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
          if (p == RgbaS3tcDxt5Format) return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
        }
      } else {
        return null;
      }
    }

    if (p == RgbPvrtc2bppv1Format || p == RgbPvrtc4bppv1Format || p == RgbaPvrtc2bppv1Format || p == RgbaPvrtc4bppv1Format) {
      var extension = extensions.get('WEBGL_compressed_texture_pvrtc');

      if (extension != null) {
        if (p == RgbPvrtc2bppv1Format) return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
        if (p == RgbPvrtc4bppv1Format) return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
        if (p == RgbaPvrtc2bppv1Format) return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
        if (p == RgbaPvrtc4bppv1Format) return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
      } else {
        return null;
      }
    }

    if (p == RgbEtc1Format || p == RgbEtc2Format || p == RgbaEtc2EacFormat) {
      var extension = extensions.get('WEBGL_compressed_texture_etc');

      if (extension != null) {
        if (p == RgbEtc1Format || p == RgbEtc2Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
        if (p == RgbaEtc2EacFormat) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
      } else {
        return null;
      }
    }

    if (p == RgbaAstc4x4Format || p == RgbaAstc5x4Format || p == RgbaAstc5x5Format || p == RgbaAstc6x5Format || p == RgbaAstc6x6Format || p == RgbaAstc8x5Format || p == RgbaAstc8x6Format || p == RgbaAstc8x8Format || p == RgbaAstc10x5Format || p == RgbaAstc10x6Format || p == RgbaAstc10x8Format || p == RgbaAstc10x10Format || p == RgbaAstc12x10Format || p == RgbaAstc12x12Format) {
      var extension = extensions.get('WEBGL_compressed_texture_astc');

      if (extension != null) {
        if (p == RgbaAstc4x4Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
        if (p == RgbaAstc5x4Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
        if (p == RgbaAstc5x5Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : extension.COMPRESSED_RGBA_ASTC_5x5_KHR;
        if (p == RgbaAstc6x5Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : extension.COMPRESSED_RGBA_ASTC_6x5_KHR;
        if (p == RgbaAstc6x6Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : extension.COMPRESSED_RGBA_ASTC_6x6_KHR;
        if (p == RgbaAstc8x5Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : extension.COMPRESSED_RGBA_ASTC_8x5_KHR;
        if (p == RgbaAstc8x6Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : extension.COMPRESSED_RGBA_ASTC_8x6_KHR;
        if (p == RgbaAstc8x8Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : extension.COMPRESSED_RGBA_ASTC_8x8_KHR;
        if (p == RgbaAstc10x5Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : extension.COMPRESSED_RGBA_ASTC_10x5_KHR;
        if (p == RgbaAstc10x6Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : extension.COMPRESSED_RGBA_ASTC_10x6_KHR;
        if (p == RgbaAstc10x8Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : extension.COMPRESSED_RGBA_ASTC_10x8_KHR;
        if (p == RgbaAstc10x10Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : extension.COMPRESSED_RGBA_ASTC_10x10_KHR;
        if (p == RgbaAstc12x10Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : extension.COMPRESSED_RGBA_ASTC_12x10_KHR;
        if (p == RgbaAstc12x12Format) return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : extension.COMPRESSED_RGBA_ASTC_12x12_KHR;
      } else {
        return null;
      }
    }

    if (p == RgbaBptcFormat) {
      var extension = extensions.get('EXT_texture_compression_bptc');

      if (extension != null) {
        return (colorSpace == SRGBColorSpace) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
      } else {
        return null;
      }
    }

    if (p == RedRgtc1Format || p == SignedRedRgtc1Format || p == RedGreenRgtc2Format || p == SignedRedGreenRgtc2Format) {
      var extension = extensions.get('EXT_texture_compression_rgtc');

      if (extension != null) {
        if (p == RedRgtc1Format) return extension.COMPRESSED_RED_RGTC1_EXT;
        if (p == SignedRedRgtc1Format) return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
        if (p == RedGreenRgtc2Format) return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
        if (p == SignedRedGreenRgtc2Format) return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
      } else {
        return null;
      }
    }

    if (p == UnsignedInt248Type) {
      return gl.UNSIGNED_INT_24_8;
    }

    // if "p" can't be resolved, assume the user defines a WebGL constant as a string (fallback/workaround for packed RGB formats)
    return (gl[p] != undefined) ? gl[p] : null;
  }

  public function clientWaitAsync():Promise<Void> {
    var gl:Dynamic = this.gl;

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
```
Note that I used the `haxe.Timer.delay` function to create a recursive timer in the `clientWaitAsync` function, as Haxe does not have a built-in equivalent to JavaScript's `requestAnimationFrame`.