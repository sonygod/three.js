import haxe.io.Bytes;
import three.constants.FloatType;
import three.constants.HalfFloatType;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;
import three.utils.Utils;

class WebGLCapabilities {

	public var maxAnisotropy:Float;

	public var isWebGL2:Bool;

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

	public function new(gl:Dynamic, extensions:Dynamic, parameters:Dynamic, utils:Utils) {
		this.isWebGL2 = true;

		this.maxAnisotropy = getMaxAnisotropy(gl, extensions);

		this.precision = getMaxPrecision(gl, parameters.precision);

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

	public function getMaxAnisotropy(gl:Dynamic, extensions:Dynamic):Float {
		if (maxAnisotropy != null) return maxAnisotropy;

		if (extensions.has('EXT_texture_filter_anisotropic')) {
			var extension = extensions.get('EXT_texture_filter_anisotropic');
			maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
		} else {
			maxAnisotropy = 0;
		}

		return maxAnisotropy;
	}

	public function textureFormatReadable(gl:Dynamic, textureFormat:Int, utils:Utils):Bool {
		if (textureFormat != RGBAFormat && utils.convert(textureFormat) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT)) {
			return false;
		}

		return true;
	}

	public function textureTypeReadable(gl:Dynamic, textureType:Int, extensions:Dynamic, utils:Utils):Bool {
		var halfFloatSupportedByExt = (textureType == HalfFloatType) && (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float'));

		if (textureType != UnsignedByteType && utils.convert(textureType) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) && // Edge and Chrome Mac < 52 (#9513)
			textureType != FloatType && !halfFloatSupportedByExt) {
			return false;
		}

		return true;
	}

	public function getMaxPrecision(gl:Dynamic, precision:String):String {
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
}