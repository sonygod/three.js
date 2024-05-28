package three.js.src.renderers.webgl;

import three.constants.RgbaAstc4x4Format;
import three.constants.RgbaAstc5x4Format;
import three.constants.RgbaAstc5x5Format;
import three.constants.RgbaAstc6x5Format;
import three.constants.RgbaAstc6x6Format;
import three.constants.RgbaAstc8x5Format;
import three.constants.RgbaAstc8x6Format;
import three.constants.RgbaAstc8x8Format;
import three.constants.RgbaAstc10x5Format;
import three.constants.RgbaAstc10x6Format;
import three.constants.RgbaAstc10x8Format;
import three.constants.RgbaAstc10x10Format;
import three.constants.RgbaAstc12x10Format;
import three.constants.RgbaAstc12x12Format;
import three.constants.RgbEtc1Format;
import three.constants.RgbEtc2Format;
import three.constants.RgbaEtc2EacFormat;
import three.constants.RgbaPvrtc2bppv1Format;
import three.constants.RgbaPvrtc4bppv1Format;
import three.constants.RgbPvrtc2bppv1Format;
import three.constants.RgbPvrtc4bppv1Format;
import three.constants.RgbaS3tcDxt5Format;
import three.constants.RgbaS3tcDxt3Format;
import three.constants.RgbaS3tcDxt1Format;
import three.constants.RgbS3tcDxt1Format;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.LuminanceAlphaFormat;
import three.constants.LuminanceFormat;
import three.constants.RedFormat;
import three.constants.RgbaFormat;
import three.constants.AlphaFormat;
import three.constants.RedIntegerFormat;
import three.constants.RgFormat;
import three.constants.RgIntegerFormat;
import three.constants.RgbaIntegerFormat;
import three.constants.HalfFloatType;
import three.constants.FloatType;
import three.constants.UnsignedIntType;
import three.constants.IntType;
import three.constants.UnsignedShortType;
import three.constants.ShortType;
import three.constants.ByteType;
import three.constants.UnsignedInt248Type;
import three.constants.UnsignedShort5551Type;
import three.constants.UnsignedShort4444Type;
import three.constants.UnsignedByteType;
import three.constants.RgbaBptcFormat;
import three.constants.RgbBptcSignedFormat;
import three.constants.RgbBptcUnsignedFormat;
import three.constants.RedRgtc1Format;
import three.constants.SignedRedRgtc1Format;
import three.constants.RedGreenRgtc2Format;
import three.constants.SignedRedGreenRgtc2Format;
import three.constants.NoColorSpace;
import three.constants.SrgbTransfer;
import three.constants.RgbFormat;

import three.math.ColorManagement;

class WebGLUtils {
  public var gl:WebGLRenderingContext;
  public var extensions:Extensions;

  public function new(gl:WebGLRenderingContext, extensions:Extensions) {
    this.gl = gl;
    this.extensions = extensions;
  }

