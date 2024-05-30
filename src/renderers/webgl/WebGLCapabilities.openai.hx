package three.renderers.webgl;

import three.constants.FloatType;
import three.constants.HalfFloatType;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;

class WebGLCapabilities {
	static function getMaxAnisotropy(gl:WebGLRenderingContext, extensions:Map<String, Dynamic>):Int {
		if (maxAnisotropy != null) return maxAnisotropy;
		if (extensions.exists('EXT_texture_filter_anisotropic')) {
			var extension = extensions.get('EXT_texture_filter_anisotropic');
			maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
		} else {
			maxAnisotropy = 0;
		}
		return maxAnisotropy;
	}

	static function textureFormatReadable(textureFormat:Int, gl:WebGLRenderingContext, utils:Utils):Bool {
		if (textureFormat != RGBAFormat && utils.convert(textureFormat) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT)) {
			return false;
		}
		return true;
	}

	static function textureTypeReadable(textureType:Int, extensions:Map<String, Dynamic>):Bool {
		var halfFloatSupportedByExt = (textureType == HalfFloatType) && (extensions.exists('EXT_color_buffer_half_float') || extensions.exists('EXT_color_buffer_float'));
		if (textureType != UnsignedByteType && utils.convert(textureType) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) && !halfFloatSupportedByExt) {
			return false;
		}
		return true;
	}

	static function getMaxPrecision(precision:String, gl:WebGLRenderingContext):String {
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

	public static function init(gl:WebGLRenderingContext, extensions:Map<String, Dynamic>, parameters:Dynamic, utils:Utils):WebGLCapabilities {
		var maxAnisotropy:Int;
		var precision:String = parameters.precision != null ? parameters.precision : 'highp';
		var maxPrecision:String = getMaxPrecision(precision, gl);
		if (maxPrecision != precision) {
			trace('THREE.WebGLRenderer:', precision, 'not supported, using', maxPrecision, 'instead.');
			precision = maxPrecision;
		}

		var logarithmicDepthBuffer:Bool = parameters.logarithmicDepthBuffer == true;
		var maxTextures:Int = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
		var maxVertexTextures:Int = gl.getParameter(gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
		var maxTextureSize:Int = gl.getParameter(gl.MAX_TEXTURE_SIZE);
		var maxCubemapSize:Int = gl.getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE);
		var maxAttributes:Int = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
		var maxVertexUniforms:Int = gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS);
		var maxVaryings:Int = gl.getParameter(gl.MAX_VARYING_VECTORS);
		var maxFragmentUniforms:Int = gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS);
		var vertexTextures:Bool = maxVertexTextures > 0;
		var maxSamples:Int = gl.getParameter(gl.MAX_SAMPLES);

		return {
			isWebGL2: true, // keeping this for backwards compatibility

			getMaxAnisotropy: getMaxAnisotropy.bind(_, gl, extensions),
			getMaxPrecision: getMaxPrecision.bind(_, _, gl),

			textureFormatReadable: textureFormatReadable.bind(_, _, gl, utils),
			textureTypeReadable: textureTypeReadable.bind(_, extensions),

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