package three.js.examples.jvm.renderers.webgl;

import openfl.display3D.Context3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.TextureBase;
import openfl.display3D.Context3DBlendMode;

class WebGLBackend {
    private var gl:Context3D;
    private var state:Dynamic;
    private var extensions:Dynamic;
    private var capabilities:Dynamic;
    private var attributeUtils:Dynamic;
    private var textureUtils:Dynamic;
    private var vaoCache:Map<String, VertexBuffer3D>;
    private var transformFeedbackCache:Map<String, IndexBuffer3D>;

    public function new(gl:Context3D, state:Dynamic, extensions:Dynamic, capabilities:Dynamic, attributeUtils:Dynamic, textureUtils:Dynamic) {
        this.gl = gl;
        this.state = state;
        this.extensions = extensions;
        this.capabilities = capabilities;
        this.attributeUtils = attributeUtils;
        this.textureUtils = textureUtils;
        this.vaoCache = new Map<String, VertexBuffer3D>();
        this.transformFeedbackCache = new Map<String, IndexBuffer3D>();
    }

    public function updateBindings(bindings:Array<Dynamic>) {
        var groupIndex:Int = 0;
        var textureIndex:Int = 0;

        for (binding in bindings) {
            if (binding.isUniformsGroup || binding.isUniformBuffer) {
                var bufferGPU:VertexBuffer3D = gl.createVertexBuffer(1);
                var data:ByteArray = binding.buffer;
                gl.bindBuffer(Context3D_BUFFER_DATA, bufferGPU);
                gl.bufferData(Context3D_BUFFER_DATA, data, Context3D_STREAM_DRAW);
                gl.bindBufferBase(Context3D_UNIFORM_BUFFER, groupIndex, bufferGPU);
                this.set(binding, { index: groupIndex++, bufferGPU: bufferGPU });
            } else if (binding.isSampledTexture) {
                var textureGPU:TextureBase = get(binding.texture).textureGPU;
                var glTextureType:Int = get(binding.texture).glTextureType;
                this.set(binding, { index: textureIndex++, textureGPU: textureGPU, glTextureType: glTextureType });
            }
        }
    }

    public function updateBinding(binding:Dynamic) {
        if (binding.isUniformsGroup || binding.isUniformBuffer) {
            var bindingData:Dynamic = get(binding);
            var bufferGPU:VertexBuffer3D = bindingData.bufferGPU;
            var data:ByteArray = binding.buffer;
            gl.bindBuffer(Context3D_UNIFORM_BUFFER, bufferGPU);
            gl.bufferData(Context3D_UNIFORM_BUFFER, data, Context3D_STREAM_DRAW);
        }
    }

    public function createIndexAttribute(attribute:Dynamic) {
        attributeUtils.createAttribute(attribute, Context3D_ELEMENT_ARRAY_BUFFER);
    }

    public function createAttribute(attribute:Dynamic) {
        if (has(attribute)) return;
        attributeUtils.createAttribute(attribute, Context3D_ARRAY_BUFFER);
    }

    public function createStorageAttribute(attribute:Dynamic) {
        // console.warn('Abstract class.');
    }

    public function updateAttribute(attribute:Dynamic) {
        attributeUtils.updateAttribute(attribute);
    }

    public function destroyAttribute(attribute:Dynamic) {
        attributeUtils.destroyAttribute(attribute);
    }

    public function updateSize() {
        // console.warn('Abstract class.');
    }

    public function hasFeature(name:String):Bool {
        var keysMatching:Array<String> = Lambda.array(Object.keys(GLFeatureName).filter(function(key:String) return GLFeatureName[key] == name));
        for (i in 0...keysMatching.length) {
            if (extensions.has(keysMatching[i])) return true;
        }
        return false;
    }

    public function getMaxAnisotropy():Float {
        return capabilities.getMaxAnisotropy();
    }

    public function copyTextureToTexture(position:Dynamic, srcTexture:TextureBase, dstTexture:TextureBase, level:Int) {
        textureUtils.copyTextureToTexture(position, srcTexture, dstTexture, level);
    }

    public function copyFramebufferToTexture(texture:TextureBase, renderContext:Dynamic) {
        textureUtils.copyFramebufferToTexture(texture, renderContext);
    }