  public function convert(p:Dynamic, colorSpace:Int = NoColorSpace):Null<Int> {
    var extension:Dynamic;
    var transfer:Int = ColorManagement.getTransfer(colorSpace);

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
      case RgbFormat:
        return gl.RGB;
      case RgbaFormat:
        return gl.RGBA;
      case LuminanceFormat:
        return gl.LUMINANCE;
      case LuminanceAlphaFormat:
        return gl.LUMINANCE_ALPHA;
      case DepthFormat:
        return gl.DEPTH_COMPONENT;
      case DepthStencilFormat:
        return gl.DEPTH_STENCIL;

      // WebGL2 formats
      case RedFormat:
        return gl.RED;
      case RedIntegerFormat:
        return gl.RED_INTEGER;
      case RgFormat:
        return gl.RG;
      case RgIntegerFormat:
        return gl.RG_INTEGER;
      case RgbaIntegerFormat:
        return gl.RGBA_INTEGER;

      // S3TC
      case RgbS3tcDxt1Format, RgbaS3tcDxt1Format, RgbaS3tcDxt3Format, RgbaS3tcDxt5Format:
        if (transfer == SrgbTransfer) {
          extension = extensions.get('WEBGL_compressed_texture_s3tc_srgb');
          if (extension != null) {
            switch (p) {
              case RgbS3tcDxt1Format:
                return extension.COMPRESSED_SRGB_S3TC_DXT1_EXT;
              case RgbaS3tcDxt1Format:
                return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;
              case RgbaS3tcDxt3Format:
                return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;
              case RgbaS3tcDxt5Format:
                return extension.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT;
            }
          } else {
            return null;
          }
        } else {
          extension = extensions.get('WEBGL_compressed_texture_s3tc');
          if (extension != null) {
            switch (p) {
              case RgbS3tcDxt1Format:
                return extension.COMPRESSED_RGB_S3TC_DXT1_EXT;
              case RgbaS3tcDxt1Format:
                return extension.COMPRESSED_RGBA_S3TC_DXT1_EXT;
              case RgbaS3tcDxt3Format:
                return extension.COMPRESSED_RGBA_S3TC_DXT3_EXT;
              case RgbaS3tcDxt5Format:
                return extension.COMPRESSED_RGBA_S3TC_DXT5_EXT;
            }
          } else {
            return null;
          }
        }

      // PVRTC
      case RgbPvrtc4bppv1Format, RgbPvrtc2bppv1Format, RgbaPvrtc4bppv1Format, RgbaPvrtc2bppv1Format:
        extension = extensions.get('WEBGL_compressed_texture_pvrtc');
        if (extension != null) {
          switch (p) {
            case RgbPvrtc4bppv1Format:
              return extension.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
            case RgbPvrtc2bppv1Format:
              return extension.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
            case RgbaPvrtc4bppv1Format:
              return extension.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            case RgbaPvrtc2bppv1Format:
              return extension.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
          }
        } else {
          return null;
        }

      // ETC
      case RgbEtc1Format, RgbEtc2Format, RgbaEtc2EacFormat:
        extension = extensions.get('WEBGL_compressed_texture_etc');
        if (extension != null) {
          switch (p) {
            case RgbEtc1Format, RgbEtc2Format:
              return (transfer == SrgbTransfer) ? extension.COMPRESSED_SRGB8_ETC2 : extension.COMPRESSED_RGB8_ETC2;
            case RgbaEtc2EacFormat:
              return (transfer == SrgbTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : extension.COMPRESSED_RGBA8_ETC2_EAC;
          }
        } else {
          return null;
        }

      // ASTC
      case RgbaAstc4x4Format, RgbaAstc5x4Format, RgbaAstc5x5Format,
           RgbaAstc6x5Format, RgbaAstc6x6Format, RgbaAstc8x5Format,
           RgbaAstc8x6Format, RgbaAstc8x8Format, RgbaAstc10x5Format,
           RgbaAstc10x6Format, RgbaAstc10x8Format, RgbaAstc10x10Format,
           RgbaAstc12x10Format, RgbaAstc12x12Format:
        extension = extensions.get('WEBGL_compressed_texture_astc');
        if (extension != null) {
          switch (p) {
            case RgbaAstc4x4Format:
              return (transfer == SrgbTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : extension.COMPRESSED_RGBA_ASTC_4x4_KHR;
            case RgbaAstc5x4Format:
              return (transfer == SrgbTransfer) ? extension.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : extension.COMPRESSED_RGBA_ASTC_5x4_KHR;
            // ...
          }
        } else {
          return null;
        }

      // BPTC
      case RgbaBptcFormat, RgbBptcSignedFormat, RgbBptcUnsignedFormat:
        extension = extensions.get('EXT_texture_compression_bptc');
        if (extension != null) {
          switch (p) {
            case RgbaBptcFormat:
              return (transfer == SrgbTransfer) ? extension.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT : extension.COMPRESSED_RGBA_BPTC_UNORM_EXT;
            case RgbBptcSignedFormat:
              return extension.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;
            case RgbBptcUnsignedFormat:
              return extension.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT;
          }
        } else {
          return null;
        }

      // RGTC
      case RedRgtc1Format, SignedRedRgtc1Format, RedGreenRgtc2Format, SignedRedGreenRgtc2Format:
        extension = extensions.get('EXT_texture_compression_rgtc');
        if (extension != null) {
          switch (p) {
            case RedRgtc1Format:
              return extension.COMPRESSED_RED_RGTC1_EXT;
            case SignedRedRgtc1Format:
              return extension.COMPRESSED_SIGNED_RED_RGTC1_EXT;
            case RedGreenRgtc2Format:
              return extension.COMPRESSED_RED_GREEN_RGTC2_EXT;
            case SignedRedGreenRgtc2Format:
              return extension.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT;
          }
        } else {
          return null;
        }

      default:
        if (Reflect.hasField(gl, p)) {
          return Reflect.field(gl, p);
        } else {
          return null;
        }
    }
  }
}