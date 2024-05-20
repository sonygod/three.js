import three.js.src.constants.*;

class WebGLCapabilities {

	var maxAnisotropy:Float;

	public function new(gl:Dynamic, extensions:Dynamic, parameters:Dynamic, utils:Dynamic) {

		function getMaxAnisotropy():Float {

			if (maxAnisotropy !== undefined) return maxAnisotropy;

			if (extensions.has('EXT_texture_filter_anisotropic') === true) {

				var extension = extensions.get('EXT_texture_filter_anisotropic');

				maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);

			} else {

				maxAnisotropy = 0;

			}

			return maxAnisotropy;

		}

		function textureFormatReadable(textureFormat:Float):Bool {

			if (textureFormat !== RGBAFormat && utils.convert(textureFormat) !== gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT)) {

				return false;

			}

			return true;

		}

		function textureTypeReadable(textureType:Float):Bool {

			var halfFloatSupportedByExt = (textureType === HalfFloatType) && (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float'));

			if (textureType !== UnsignedByteType && utils.convert(textureType) !== gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) && // Edge and Chrome Mac < 52 (#9513)
				textureType !== FloatType && ! halfFloatSupportedByExt) {

				return false;

			}

			return true;

		}

		function getMaxPrecision(precision:String):String {

			if (precision === 'highp') {

				if (gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.HIGH_FLOAT).precision > 0 &&
					gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision > 0) {

					return 'highp';

				}

				precision = 'mediump';

			}

			if (precision === 'mediump') {

				if (gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.MEDIUM_FLOAT).precision > 0 &&
					gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT).precision > 0) {

					return 'mediump';

				}

			}

			return 'lowp';

		}

		var precision = parameters.precision !== undefined ? parameters.precision : 'highp';
		var maxPrecision = getMaxPrecision(precision);

		if (maxPrecision !== precision) {

			trace('THREE.WebGLRenderer:', precision, 'not supported, using', maxPrecision, 'instead.');
			precision = maxPrecision;

		}

		var logarithmicDepthBuffer = parameters.logarithmicDepthBuffer === true;

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

			isWebGL2: true, // keeping this for backwards compatibility

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