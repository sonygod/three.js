import three.js.src.constants.FloatType;
import three.js.src.constants.HalfFloatType;
import three.js.src.constants.RGBAFormat;
import three.js.src.constants.UnsignedByteType;

class WebGLCapabilities {
    var maxAnisotropy:Float;

    public function new(gl:WebGLRenderingContext, extensions:Map<String, Dynamic>, parameters:Map<String, Dynamic>, utils:Dynamic) {
        this.maxAnisotropy = undefined;

        function getMaxAnisotropy() {
            if (this.maxAnisotropy !== undefined) return this.maxAnisotropy;

            if (extensions.exists('EXT_texture_filter_anisotropic')) {
                var extension = extensions.get('EXT_texture_filter_anisotropic');
                this.maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
            } else {
                this.maxAnisotropy = 0;
            }

            return this.maxAnisotropy;
        }

        function textureFormatReadable(textureFormat) {
            if (textureFormat !== RGBAFormat && utils.convert(textureFormat) !== gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT)) {
                return false;
            }

            return true;
        }

        function textureTypeReadable(textureType) {
            var halfFloatSupportedByExt = (textureType === HalfFloatType) && (extensions.exists('EXT_color_buffer_half_float') || extensions.exists('EXT_color_buffer_float'));

            if (textureType !== UnsignedByteType && utils.convert(textureType) !== gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) && // Edge and Chrome Mac < 52 (#9513)
                textureType !== FloatType && !halfFloatSupportedByExt) {
                return false;
            }

            return true;
        }

        function getMaxPrecision(precision) {
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

        var precision = parameters.exists('precision') ? parameters.get('precision') : 'highp';
        var maxPrecision = getMaxPrecision(precision);

        if (maxPrecision !== precision) {
            trace('THREE.WebGLRenderer:', precision, 'not supported, using', maxPrecision, 'instead.');
            precision = maxPrecision;
        }

        var logarithmicDepthBuffer = parameters.exists('logarithmicDepthBuffer') && parameters.get('logarithmicDepthBuffer') === true;

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