import js.html.WebGLRenderingContext;
import js.html.WebGLTexture;
import js.html.WebGLBuffer;
import js.html.WebGLFramebuffer;
import js.html.WebGLRenderbuffer;
import js.html.ImageBitmap;
import js.html.OffscreenCanvas;
import js.html.ImageData;
import js.html.CanvasPixelArray;

class WebGLTextureUtils {
    var initialized:Bool;
    var wrappingToGL:Map<Int,Int>;
    var filterToGL:Map<Int,Int>;
    var compareToGL:Map<Int,Int>;
    var backend:Dynamic;
    var gl:WebGLRenderingContext;
    var extensions:Dynamic;
    var defaultTextures:Map<Int,WebGLTexture>;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = backend.gl;
        this.extensions = backend.extensions;
        this.defaultTextures = {};

        if (!initialized) {
            _init(gl);
            initialized = true;
        }
    }

    function _init(gl:WebGLRenderingContext) {
        wrappingToGL = {
            RepeatWrapping: gl.REPEAT,
            ClampToEdgeWrapping: gl.CLAMP_TO_EDGE,
            MirroredRepeatWrapping: gl.MIRRORED_REPEAT
        };

        filterToGL = {
            NearestFilter: gl.NEAREST,
            NearestMipmapNearestFilter: gl.NEAREST_MIPMAP_NEAREST,
            NearestMipmapLinearFilter: gl.NEAREST_MIPMAP_LINEAR,
            LinearFilter: gl.LINEAR,
            LinearMipmapNearestFilter: gl.LINEAR_MIPMAP_NEAREST,
            LinearMipmapLinearFilter: gl.LINEAR_MIPMAP_LINEAR
        };

        compareToGL = {
            NeverCompare: gl.NEVER,
            AlwaysCompare: gl.ALWAYS,
            LessCompare: gl.LESS,
            LessEqualCompare: gl.LEQUAL,
            EqualCompare: gl.EQUAL,
            GreaterEqualCompare: gl.GEQUAL,
            GreaterCompare: gl.GREATER,
            NotEqualCompare: gl.NOTEQUAL
        };
    }

    function filterFallback(f:Int) -> Int {
        if (f == NearestFilter || f == NearestMipmapNearestFilter || f == NearestMipmapLinearFilter) {
            return gl.NEAREST;
        }
        return gl.LINEAR;
    }

    function getGLTextureType(texture:Dynamic) -> Int {
        if (texture.isCubeTexture) {
            return gl.TEXTURE_CUBE_MAP;
        } else if (texture.isDataArrayTexture) {
            return gl.TEXTURE_2D_ARRAY;
        } else {
            return gl.TEXTURE_2D;
        }
    }

    function getInternalFormat(internalFormatName:String, glFormat:Int, glType:Int, colorSpace:Int, forceLinearTransfer:Bool = false) -> Int {
        if (internalFormatName != null) {
            if (Reflect.hasField(gl, internalFormatName)) {
                return Reflect.field(gl, internalFormatName);
            }
            trace("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '" + internalFormatName + "'");
        }

        var internalFormat:Int = glFormat;

        if (glFormat == gl.RED) {
            if (glType == gl.FLOAT) internalFormat = gl.R32F;
            if (glType == gl.HALF_FLOAT) internalFormat = gl.R16F;
            if (glType == gl.UNSIGNED_BYTE) internalFormat = gl.R8;
        }

        if (glFormat == gl.RED_INTEGER) {
            if (glType == gl.UNSIGNED_BYTE) internalFormat = gl.R8UI;
            if (glType == gl.UNSIGNED_SHORT) internalFormat = gl.R16UI;
            if (glType == gl.UNSIGNED_INT) internalFormat = gl.R32UI;
            if (glType == gl.BYTE) internalFormat = gl.R8I;
            if (glType == gl.SHORT) internalFormat = gl.R16I;
            if (glType == gl.INT) internalFormat = gl.R32I;
        }

        if (glFormat == gl.RG) {
            if (glType == gl.FLOAT) internalFormat = gl.RG32F;
            if (glType == gl.HALF_FLOAT) internalFormat = gl.RG16F;
            if (glType == gl.UNSIGNED_BYTE) internalFormat = gl.RG8;
        }

        if (glFormat == gl.RGB) {
            if (glType == gl.FLOAT) internalFormat = gl.RGB32F;
            if (glType == gl.HALF_FLOAT) internalFormat = gl.RGB16F;
            if (glType == gl.UNSIGNED_BYTE) internalFormat = gl.RGB8;
            if (glType == gl.UNSIGNED_SHORT_5_6_5) internalFormat = gl.RGB565;
            if (glType == gl.UNSIGNED_SHORT_5_5_5_1) internalFormat = gl.RGB5_A1;
            if (glType == gl.UNSIGNED_SHORT_4_4_4_4) internalFormat = gl.RGB4;
            if (glType == gl.UNSIGNED_INT_5_9_9_9_REV) internalFormat = gl.RGB9_E5;
        }

        if (glFormat == gl.RGBA) {
            if (glType == gl.FLOAT) internalFormat = gl.RGBA32F;
            if (glType == gl.HALF_FLOAT) internal PMIDATE_MIPMAP_LINEAR_FILTER = gl.LINEAR_MIPMAP_LINEAR;

        gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, filterToGL[minFilter]);

        if (texture.compareFunction != null) {
            gl.texParameteri(textureType, gl.TEXTURE_COMPARE_MODE, gl.COMPARE_REF_TO_TEXTURE);
            gl.texParameteri(textureType, gl.TEXTURE_COMPARE_FUNC, compareToGL[texture.compareFunction]);
        }

        if (extensions.has("EXT_texture_filter_anisotropic")) {
            if (texture.magFilter == NearestFilter) return;
            if (texture.minFilter != NearestMipmapLinearFilter && texture.minFilter != LinearMipmapLinearFilter) return;
            if (texture.type == FloatType && !extensions.has("OES_texture_float_linear")) return;

            if (texture.anisotropy > 1 || currentAnisotropy != texture.anisotropy) {
                var extension = extensions.get("EXT_texture_filter_anisotropic");
                gl.texParameterf(textureType, extension.TEXTURE_MAX_ANISOTROPY_EXT, min(texture.anisotropy, backend.getMaxAnisotropy()));
                backend.get(texture).currentAnisotropy = texture.anisotropy;
            }
        }
    }

    function createDefaultTexture(texture:Dynamic) {
        var glTextureType = getGLTextureType(texture);
        var textureGPU = defaultTextures.get(glTextureType);

        if (textureGPU == null) {
            textureGPU = gl.createTexture();
            backend.state.bindTexture(glTextureType, textureGPU);
            gl.texParameteri(glTextureType, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(glTextureType, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            defaultTextures[glTextureType] = textureGPU;
        }

        backend.set(texture, {
            textureGPU: textureGPU,
            glTextureType: glTextureType,
            isDefault: true
        });
    }

    function createTexture(texture:Dynamic, options:Dynamic) {
        var levels = options.levels;
        var width = options.width;
        var height = options.height;
        var depth = options.depth;

        var glFormat = backend.utils.convert(texture.format, texture.colorSpace);
        var glType = backend.utils.convert(texture.type);
        var glInternalFormat = getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace, texture.isVideoTexture);

        var textureGPU = gl.createTexture();
        var glTextureType = getGLTextureType(texture);

        backend.state.bindTexture(glTextureType, textureGPU);

        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY);
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha);
        gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
        gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);

        setTextureParameters(glTextureType, texture);

        if (texture.isDataArrayTexture) {
            gl.texStorage3D(gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, width, height, depth);
        } else if (!texture.isVideoTexture) {
            gl.texStorage2D(glTextureType, levels, glInternalFormat, width, height);
        }

        backend.set(texture, {
            textureGPU: textureGPU,
            glTextureType: glTextureType,
            glFormat: glFormat,
            glType: glType,
            glInternalFormat: glInternalFormat
        });
    }

    function copyBufferToTexture(buffer:WebGLBuffer, texture:Dynamic) {
        var textureGPU = backend.get(texture).textureGPU;
        var glTextureType = backend.get(texture).glTextureType;
        var glFormat = backend.get(texture).glFormat;
        var glType = backend.get(texture).glType;

        var width = texture.source.data.width;
        var height = texture.source.data.height;

        gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, buffer);
        backend.state.bindTexture(glTextureType, textureGPU);
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
        gl.texSubImage2D(glTextureType, 0, 0, 0, width, height, glFormat, glType, 0);
        gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, null);
        backend.state.unbindTexture();
    }

    function updateTexture(texture:Dynamic, options:Dynamic) {
        var width = options.width;
        var height = options.height;
        var textureGPU = backend.get(texture).textureGPU;
        var glTextureType = backend.get(texture).glTextureType;
        var glFormat = backend.get(texture).glFormat;
        var glType = backend.get(texture).glType;
        var glInternalFormat = backend.get(texture).glInternalFormat;

        if (texture.isRenderTargetTexture || textureGPU == null) return;

        function getImage(source:Dynamic) {
            if (source.isDataTexture) {
                return source.image.data;
            } else if (source instanceof ImageBitmap || source instanceof OffscreenCanvas || source instanceof Image || source instanceof Canvas) {
                return source;
            }
            return source.data;
        }

        backend.state.bindTexture(glTextureType, textureGPU);

        if (texture.isCompressedTexture) {
            var mipmaps = texture.mipmaps;
            for (mipmap in mipmaps) {
                if (texture.isCompressedArrayTexture) {
                    var image = options.image;
                    if (texture.format != gl.RGBA) {
                        if (glFormat != null) {
                            gl.compressedTexSubImage3D(gl.TEXTURE_2D_ARRAY, mipmap.level, mipmap.x, mipmap.y, 0, mipmap.width, mipmap.height, image.depth, glFormat, mipmap.data, 0, 0);
                        } else {
                            trace("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()");
                        }
                    } else {
                        gl.texSubImage3D(gl.TEXTURE_2D_ARRAY, mipmap.level, mipmap.x, mipmap.y, 0, mipmap.width, mipmap.height, image.depth, glFormat, glType, mipmap.data);
                    }
                } else {
                    if (glFormat != null) {
                        gl.compressedTexSubImage2D(gl.TEXTURE_2D, mipmap.level, mipmap.x, mipmap.y, mipmap.width, mipmap.height, glFormat, mipmap.data);
                    } else {
                        trace("Unsupported compressed texture format");
                    }
                }
            }
        } else if (texture.isCubeTexture) {
            var images = options.images;
            for (i in 0...6) {
                var image = getImage(images[i]);
                gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, 0, 0, width, height, glFormat, glType, image);
            }
        } else if (texture.isDataArrayTexture) {
            var image = options.image;
            gl.texSubImage3D(gl.TEXTURE_2D_ARRAY, 0, 0, 0, 0, image.width, image.height, image.depth, glFormat, glType, image.data);
        } else if (texture.isVideoTexture) {
            texture.update();
            gl.texImage2D(glTextureType, 0, glInternalFormat, glFormat, glType, options.image);
        } else {
            var image = getImage(options.image);
            gl.texSubImage2D(glTextureType, 0, 0, 0, width, height, glFormat, glType, image);
        }
    }

    function generateMipmaps(texture:Dynamic) {
        var textureGPU = backend.get(texture).textureGPU;
        var glTextureType = backend.get(texture).glTextureType;
        backend.state.bindTexture(glTextureType, textureGPU);
        gl.generateMipmap(glTextureType);
    }

    function deallocateRenderBuffers(renderTarget:Dynamic) {
        if (renderTarget != null) {
            var renderContextData = backend.get(renderTarget);
            renderContextData.renderBufferStorageSetup = null;
            if (renderContextData.framebuffer != null) {
                gl.deleteFramebuffer(renderContextData.framebuffer);
                renderContextData.framebuffer = null;
            }
            if (renderContextData.depthRenderbuffer != null) {
                gl.deleteRenderbuffer(renderContextData.depthRenderbuffer);
                renderContextData.depthRenderbuffer = null;
            }
            if (renderContextData.stencilRenderbuffer != null) {
                gl.deleteRenderbuffer(renderContextData.stencilRenderbuffer);
                renderContextData.stencilRenderbuffer = null;
            }
            if (renderContextData.msaaFrameBuffer != null) {
                gl.deleteFramebuffer(renderContextData.msaaFrameBuffer);
                renderContextData.msaaFrameBuffer = null;
            }
            if (renderContextData.msaaRenderbuffers != null) {
                for (renderbuffer in renderContextData.msaaRenderbuffers) {
                    gl.deleteRenderbuffer(renderbuffer);
                }
                renderContextData.msaaRenderbuffers = null;
            }
        }
    }

    function destroyTexture(texture:Dynamic) {
        var textureGPU = backend.get(texture).textureGPU;
        var renderTarget = backend.get(texture).renderTarget;
        deallocateRenderBuffers(renderTarget);
        gl.deleteTexture(textureGPU);
        backend.delete(texture);
    }

    function copyTextureToTexture(srcTexture:Dynamic, dstTexture:Dynamic, srcRegion:Dynamic = null, dstPosition:Dynamic = null, level:Int = 0) {
        var dstTextureGPU = backend.get(dstTexture).textureGPU;
        var glTextureType = backend.get(dstTexture).glTextureType;
        var glType = backend.get(dstTexture).glType;
        var glFormat = backend.get(dstTexture).glFormat;

        var width:Int, height:Int, minX:Int, minY:Int;
        var dstX:Int, dstY:Int;
        if (srcRegion != null) {
            width = srcRegion.max.x - srcRegion.min.x;
            height = srcRegion.max.y - srcRegion.min.y;
            minX = srcRegion.min.x;
            minY = srcRegion.min.y;
        } else {
            width = srcTexture.image.width;
            height = srcTexture.image.height;
            minX = 0;
            minY = 0;
        }

        if (dstPosition != null) {
            dstX = dstPosition.x;
            dstY = dstPosition.y;
        } else {
            dstX = 0;
            dstY = 0;
        }

        backend.state.bindTexture(glTextureType, dstTextureGPU);

        gl.pixelStorei(gl.UNPACK_ALIGNMENT, dstTexture.unpackAlignment);
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, dstTexture.flipY);
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, dstTexture.premultiplyAlpha);
        gl.pixelStorei(gl.UNPACK_ALIGNMENT, dstTexture.unpackAlignment);

        var currentUnpackRowLen = gl.getParameter(gl.UNPACK_ROW_LENGTH);
        var currentUnpackImageHeight = gl.getParameter(gl.UNPACK_IMAGE_HEIGHT);
        var currentUnpackSkipPixels = gl.getParameter(gl.UNPACK_SKIP_PIXELS);
        var currentUnpackSkipRows = gl.getParameter(gl.UNPACK_SKIP_ROWS);
        var currentUnpackSkipImages = gl.getParameter(gl.
UNPACK_SKIP_IMAGES);

        var image = srcTexture.isCompressedTexture ? srcTexture.mipmaps[level] : srcTexture.image;

        gl.pixelStorei(gl.UNPACK_ROW_LENGTH, image.width);
        gl.pixelStorei(gl.UNPACK_IMAGE_HEIGHT, image.height);
        gl.pixelStorei(gl.UNPACK_SKIP_PIXELS, minX);
        gl.pixelStorei(gl.UNPACK_SKIP_ROWS, minY);

        if (srcTexture.isDataTexture) {
            gl.texSubImage2D(gl.TEXTURE_2D, level, dstX, dstY, width, height, glFormat, glType, image.data);
        } else {
            if (srcTexture.isCompressedTexture) {
                gl.compressedTexSubImage2D(gl.TEXTURE_2D, level, dstX, dstY, image.width, image.height, glFormat, image.data);
            } else {
                gl.texSubImage2D(gl.TEXTURE_2D, level, dstX, dstY, glFormat, glType, image);
            }
        }

        gl.pixelStorei(gl.UNPACK_ROW_LENGTH, currentUnpackRowLen);
        gl.pixelStorei(gl.UNPACK_IMAGE_HEIGHT, currentUnpackImageHeight);
        gl.pixelStorei(gl.UNPACK_SKIP_PIXELS, currentUnpackSkipPixels);
        gl.pixelStorei(gl.UNPACK_SKIP_ROWS, currentUnpackSkipRows);
        gl.pixelStorei(gl.UNPACK_SKIP_IMAGES, currentUnpackSkipImages);

        if (level == 0 && dstTexture.generateMipmaps) {
            gl.generateMipmap(gl.TEXTURE_2D);
        }

        backend.state.unbindTexture();
    }

    function copyFramebufferToTexture(texture:Dynamic, renderContext:Dynamic) {
        var textureGPU = backend.get(texture).textureGPU;
        var width = texture.image.width;
        var height = texture.image.height;
        var requireDrawFrameBuffer = texture.isDepthTexture || (renderContext.renderTarget != null && renderContext.renderTarget.samples > 0);

        if (requireDrawFrameBuffer) {
            var mask:Int, attachment:Int;

            if (texture.isDepthTexture) {
                mask = gl.DEPTH_BUFFER_BIT;
                attachment = gl.DEPTH_ATTACHMENT;

                if (renderContext.stencil) {
                    mask |= gl.STENCIL_BUFFER_BIT;
                }
            } else {
                mask = gl.COLOR_BUFFER_BIT;
                attachment = gl.COLOR_ATTACHMENT0;
            }

            var fb = gl.createFramebuffer();
            backend.state.bindFramebuffer(gl.DRAW_FRAMEBUFFER, fb);
            gl.framebufferTexture2D(gl.DRAW_FRAMEBUFFER, attachment, gl.TEXTURE_2D, textureGPU, 0);
            gl.blitFramebuffer(0, 0, width, height, 0, 0, width, height, mask, gl.NEAREST);
            gl.deleteFramebuffer(fb);
        } else {
            backend.state.bindTexture(gl.TEXTURE_2D, textureGPU);
            gl.copyTexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 0, 0, width, height);
            backend.state.unbindTexture();
        }

        if (texture.generateMipmaps) {
            generateMipmaps(texture);
        }

        backend._setFramebuffer(renderContext);
    }

    function setupRenderBufferStorage(renderbuffer:WebGLRenderbuffer, renderContext:Dynamic) {
        var renderTarget = renderContext.renderTarget;
        var samples = renderTarget.samples;
        var depthTexture = renderTarget.depthTexture;
        var depthBuffer = renderTarget.depthBuffer;
        var stencilBuffer = renderTarget.stencilBuffer;
        var width = renderTarget.width;
        var height = renderTarget.height;

        gl.bindRenderbuffer(gl.RENDERBUFFER, renderbuffer);

        if (depthBuffer && !stencilBuffer) {
            var glInternalFormat = gl.DEPTH_COMPONENT24;

            if (samples > 0) {
                if (depthTexture && depthTexture.isDepthTexture) {
                    if (depthTexture.type == gl.FLOAT) {
                        glInternalFormat = gl.DEPTH_COMPONENT32F;
                    }
                }
                gl.renderbufferStorageMultisample(gl.RENDERBUFFER, samples, glInternalFormat, width, height);
            } else {
                gl.renderbufferStorage(gl.RENDERBUFFER, glInternalFormat, width, height);
            }
            gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
        } else if (depthBuffer && stencilBuffer) {
            if (samples > 0) {
                gl.renderbufferStorageMultisample(gl.RENDERBUFFER, samples, gl.DEPTH24_STENCIL8, width, height);
            } else {
                gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_STENCIL, width, height);
            }
            gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
        }
    }

    function copyTextureToBuffer(texture:Dynamic, x:Int, y:Int, width:Int, height:Int):Dynamic {
        var textureGPU = backend.get(texture).textureGPU;
        var glFormat = backend.get(texture).glFormat;
        var glType = backend.get(texture).glType;

        var fb = gl.createFramebuffer();
        gl.bindFramebuffer(gl.READ_FRAMEBUFFER, fb);
        gl.framebufferTexture2D(gl.READ_FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, textureGPU, 0);

        var typedArrayType = _getTypedArrayType(glType);
        var bytesPerTexel = _getBytesPerTexel(glFormat);

        var elementCount = width * height;
        var byteLength = elementCount * bytesPerTexel;

        var buffer = gl.createBuffer();
        gl.bindBuffer(gl.PIXEL_PACK_BUFFER, buffer);
        gl.bufferData(gl.PIXEL_PACK_BUFFER, byteLength, gl.STREAM_READ);
        gl.readPixels(x, y, width, height, glFormat, glType, 0);
        gl.bindBuffer(gl.PIXEL_PACK_BUFFER, null);

        backend.utils._clientWaitAsync();

        var dstBuffer = typedArrayType.make(byteLength / typedArrayType.BYTES_PER_ELEMENT);
        gl.bindBuffer(gl.PIXEL_PACK_BUFFER, buffer);
        gl.getBufferSubData(gl.PIXEL_PACK_BUFFER, 0, dstBuffer);
        gl.bindBuffer(gl.PIXEL_PACK_BUFFER, null);
        gl.deleteFramebuffer(fb);

        return dstBuffer;
    }

    function _getTypedArrayType(glType:Int):Dynamic {
        if (glType == gl.UNSIGNED_BYTE) return Uint8Array;
        if (glType == gl.UNSIGNED_SHORT_4_4_4_4) return Uint16Array;
        if (glType == gl.UNSIGNED_SHORT_5_5_5_1) return Uint16Array;
        if (glType == gl.UNSIGNED_SHORT_5_6_5) return Uint16Array;
        if (glType == gl.UNSIGNED_SHORT) return Uint16Array;
        if (glType == gl.UNSIGNED_INT) return Uint32Array;
        if (glType == gl.FLOAT) return Float32Array;
        throw "Unsupported WebGL type: " + glType;
    }

    function _getBytesPerTexel(glFormat:Int):Int {
        if (glFormat == gl.RGBA) return 4;
        if (glFormat == gl.RGB) return 3;
        if (glFormat == gl.ALPHA) return 1;
        return 0;
    }
}