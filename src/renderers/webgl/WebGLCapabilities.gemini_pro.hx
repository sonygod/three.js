import haxe.io.Bytes;
import three.constants.Constants;

class WebGLCapabilities {
  public var maxAnisotropy:Float;

  public function new(gl:Dynamic, extensions:Dynamic, parameters:Dynamic, utils:Dynamic) {
    this.maxAnisotropy = null;
    this.getMaxAnisotropy();
  }

  public function getMaxAnisotropy():Float {
    if (this.maxAnisotropy != null) return this.maxAnisotropy;

    if (extensions.has('EXT_texture_filter_anisotropic')) {
      var extension = extensions.get('EXT_texture_filter_anisotropic');
      this.maxAnisotropy = cast gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
    } else {
      this.maxAnisotropy = 0;
    }

    return this.maxAnisotropy;
  }

  public function textureFormatReadable(textureFormat:Int):Bool {
    if (textureFormat != Constants.RGBAFormat && utils.convert(textureFormat) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT)) {
      return false;
    }

    return true;
  }

  public function textureTypeReadable(textureType:Int):Bool {
    var halfFloatSupportedByExt = (textureType == Constants.HalfFloatType) && (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float'));

    if (textureType != Constants.UnsignedByteType && utils.convert(textureType) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) && // Edge and Chrome Mac < 52 (#9513)
      textureType != Constants.FloatType && !halfFloatSupportedByExt) {
      return false;
    }

    return true;
  }

  public function getMaxPrecision(precision:String):String {
    if (precision == 'highp') {
      if (gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.HIGH_FLOAT).precision > 0 &&
        gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision > 0) {
        return 'highp';
      }

      precision = 'mediump';
    }

    if (precision == 'mediump') {
      if (gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.MEDIUM_FLOAT).precision > 0 &&
        gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT).precision > 0) {
        return 'mediump';
      }
    }

    return 'lowp';
  }

  public var precision:String;
  public var logarithmicDepthBuffer:Bool;
  public var maxTextures:Int;
  public var maxVertexTextures:Int;
  public var maxTextureSize:Int;
  public var maxCubemapSize:Int;
  public var maxAttributes:Int;
  public var maxVertexUniforms:Int;
  public var maxVaryings:Int;
  public var maxFragmentUniforms:Int;
  public var vertexTextures:Bool;
  public var maxSamples:Int;

  public function init(gl:Dynamic, extensions:Dynamic, parameters:Dynamic, utils:Dynamic) {
    this.precision = parameters.precision != null ? parameters.precision : 'highp';
    var maxPrecision = this.getMaxPrecision(this.precision);

    if (maxPrecision != this.precision) {
      trace('THREE.WebGLRenderer: ${this.precision} not supported, using ${maxPrecision} instead.');
      this.precision = maxPrecision;
    }

    this.logarithmicDepthBuffer = parameters.logarithmicDepthBuffer == true;
    this.maxTextures = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
    this.maxVertexTextures = gl.getParameter(gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
    this.maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
    this.maxCubemapSize = gl.getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE);
    this.maxAttributes = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
    this.maxVertexUniforms = gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS);
    this.maxVaryings = gl.getParameter(gl.MAX_VARYING_VECTORS);
    this.maxFragmentUniforms = gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS);
    this.vertexTextures = this.maxVertexTextures > 0;
    this.maxSamples = gl.getParameter(gl.MAX_SAMPLES);
  }

  public function isWebGL2():Bool {
    return true;
  }
}


Here's a breakdown of the changes:

* **Import Statements:** The `import` statements have been adjusted to reflect the Haxe class structure.
* **Class Structure:**  Haxe uses classes with `new` constructors. The `WebGLCapabilities` class now takes the necessary parameters in its constructor and initializes its members.
* **Dynamic Types:** The `Dynamic` type is used to represent objects that can be of any type. This allows us to interact with the WebGL API without specifying exact types.
* **`cast` Function:** The `cast` function is used to convert a `Dynamic` value to a specific type. For example, `cast gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT)` converts the result of `gl.getParameter` to a `Float`.
* **`trace` Function:**  The `trace` function is used for debugging output. It's equivalent to `console.warn` in JavaScript.
* **Member Variables:**  Member variables are defined as `public var` within the class.
* **`init` Function:**  We've created an `init` function to encapsulate the initialization logic that was previously done in the constructor.
* **`isWebGL2` Function:**  This function is kept for backwards compatibility, though it always returns `true` in this context.

**Important Notes:**

* **WebGL Library:**  This Haxe code assumes you have a WebGL library available that provides the necessary API (e.g., a Haxe port of a WebGL library). You'll need to include that library in your project. 
* **Context:** The `gl` variable represents the WebGL context. You'll need to obtain this from your WebGL library.
* **Extensions:** The `extensions` variable should be an object representing the WebGL extensions available in your context.

**How to Use:**

1. **Include the necessary Haxe libraries.**
2. **Create a WebGL context (`gl`).**
3. **Create a new instance of `WebGLCapabilities`:**
   
   var capabilities = new WebGLCapabilities(gl, extensions, parameters, utils);
   capabilities.init(gl, extensions, parameters, utils);
   
4. **Access the capabilities:**
   
   trace("Max Anisotropy: ${capabilities.maxAnisotropy}");
   trace("Texture Format Readable: ${capabilities.textureFormatReadable(Constants.RGBAFormat)}");