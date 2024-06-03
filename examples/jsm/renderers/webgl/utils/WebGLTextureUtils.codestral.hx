import js.html.WebGLRenderingContext;
import js.html.HTMLImageElement;
import js.html.CanvasElement;
import js.html.OffscreenCanvas;
import js.html.ImageBitmap;

import three.LinearFilter;
import three.LinearMipmapLinearFilter;
import three.LinearMipmapNearestFilter;
import three.NearestFilter;
import three.NearestMipmapLinearFilter;
import three.NearestMipmapNearestFilter;
import three.FloatType;
import three.MirroredRepeatWrapping;
import three.ClampToEdgeWrapping;
import three.RepeatWrapping;
import three.SRGBColorSpace;
import three.NeverCompare;
import three.AlwaysCompare;
import three.LessCompare;
import three.LessEqualCompare;
import three.EqualCompare;
import three.GreaterEqualCompare;
import three.GreaterCompare;
import three.NotEqualCompare;

class WebGLTextureUtils {
    var initialized:Bool = false;
    var wrappingToGL:Map<Int, Int>;
    var filterToGL:Map<Int, Int>;
    var compareToGL:Map<Int, Int>;
    var gl:WebGLRenderingContext;
    var extensions:Dynamic;
    var defaultTextures:Map<Int, Dynamic>;
    var backend:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = backend.gl;
        this.extensions = backend.extensions;
        this.defaultTextures = new Map<Int, Dynamic>();