    public function _setFramebuffer(renderContext:Dynamic) {
        var currentFrameBuffer:VertexBuffer3D = null;

        if (renderContext.textures != null) {
            var renderTarget:Dynamic = renderContext.renderTarget;
            var renderTargetContextData:Dynamic = get(renderTarget);
            var samples:Int = renderTarget.samples;
            var depthBuffer:Bool = renderTarget.depthBuffer;
            var stencilBuffer:Bool = renderTarget.stencilBuffer;
            var cubeFace:Int = renderer._activeCubeFace;
            var isCube:Bool = renderTarget.isWebGLCubeRenderTarget;

            var msaaFb:VertexBuffer3D;
            var depthRenderbuffer:VertexBuffer3D;

            if (isCube) {
                if (renderTargetContextData.cubeFramebuffers == null) {
                    renderTargetContextData.cubeFramebuffers = [];
                }
                var fb:VertexBuffer3D = renderTargetContextData.cubeFramebuffers[cubeFace];
            } else {
                fb = renderTargetContextData.framebuffer;
            }

            if (fb == null) {
                fb = gl.createVertexBuffer(1);
                state.bindFramebuffer(Context3D_FRAMEBUFFER, fb);

                var textures:Array<TextureBase> = renderContext.textures;

                if (isCube) {
                    renderTargetContextData.cubeFramebuffers[cubeFace] = fb;
                    var textureGPU:TextureBase = get(textures[0]).textureGPU;
                    gl.framebufferTexture2D(Context3D_FRAMEBUFFER, Context3D_COLOR_ATTACHMENT0, Context3D_TEXTURE_CUBE_MAP_POSITIVE_X + cubeFace, textureGPU, 0);
                } else {
                    for (i in 0...textures.length) {
                        var texture:TextureBase = textures[i];
                        var textureData:Dynamic = get(texture);
                        textureData.renderTarget = renderContext.renderTarget;

                        var attachment:Int = Context3D_COLOR_ATTACHMENT0 + i;

                        gl.framebufferTexture2D(Context3D_FRAMEBUFFER, attachment, Context3D_TEXTURE_2D, textureData.textureGPU, 0);
                    }

                    renderTargetContextData.framebuffer = fb;

                    state.drawBuffers(renderContext, fb);
                }

                if (renderContext.depthTexture != null) {
                    var textureData:Dynamic = get(renderContext.depthTexture);
                    var depthStyle:Int = stencilBuffer ? Context3D_DEPTH_STENCIL_ATTACHMENT : Context3D_DEPTH_ATTACHMENT;

                    gl.framebufferTexture2D(Context3D_FRAMEBUFFER, depthStyle, Context3D_TEXTURE_2D, textureData.textureGPU, 0);
                }

                if (samples > 0) {
                    if (msaaFb == null) {
                        var invalidationArray:Array<Int> = [];

                        msaaFb = gl.createVertexBuffer(1);

                        state.bindFramebuffer(Context3D_FRAMEBUFFER, msaaFb);

                        var msaaRenderbuffers:Array<VertexBuffer3D> = [];

                        for (i in 0...textures.length) {
                            msaaRenderbuffers[i] = gl.createVertexBuffer(1);
                            gl.bindRenderbuffer(Context3D_RENDERBUFFER, msaaRenderbuffers[i]);
                            invalidationArray.push(Context3D_COLOR_ATTACHMENT0 + i);

                            if (depthBuffer) {
                                var depthStyle:Int = stencilBuffer ? Context3D_DEPTH_STENCIL_ATTACHMENT : Context3D_DEPTH_ATTACHMENT;
                                invalidationArray.push(depthStyle);
                            }

                            var texture:TextureBase = textures[i];
                            var textureData:Dynamic = get(texture);

                            gl.renderbufferStorageMultisample(Context3D_RENDERBUFFER, samples, textureData.glInternalFormat, renderContext.width, renderContext.height);
                            gl.framebufferRenderbuffer(Context3D_FRAMEBUFFER, Context3D_COLOR_ATTACHMENT0 + i, Context3D_RENDERBUFFER, msaaRenderbuffers[i]);
                        }

                        renderTargetContextData.msaaFrameBuffer = msaaFb;
                        renderTargetContextData.msaaRenderbuffers = msaaRenderbuffers;

                        if (depthRenderbuffer == null) {
                            depthRenderbuffer = gl.createVertexBuffer(1);
                            textureUtils.setupRenderBufferStorage(depthRenderbuffer, renderContext);
                            renderTargetContextData.depthRenderbuffer = depthRenderbuffer;

                            var depthStyle:Int = stencilBuffer ? Context3D_DEPTH_STENCIL_ATTACHMENT : Context3D_DEPTH_ATTACHMENT;
                            invalidationArray.push(depthStyle);
                        }

                        renderTargetContextData.invalidationArray = invalidationArray;
                    }

                    currentFrameBuffer = renderTargetContextData.msaaFrameBuffer;
                } else {
                    currentFrameBuffer = fb;
                }
            }

            state.bindFramebuffer(Context3D_FRAMEBUFFER, currentFrameBuffer);
        }
    }

    public function _getVaoKey(index:Dynamic, attributes:Array<Dynamic>):String {
        var key:String = '';

        if (index != null) {
            var indexData:Dynamic = get(index);
            key += ':' + indexData.id;
        }

        for (i in 0...attributes.length) {
            var attributeData:Dynamic = get(attributes[i]);
            key += ':' + attributeData.id;
        }

        return key;
    }

