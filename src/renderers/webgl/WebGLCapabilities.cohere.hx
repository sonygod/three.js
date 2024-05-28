import js.WebGLRenderingContext.*;
import js.WebGL2RenderingContext.*;

class WebGLCapabilities {
    var maxAnisotropy:Int;
    var precision:String;
    var maxPrecision:String;
    var logarithmicDepthBuffer:Bool;

    public function new(gl:WebGLRenderingContext, extensions:Dynamic, parameters:Dynamic, utils:Dynamic) {
        maxAnisotropy = getMaxAnisotropy();

        precision = parameters.precision != null ? parameters.precision : 'highp';
        maxPrecision = getMaxPrecision(precision);
        if (maxPrecision != precision) {
            trace('THREE.WebGLRenderer:', precision, 'not supported, using', maxPrecision, 'instead.');
            precision = maxPrecision;
        }

        logarithmicDepthBuffer = parameters.logarithmicDepthBuffer;

        maxTextures = gl.getParameter(MAX_TEXTURE_IMAGE_UNITS);
        maxVertexTextures = gl.getParameter(MAX_VERTEX_TEXTURE_IMAGE_UNITS);
        maxTextureSize = gl.getParameter(MAX_TEXTURE_SIZE);
        maxCubemapSize = gl.getParameter(MAX_CUBE_MAP_TEXTURE_SIZE);

        maxAttributes = gl.getParameter(MAX_VERTEX_ATTRIBS);
        maxVertexUniforms = gl.getParameter(MAX_VERTEX_UNIFORM_VECTORS);
        maxVaryings = gl.getParameter(MAX_VARYING_VECTORS);
        maxFragmentUniforms = gl.getParameter(MAX_FRAGMENT_UNIFORM_VECTORS);

        vertexTextures = maxVertexTextures > 0;

        maxSamples = gl.getParameter(MAX_SAMPLES);
    }

    public function getMaxAnisotropy():Int {
        if (maxAnisotropy != null) return maxAnisotropy;

        if (extensions.hasOwnProperty('EXT_texture_filter_anisotropic')) {
            var extension = extensions['EXT_texture_filter_anisotropic'];
            maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else {
            maxAnisotropy = 0;
        }

        return maxAnisotropy;
    }

    public function getMaxPrecision(precision:String):String {
        if (precision == 'highp') {
            if (gl.getShaderPrecisionFormat(VERTEX_SHADER, HIGH_FLOAT).precision > 0 &&
                gl.getShaderPrecisionFormat(FRAGMENT_SHADER, HIGH_FLOAT).precision > 0) {
                return 'highp';
            }
            precision = 'mediump';
        }

        if (precision == 'mediump') {
            if (gl.getShaderPrecisionFormat(VERTEX_SHADER, MEDIUM_FLOAT).precision > 0 &&
                gl.getShaderPrecisionFormat(FRAGMENT_SHADER, MEDIUM_FLOAT).precision > 0) {
                return 'mediump';
            }
        }

        return 'lowp';
    }

    public function textureFormatReadable(textureFormat:Int):Bool {
        if (textureFormat != RGBAFormat && utils.convert(textureFormat) != gl.getParameter(IMPLEMENTATION_COLOR_READ_FORMAT)) {
            return false;
        }
        return true;
    }

    public function textureTypeReadable(textureType:Int):Bool {
        var halfFloatSupportedByExt = (textureType == HalfFloatType) &&
            (extensions.hasOwnProperty('EXT_color_buffer_half_float') || extensions.hasOwnProperty('EXT_color_buffer_float'));

        if (textureType != UnsignedByteType && utils.convert(textureType) != gl.getParameter(IMPLEMENTATION_COLOR_READ_TYPE) &&
            textureType != FloatType && !halfFloatSupportedByExt) {
            return false;
        }
        return true;
    }

    public function get isWebGL2():Bool {
        return true; // keeping this for backwards compatibility
    }
}