        if (!initialized) {
            this._init(this.gl);
            initialized = true;
        }
    }

    public function _init(gl:WebGLRenderingContext) {
        wrappingToGL = new Map<Int, Int>();
        wrappingToGL.set(RepeatWrapping, gl.REPEAT);
        wrappingToGL.set(ClampToEdgeWrapping, gl.CLAMP_TO_EDGE);
        wrappingToGL.set(MirroredRepeatWrapping, gl.MIRRORED_REPEAT);

        filterToGL = new Map<Int, Int>();
        filterToGL.set(NearestFilter, gl.NEAREST);
        filterToGL.set(NearestMipmapNearestFilter, gl.NEAREST_MIPMAP_NEAREST);
        filterToGL.set(NearestMipmapLinearFilter, gl.NEAREST_MIPMAP_LINEAR);
        filterToGL.set(LinearFilter, gl.LINEAR);
        filterToGL.set(LinearMipmapNearestFilter, gl.LINEAR_MIPMAP_NEAREST);
        filterToGL.set(LinearMipmapLinearFilter, gl.LINEAR_MIPMAP_LINEAR);

        compareToGL = new Map<Int, Int>();
        compareToGL.set(NeverCompare, gl.NEVER);
        compareToGL.set(AlwaysCompare, gl.ALWAYS);
        compareToGL.set(LessCompare, gl.LESS);
        compareToGL.set(LessEqualCompare, gl.LEQUAL);
        compareToGL.set(EqualCompare, gl.EQUAL);
        compareToGL.set(GreaterEqualCompare, gl.GEQUAL);
        compareToGL.set(GreaterCompare, gl.GREATER);
        compareToGL.set(NotEqualCompare, gl.NOTEQUAL);
    }

    public function filterFallback(f:Int):Int {
        if (f == NearestFilter || f == NearestMipmapNearestFilter || f == NearestMipmapLinearFilter) {
            return gl.NEAREST;
        }
        return gl.LINEAR;
    }

    public function getGLTextureType(texture:Dynamic):Int {
        if (texture.isCubeTexture) {
            return gl.TEXTURE_CUBE_MAP;
        } else if (texture.isDataArrayTexture) {
            return gl.TEXTURE_2D_ARRAY;
        } else {
            return gl.TEXTURE_2D;
        }
    }

    public function getInternalFormat(internalFormatName:String, glFormat:Int, glType:Int, colorSpace:Int, forceLinearTransfer:Bool = false):Int {
        if (internalFormatName != null) {
            if (gl[internalFormatName] != null) return gl[internalFormatName];
            js.Browser.console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '" + internalFormatName + "'");
        }

        var internalFormat:Int = glFormat;

        // Implementation for other cases (like RED, RED_INTEGER, RG, RGB, RGBA, DEPTH_COMPONENT, DEPTH_STENCIL)
        // ...

        if (internalFormat == gl.R16F || internalFormat == gl.R32F ||
            internalFormat == gl.RG16F || internalFormat == gl.RG32F ||
            internalFormat == gl.RGBA16F || internalFormat == gl.RGBA32F) {
            extensions.get("EXT_color_buffer_float");
        }

        return internalFormat;
    }

    public function setTextureParameters(textureType:Int, texture:Dynamic) {
        var currentAnisotropy = backend.get(texture).currentAnisotropy;

        gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, wrappingToGL.get(texture.wrapS));
        gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, wrappingToGL.get(texture.wrapT));

        if (textureType == gl.TEXTURE_3D || textureType == gl.TEXTURE_2D_ARRAY) {
            gl.texParameteri(textureType, gl.TEXTURE_WRAP_R, wrappingToGL.get(texture.wrapR));
        }

        gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER, filterToGL.get(texture.magFilter));

        var minFilter = !texture.isVideoTexture && texture.minFilter == LinearFilter ? LinearMipmapLinearFilter : texture.minFilter;
        gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, filterToGL.get(minFilter));

        if (texture.compareFunction) {
            gl.texParameteri(textureType, gl.TEXTURE_COMPARE_MODE, gl.COMPARE_REF_TO_TEXTURE);
            gl.texParameteri(textureType, gl.TEXTURE_COMPARE_FUNC, compareToGL.get(texture.compareFunction));
        }

        if (extensions.has("EXT_texture_filter_anisotropic")) {
            if (texture.magFilter == NearestFilter) return;
            if (texture.minFilter != NearestMipmapLinearFilter && texture.minFilter != LinearMipmapLinearFilter) return;
            if (texture.type == FloatType && extensions.has("OES_texture_float_linear") == false) return;

            if (texture.anisotropy > 1 || currentAnisotropy != texture.anisotropy) {
                var extension = extensions.get("EXT_texture_filter_anisotropic");
                gl.texParameterf(textureType, extension.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(texture.anisotropy, backend.getMaxAnisotropy()));
                backend.get(texture).currentAnisotropy = texture.anisotropy;
            }
        }
    }

    public function createDefaultTexture(texture:Dynamic) {
        var glTextureType:Int = this.getGLTextureType(texture);

        var textureGPU = defaultTextures.get(glTextureType);

        if (textureGPU == null) {
            textureGPU = gl.createTexture();
            backend.state.bindTexture(glTextureType, textureGPU);
            gl.texParameteri(glTextureType, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(glTextureType, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

            defaultTextures.set(glTextureType, textureGPU);
        }

        backend.set(texture, {
            textureGPU: textureGPU,
            glTextureType: glTextureType,
            isDefault: true
        });
    }

    public function createTexture(texture:Dynamic, options:Dynamic) {
        var glFormat:Int = backend.utils.convert(texture.format, texture.colorSpace);
        var glType:Int = backend.utils.convert(texture.type);
        var glInternalFormat:Int = this.getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace, texture.isVideoTexture);

        var textureGPU = gl.createTexture();
        var glTextureType:Int = this.getGLTextureType(texture);

        backend.state.bindTexture(glTextureType, textureGPU);

        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY);
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha);
        gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
        gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);

        this.setTextureParameters(glTextureType, texture);

        if (texture.isDataArrayTexture) {
            gl.texStorage3D(gl.TEXTURE_2D_ARRAY, options.levels, glInternalFormat, options.width, options.height, options.depth);
        } else if (!texture.isVideoTexture) {
            gl.texStorage2D(glTextureType, options.levels, glInternalFormat, options.width, options.height);
        }

        backend.set(texture, {
            textureGPU: textureGPU,
            glTextureType: glTextureType,
            glFormat: glFormat,
            glType: glType,
            glInternalFormat: glInternalFormat
        });
    }

    public function copyBufferToTexture(buffer:Dynamic, texture:Dynamic) {
        var textureGPU:Int = backend.get(texture).textureGPU;
        var glTextureType:Int = backend.get(texture).glTextureType;
        var glFormat:Int = backend.get(texture).glFormat;
        var glType:Int = backend.get(texture).glType;

        var width:Int = texture.source.data.width;
        var height:Int = texture.source.data.height;

        gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, buffer);
        backend.state.bindTexture(glTextureType, textureGPU);
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
        gl.texSubImage2D(glTextureType, 0, 0, 0, width, height, glFormat, glType, 0);
        gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, null);
        backend.state.unbindTexture();
    }

    // Other functions can be added similarly
}