    public function _createVao(index:Dynamic, attributes:Array<Dynamic>):{ vaoGPU:VertexBuffer3D, staticVao:Bool } {
        var key:String = '';

        if (index != null) {
            var indexData:Dynamic = get(index);
            key += ':' + indexData.id;
        }

        for (i in 0...attributes.length) {
            var attributeData:Dynamic = get(attributes[i]);
            key += ':' + attributeData.id;
        }

        var vaoGPU:VertexBuffer3D = gl.createVertexBuffer(1);
        var staticVao:Bool = true;

        gl.bindVertexArray(vaoGPU);

        if (index != null) {
            var indexData:Dynamic = get(index);
            gl.bindBuffer(Context3D_ELEMENT_ARRAY_BUFFER, indexData.bufferGPU);
        }

        for (i in 0...attributes.length) {
            var attribute:Dynamic = attributes[i];
            var attributeData:Dynamic = get(attribute);
            key += ':' + attributeData.id;

            gl.bindBuffer(Context3D_ARRAY_BUFFER, attributeData.bufferGPU);
            gl.enableVertexAttribArray(i);

            if (attribute.isStorageBufferAttribute || attribute.isStorageInstancedBufferAttribute) staticVao = false;

            var stride:Int = 0;
            var offset:Int = 0;

            if (attribute.isInterleavedBufferAttribute) {
                stride = attribute.data.stride * attributeData.bytesPerElement;
                offset = attribute.offset * attributeData.bytesPerElement;
            } else {
                stride = 0;
                offset = 0;
            }

            if (attributeData.isInteger) {
                gl.vertexAttribIPointer(i, attribute.itemSize, attributeData.type, stride, offset);
            } else {
                gl.vertexAttribPointer(i, attribute.itemSize, attributeData.type, attribute.normalized, stride, offset);
            }

            if (attribute.isInstancedBufferAttribute && !attribute.isInterleavedBufferAttribute) {
                gl.vertexAttribDivisor(i, attribute.meshPerAttribute);
            } else if (attribute.isInterleavedBufferAttribute && attribute.data.isInstancedInterleavedBuffer) {
                gl.vertexAttribDivisor(i, attribute.data.meshPerAttribute);
            }
        }

        gl.bindBuffer(Context3D_ARRAY_BUFFER, null);

        vaoCache[key] = vaoGPU;

        return { vaoGPU: vaoGPU, staticVao: staticVao };
    }

    public function _getTransformFeedback(transformBuffers:Array<Dynamic>):IndexBuffer3D {
        var key:String = '';

        for (i in 0...transformBuffers.length) {
            key += ':' + transformBuffers[i].id;
        }

        var transformFeedbackGPU:IndexBuffer3D = transformFeedbackCache[key];

        if (transformFeedbackGPU != null) {
            return transformFeedbackGPU;
        }

        transformFeedbackGPU = gl.createIndexBuffer(1);
        gl.bindTransformFeedback(Context3D_TRANSFORM_FEEDBACK, transformFeedbackGPU);

        for (i in 0...transformBuffers.length) {
            var attributeData:Dynamic = transformBuffers[i];
            gl.bindBufferBase(Context3D_TRANSFORM_FEEDBACK_BUFFER, i, attributeData.transformBuffer);
        }

        gl.bindTransformFeedback(Context3D_TRANSFORM_FEEDBACK, null);

        transformFeedbackCache[key] = transformFeedbackGPU;

        return transformFeedbackGPU;
    }

    public function _setupBindings(bindings:Array<Dynamic>, programGPU:Program3D) {
        for (binding in bindings) {
            var bindingData:Dynamic = get(binding);
            var index:Int = bindingData.index;

            if (binding.isUniformsGroup || binding.isUniformBuffer) {
                var location:Int = gl.getUniformBlockIndex(programGPU, binding.name);
                gl.uniformBlockBinding(programGPU, location, index);
            } else if (binding.isSampledTexture) {
                var location:Int = gl.getUniformLocation(programGPU, binding.name);
                gl.uniform1i(location, index);
            }
        }
    }

    public function _bindUniforms(bindings:Array<Dynamic>) {
        for (binding in bindings) {
            var bindingData:Dynamic = get(binding);
            var index:Int = bindingData.index;

            if (binding.isUniformsGroup || binding.isUniformBuffer) {
                gl.bindBufferBase(Context3D_UNIFORM_BUFFER, index, bindingData.bufferGPU);
            } else if (binding.isSampledTexture) {
                state.bindTexture(bindingData.glTextureType, bindingData.textureGPU, Context3D_TEXTURE0 + index);
            }
        }
    }
}