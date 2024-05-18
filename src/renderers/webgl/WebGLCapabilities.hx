package renderers.webgl;

import constants.FloatType;
import constants.HalfFloatType;
import constants.RGBAFormat;
import constants.UnsignedByteType;

class WebGLCapabilities {
    private var gl:Dynamic;
    private var extensions:Dynamic;
    private var parameters:Dynamic;
    private var utils:Dynamic;

    private var maxAnisotropy:Null<Float>;

    public function new(gl:Dynamic, extensions:Dynamic, parameters:Dynamic, utils:Dynamic) {
        this.gl = gl;
        this.extensions = extensions;
        this.parameters = parameters;
        this.utils = utils;

        var maxPrecision:String = getMaxPrecision(parameters.precision != null ? parameters.precision : 'highp');

        if (maxPrecision != parameters.precision) {
            trace('THREE.WebGLRenderer: ' + parameters.precision + ' not supported, using ' + maxPrecision + ' instead.');
            parameters.precision = maxPrecision;
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

        this.maxAnisotropy = null;

        this.getMaxAnisotropy = getMaxAnisotropy;
        this.getMaxPrecision = getMaxPrecision;

        this.textureFormatReadable = textureFormatReadable;
        this.textureTypeReadable = textureTypeReadable;

        this.precision = parameters.precision;
        this.logarithmicDepthBuffer = logarithmicDepthBuffer;

        this.maxTextures = maxTextures;
        this.maxVertexTextures = maxVertexTextures;
        this.maxTextureSize = maxTextureSize;
        this.maxCubemapSize = maxCubemapSize;

        this.maxAttributes = maxAttributes;
        this.maxVertexUniforms = maxVertexUniforms;
        this.maxVaryings = maxVaryings;
        this.maxFragmentUniforms = maxFragmentUniforms;

        this.vertexTextures = vertexTextures;

        this.maxSamples = maxSamples;
    }

    private function getMaxAnisotropy():Null<Float> {
        if (maxAnisotropy != null) return maxAnisotropy;

        if (extensions.has('EXT_texture_filter_anisotropic')) {
            var extension = extensions.get('EXT_texture_filter_anisotropic');
            maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else {
            maxAnisotropy = 0;
        }

        return maxAnisotropy;
    }

    private function getMaxPrecision(precision:String):String {
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

    private function textureFormatReadable(textureFormat:Dynamic):Bool {
        if (textureFormat != RGBAFormat && utils.convert(textureFormat) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_FORMAT)) {
            return false;
        }
        return true;
    }

    private function textureTypeReadable(textureType:Dynamic):Bool {
        var halfFloatSupportedByExt:Bool = (textureType == HalfFloatType) && (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float'));
        if (textureType != UnsignedByteType && utils.convert(textureType) != gl.getParameter(gl.IMPLEMENTATION_COLOR_READ_TYPE) &&
            textureType != FloatType && !halfFloatSupportedByExt) {
            return false;
        }
        return true;
    }
}