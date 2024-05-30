import js.webgl.WebGLRenderingContext as GL;

class WebGLState {
    var backend:Dynamic;
    var gl:GL;
    var enabled:Map<Bool>;
    var currentFlipSided:Bool;
    var currentCullFace:Dynamic;
    var currentProgram:Dynamic;
    var currentBlendingEnabled:Bool;
    var currentBlending:Dynamic;
    var currentBlendSrc:Dynamic;
    var currentBlendDst:Dynamic;
    var currentBlendSrcAlpha:Dynamic;
    var currentBlendDstAlpha:Dynamic;
    var currentPremultipledAlpha:Dynamic;
    var currentPolygonOffsetFactor:Dynamic;
    var currentPolygonOffsetUnits:Dynamic;
    var currentColorMask:Dynamic;
    var currentDepthFunc:Dynamic;
    var currentDepthMask:Dynamic;
    var currentStencilFunc:Dynamic;
    var currentStencilRef:Dynamic;
    var currentStencilFuncMask:Dynamic;
    var currentStencilFail:Dynamic;
    var currentStencilZFail:Dynamic;
    var currentStencilZPass:Dynamic;
    var currentStencilMask:Dynamic;
    var currentLineWidth:Dynamic;
    var currentBoundFramebuffers:Map<Dynamic>;
    var currentDrawbuffers:WeakMap<Dynamic,Dynamic>;
    var maxTextures:Int;
    var currentTextureSlot:Dynamic;
    var currentBoundTextures:Map<Dynamic>;
    var initialized:Bool;
    var equationToGL:Map<Dynamic>;
    var factorToGL:Map<Dynamic>;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = backend.gl;
        this.enabled = Map();
        this.currentFlipSided = null;
        this.currentCullFace = null;
        this.currentProgram = null;
        this.currentBlendingEnabled = false;
        this.currentBlending = null;
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentPremultipledAlpha = null;
        this.currentPolygonOffsetFactor = null;
        this.currentPolygonOffsetUnits = null;
        this.currentColorMask = null;
        this.currentDepthFunc = null;
        this.currentDepthMask = null;
        this.currentStencilFunc = null;
        this.currentStencilRef = null;
        this.currentStencilFuncMask = null;
        this.currentStencilFail = null;
        this.currentStencilZFail = null;
        this.currentStencilZPass = null;
        this.currentStencilMask = null;
        this.currentLineWidth = null;
        this.currentBoundFramebuffers = Map();
        this.currentDrawbuffers = new WeakMap();
        this.maxTextures = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
        this.currentTextureSlot = null;
        this.currentBoundTextures = Map();
        if (!initialized) {
            _init(gl);
            initialized = true;
        }
    }

    function _init(gl:GL) {
        equationToGL = {
            AddEquation: gl.FUNC_ADD,
            SubtractEquation: gl.FUNC_SUBTRACT,
            ReverseSubtractEquation: gl.FUNC_REVERSE_SUBTRACT
        };
        factorToGL = {
            ZeroFactor: gl.ZERO,
            OneFactor: gl.ONE,
            SrcColorFactor: gl.SRC_COLOR,
            SrcAlphaFactor: gl.SRC_ALPHA,
            SrcAlphaSaturateFactor: gl.SRC_ALPHA_SATURATE,
            DstColorFactor: gl.DST_COLOR,
            DstAlphaFactor: gl.DST_ALPHA,
            OneMinusSrcColorFactor: gl.ONE_MINUS_SRC_COLOR,
            OneMinusSrcAlphaFactor: gl.ONE_MINUS_SRC_ALPHA,
            OneMinusDstColorFactor: gl.ONE_MINUS_DST_COLOR,
            OneMinusDstAlphaFactor: gl.ONE_MINUS_DST_ALPHA
        };
    }

    function enable(id:Int) {
        if (!enabled.exists(id)) {
            gl.enable(id);
            enabled[id] = true;
        }
    }

    function disable(id:Int) {
        if (enabled.exists(id)) {
            gl.disable(id);
            enabled[id] = false;
        }
    }

    function setFlipSided(flipSided:Bool) {
        if (currentFlipSided != flipSided) {
            if (flipSided) {
                gl.frontFace(gl.CW);
            } else {
                gl.frontFace(gl.CCW);
            }
            currentFlipSided = flipSided;
        }
    }

    function setCullFace(cullFace:Dynamic) {
        if (cullFace != CullFaceNone) {
            enable(gl.CULL_FACE);
            if (cullFace != currentCullFace) {
                if (cullFace == CullFaceBack) {
                    gl.cullFace(gl.BACK);
                } else if (cullFace == CullFaceFront) {
                    gl.cullFace(gl.FRONT);
                } else {
                    gl.cullFace(gl.FRONT_AND_BACK);
                }
            }
        } else {
            disable(gl.CULL_FACE);
        }
        currentCullFace = cullFace;
    }

    function setLineWidth(width:Float) {
        if (currentLineWidth != width) {
            gl.lineWidth(width);
            currentLineWidth = width;
        }
    }

    function setBlending(blending:Dynamic, blendEquation:Dynamic, blendSrc:Dynamic, blendDst:Dynamic, blendEquationAlpha:Dynamic, blendSrcAlpha:Dynamic, blendDstAlpha:Dynamic, premultipliedAlpha:Bool) {
        if (blending == NoBlending) {
            if (currentBlendingEnabled) {
                disable(gl.BLEND);
                currentBlendingEnabled = false;
            }
            return;
        }
        if (!currentBlendingEnabled) {
            enable(gl.BLEND);
            currentBlendingEnabled = true;
        }
        if (blending != CustomBlending) {
            if (blending != currentBlending || premultipliedAlpha != currentPremultipledAlpha) {
                if (currentBlendEquation != AddEquation || currentBlendEquationAlpha != AddEquation) {
                    gl.blendEquation(gl.FUNC_ADD);
                    currentBlendEquation = AddEquation;
                    currentBlendEquationAlpha = AddEquation;
                }
                if (premultipliedAlpha) {
                    switch (blending) {
                        case NormalBlending:
                            gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
                            break;
                        case AdditiveBlending:
                            gl.blendFunc(gl.ONE, gl.ONE);
                            break;
                        case SubtractiveBlending:
                            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
                            break;
                        case MultiplyBlending:
                            gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
                            break;
                        default:
                            trace("THREE.WebGLState: Invalid blending: " + blending);
                            break;
                    }
                } else {
                    switch (blending) {
                        case NormalBlending:
                            gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
                            break;
                        case AdditiveBlending:
                            gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
                            break;
                        case SubtractiveBlending:
                            gl.blendFuncSeparate(gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ZERO, gl.ONE);
                            break;
                        case MultiplyBlending:
                            gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
                            break;
                        default:
                            trace("THREE.WebGLState: Invalid blending: " + blending);
                            break;
                    }
                }
                currentBlendSrc = null;
                currentBlendDst = null;
                currentBlendSrcAlpha = null;
                currentBlendDstAlpha = null;
                currentBlending = blending;
                currentPremultipledAlpha = premultipliedAlpha;
            }
            return;
        }
        blendEquationAlpha = blendEquationAlpha || blendEquation;
        blendSrcAlpha = blendSrcAlpha || blendSrc;
        blendDstAlpha = blendDstAlpha || blendDst;
        if (blendEquation != currentBlendEquation || blendEquationAlpha != currentBlendEquationAlpha) {
            gl.blendEquationSeparate(equationToGL[blendEquation], equationToGL[blendEquationAlpha]);
            currentBlendEquation = blendEquation;
            currentBlendEquationAlpha = blendEquationAlpha;
        }
        if (blendSrc != currentBlendSrc || blendDst != currentBlendDst || blendSrcAlpha != currentBlendSrcAlpha || blendDstAlpha != currentBlendDstAlpha) {
            gl.blendFuncSeparate(factorToGL[blendSrc], factorToGL[blendDst], factorToGL[blendSrcAlpha], factorToGL[blendDstAlpha]);
            currentBlendSrc = blendSrc;
            currentBlendDst = blendDst;
            currentBlendSrcAlpha = blendSrcAlpha;
            currentBlendDstAlpha = blendDstAlpha;
        }
        currentBlending = blending;
        currentPremultipledAlpha = false;
    }

    function setColorMask(colorMask:Bool) {
        if (currentColorMask != colorMask) {
            gl.colorMask(colorMask, colorMask, colorMask, colorMask);
            currentColorMask = colorMask;
        }
    }

    function setDepthTest(depthTest:Bool) {
        if (depthTest) {
            enable(gl.DEPTH_TEST);
        } else {
            disable(gl.DEPTH_TEST);
        }
    }

    function setDepthMask(depthMask:Bool) {
        if (currentDepthMask != depthMask) {
            gl.depthMask(depthMask);
            currentDepthMask = depthMask;
        }
    }

    function setDepthFunc(depthFunc:Dynamic) {
        if (currentDepthFunc != depthFunc) {
            switch (depthFunc) {
                case NeverDepth:
                    gl.depthFunc(gl.NEVER);
                    break;
                case AlwaysDepth:
                    gl.depthFunc(gl.ALWAYS);
                    break;
                case LessDepth:
                    gl.depthFunc(gl.LESS);
                    break;
                case LessEqualDepth:
                    gl.depthFunc(gl.LEQUAL);
                    break;
                case EqualDepth:
                    gl.depthFunc(gl.EQUAL);
                    break;
                case GreaterEqualDepth:
                    gl.depthFunc(gl.GEQUAL);
                    break;
                case GreaterDepth:
                    gl.depthFunc(gl.GREATER);
                    break;
                case NotEqualDepth:
                    gl.depthFunc(gl.NOTEQUAL);
                    break;
                default:
                    gl.depthFunc(gl.LEQUAL);
            }
            currentDepthFunc = depthFunc;
        }
    }

    function setStencilTest(stencilTest:Bool) {
        if (stencilTest) {
            enable(gl.STENCIL_TEST);
        } else {
            disable(gl.STENCIL_TEST);
        }
    }

    function setStencilMask(stencilMask:Int) {
        if (currentStencilMask != stencilMask) {
            gl.stencilMask(stencilMask);
            currentStencilMask = stencilMask;
        }
    }

    function setStencilFunc(stencilFunc:Int, stencilRef:Int, stencilMask:Int) {
        if (currentStencilFunc != stencilFunc || currentStencilRef != stencilRef || currentStencilFuncMask != stencilMask) {
            gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
            currentStencilFunc = stencilFunc;
            currentStencilRef = stencilRef;
            currentStencilFuncMask = stencilMask;
        }
    }

    function setStencilOp(stencilFail:Int, stencilZFail:Int, stencilZPass:Int) {
        if (currentStencilFail != stencilFail || currentStencilZFail != stencilZFail || currentStencilZPass != stencilZPass) {
            gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
            currentStencilFail = stencilFail;
            currentStencilZFail = stencilZFail;
            currentStencilZPass = stencilZPass;
        }
    }

    function setMaterial(material:Dynamic, frontFaceCW:Bool) {
        if (material.side == DoubleSide) {
            disable(gl.CULL_FACE);
        } else {
            enable(gl.CULL_FACE);
        }
        var flipSided = (material.side == BackSide);
        if (frontFaceCW) flipSided = !flipSided;
        setFlipSided(flipSided);
        if (material.blending == NormalBlending && !material.transparent) {
            setBlending(NoBlending);
        } else {
            setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.premultipliedAlpha);
        }
        setDepthFunc(material.depthFunc);
        setDepthTest(material.depthTest);
        setDepthMask(material.depthWrite);
        setColorMask(material.colorWrite);
        var stencilWrite = material.stencilWrite;
        setStencilTest(stencilWrite);
        if (stencilWrite) {
            setStencilMask(material.stencilWriteMask);
            setStencilFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
            setStencilOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
        }
        setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
        if (material.alphaToCoverage) {
            enable(gl.SAMPLE_ALPHA_TO_COVERAGE);
        } else {
            disable(gl.SAMPLE_ALPHA_TO_COVERAGE);
        }
    }

    function setPolygonOffset(polygonOffset:Bool, factor:Float, units:Float) {
        if (polygonOffset) {
            enable(gl.POLYGON_OFFSET_FILL);
            if (currentPolygonOffsetFactor != factor || currentPolygonOffsetUnits != units) {
                gl.polygonOffset(factor, units);
                currentPolygonOffsetFactor = factor;
                currentPolygonOffsetUnits = units;
            }
        } else {
            disable(gl.POLYGON_OFFSET_FILL);
        }
    }

    function useProgram(program:Dynamic) {
        if (currentProgram != program) {
            gl.useProgram(program);
            currentProgram = program;
            return true;
        }
        return false;
    }

    function bindFramebuffer(target:Int, framebuffer:Dynamic) {
        if (currentBoundFramebuffers[target] != framebuffer) {
            gl.bindFramebuffer(target, framebuffer);
            currentBoundFramebuffers[target] = framebuffer;
            if (target == gl.DRAW_FRAMEBUFFER) {
                currentBoundFramebuffers[gl.FRAMEBUFFER] = framebuffer;
            }
            if (target == gl.FRAMEBUFFER) {
                currentBoundFramebuffers[gl.DRAW_FRAMEBUFFER] = framebuffer;
            }
            return true;
        }
        return false;
    }

    function drawBuffers(renderContext:Dynamic, framebuffer:Dynamic) {
        var drawBuffers = [];
        var needsUpdate = false;
        if (renderContext.textures != null) {
            drawBuffers = currentDrawbuffers.get(framebuffer);
            if (drawBuffers == null) {
                drawBuffers = [];
                currentDrawbuffers.set(framebuffer, drawBuffers);
            }
            var textures = renderContext.textures;
            if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
                for (i in 0...textures.length) {
                    drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
                }
                drawBuffers.length = textures.length;
                needsUpdate = true;
            }
        } else {
            if (drawBuffers[0] != gl.BACK) {
                drawBuffers[0] = gl.BACK;
                needsUpdate = true;
            }
        }
        if (needsUpdate) {
            gl.drawBuffers(drawBuffers);
        }
    }

    function activeTexture(webglSlot:Int) {
        if (currentTextureSlot == null) {
            webglSlot = gl.TEXTURE0 + maxTextures - 1;
        } else {
            webglSlot = currentTextureSlot;
        }
        if (currentTextureSlot != webglSlot) {
            gl.activeTexture(webglSlot);
            currentTextureSlot = webglSlot;
        }
    }

    function bindTexture(webglType:Int, webglTexture:Dynamic, webglSlot:Int) {
        if (currentTextureSlot == null) {
            webglSlot = gl.TEXTURE0 + maxTextures - 1;
        } else {
            webglSlot = currentTextureSlot;
        }
        var boundTexture = currentBoundTextures[webglSlot];
        if (boundTexture == null || boundTexture.type != webglType || boundTexture.texture != webglTexture) {
            if (currentTextureSlot != webglSlot) {
                gl.activeTexture(webglSlot);
                currentTextureSlot = webglSlot;
            }
            gl.bindTexture(webglType, webglTexture);
            boundTexture = { type: webglType, texture: webglTexture };
            currentBoundTextures[webglSlot] = boundTexture;
        }
    }

    function unbindTexture() {
        var boundTexture = currentBoundTextures[currentTextureSlot];
        if (boundTexture != null && boundTexture.type != null) {
            gl.bindTexture(boundTexture.type, null);
            boundTexture.type = null;
            boundTexture.texture = null;
        }
    }
}