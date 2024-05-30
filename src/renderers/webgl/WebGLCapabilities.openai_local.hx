import three.constants.FloatType;
import three.constants.HalfFloatType;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;

class WebGLCapabilities {
  var gl:Dynamic;
  var extensions:Dynamic;
  var parameters:Dynamic;
  var utils:Dynamic;
  var maxAnisotropy:Null<Int>;

  public function new(gl:Dynamic, extensions:Dynamic, parameters:Dynamic, utils:Dynamic) {
    this.gl = gl;
    this.extensions = extensions;
    this.parameters = parameters;
    this.utils = utils;
    this.maxAnisotropy = null;
  }

  public function getMaxAnisotropy():Int {
    if (maxAnisotropy != null) return maxAnisotropy;

    if (extensions.has('EXT_texture_filter_anisotropic')) {
      var extension = extensions.get('EXT_texture_filter_anisotropic');
      maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
    } else {
      maxAnisotropy = 0;
    }

    return maxAnisotropy;
  }

  public function textureFormatReadable(textureFormat:Int):Bool {
    return textureFormat == RGBAFormat || utils.convert(textureFormat) == gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT);
  }

  public function textureTypeReadable(textureType:Int):Bool {
    var halfFloatSupportedByExt = textureType == HalfFloatType && (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float'));

    return textureType == UnsignedByteType || utils.convert(textureType) == gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) || (textureType == FloatType || halfFloatSupportedByExt);
  }

  public function getMaxPrecision(precision:String):String {
    if (precision == 'highp') {
      if (gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.HIGH_FLOAT).precision > 0 && gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision > 0) {
        return 'highp';
      }
      precision = 'mediump';
    }

    if (precision == 'mediump') {
      if (gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.MEDIUM_FLOAT).precision > 0 && gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT).precision > 0) {
        return 'mediump';
      }
    }

    return 'lowp';
  }

  public function getCapabilities():Dynamic {
    var precision = parameters.precision != null ? parameters.precision : 'highp';
    var maxPrecision = getMaxPrecision(precision);

    if (maxPrecision != precision) {
      trace('THREE.WebGLRenderer: $precision not supported, using $maxPrecision instead.');
      precision = maxPrecision;
    }

    var logarithmicDepthBuffer = parameters.logarithmicDepthBuffer == true;
    var maxTextures = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
    var maxVertexTextures = gl.getParameter(gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
    var maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
    var maxCubemapSize = gl.getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE);

    var maxAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
    var maxVertexUniforms = gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS);
    var maxVaryings = gl.getParameter(gl.MAX_VARYING_VECTORS);
    var maxFragmentUniforms = gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS);

    var vertexTextures = maxVertexTextures > 0;
    var maxSamples = gl.getParameter(gl.MAX_SAMPLES);

    return {
      isWebGL2: true,
      getMaxAnisotropy: getMaxAnisotropy,
      getMaxPrecision: getMaxPrecision,
      textureFormatReadable: textureFormatReadable,
      textureTypeReadable: textureTypeReadable,
      precision: precision,
      logarithmicDepthBuffer: logarithmicDepthBuffer,
      maxTextures: maxTextures,
      maxVertexTextures: maxVertexTextures,
      maxTextureSize: maxTextureSize,
      maxCubemapSize: maxCubemapSize,
      maxAttributes: maxAttributes,
      maxVertexUniforms: maxVertexUniforms,
      maxVaryings: maxVaryings,
      maxFragmentUniforms: maxFragmentUniforms,
      vertexTextures: vertexTextures,
      maxSamples: maxSamples
    };
  }
}