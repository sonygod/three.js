import three.constants.*;
import three.math.Color;
import three.math.Vector4;

class WebGLState {
    var gl:GLRenderContext;

    public function new(gl:GLRenderContext) {
        this.gl = gl;
        colorBuffer.setClear(0, 0, 0, 1);
        depthBuffer.setClear(1);
        stencilBuffer.setClear(0);

        enable(gl.DEPTH_TEST);
        depthBuffer.setFunc(LessEqualDepth);

        setFlipSided(false);
        setCullFace(CullFaceBack);
        enable(gl.CULL_FACE);

        setBlending(NoBlending);
    }

    private function ColorBuffer() {
        var locked = false;
        var color = new Vector4();
        var currentColorMask:Bool = null;
        var currentColorClear = new Vector4(0, 0, 0, 0);

        return {
            setMask: function(colorMask:Bool) {
                if (currentColorMask != colorMask && !locked) {
                    gl.colorMask(colorMask, colorMask, colorMask, colorMask);
                    currentColorMask = colorMask;
                }
            },
            setLocked: function(lock:Bool) {
                locked = lock;
            },
            setClear: function(r:Float, g:Float, b:Float, a:Float, premultipliedAlpha:Bool) {
                if (premultipliedAlpha) {
                    r *= a;
                    g *= a;
                    b *= a;
                }
                color.set(r, g, b, a);
                if (!currentColorClear.equals(color)) {
                    gl.clearColor(r, g, b, a);
                    currentColorClear.copy(color);
                }
            },
            reset: function() {
                locked = false;
                currentColorMask = null;
                currentColorClear.set(-1, 0, 0, 0);
            }
        };
    }

    private function DepthBuffer() {
        var locked = false;
        var currentDepthMask:Bool = null;
        var currentDepthFunc:Int = null;
        var currentDepthClear:Float = null;

        return {
            setTest: function(depthTest:Bool) {
                if (depthTest) {
                    enable(gl.DEPTH_TEST);
                } else {
                    disable(gl.DEPTH_TEST);
                }
            },
            setMask: function(depthMask:Bool) {
                if (currentDepthMask != depthMask && !locked) {
                    gl.depthMask(depthMask);
                    currentDepthMask = depthMask;
                }
            },
            setFunc: function(depthFunc:Int) {
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
            },
            setLocked: function(lock:Bool) {
                locked = lock;
            },
            setClear: function(depth:Float) {
                if (currentDepthClear != depth) {
                    gl.clearDepth(depth);
                    currentDepthClear = depth;
                }
            },
            reset: function() {
                locked = false;
                currentDepthMask = null;
                currentDepthFunc = null;
                currentDepthClear = null;
            }
        };
    }

    private function StencilBuffer() {
        var locked = false;
        var currentStencilMask:Int = null;
        var currentStencilFunc:Int = null;
        var currentStencilRef:Int = null;
        var currentStencilFuncMask:Int = null;
        var currentStencilFail:Int = null;
        var currentStencilZFail:Int = null;
        var currentStencilZPass:Int = null;
        var currentStencilClear:Int = null;

        return {
            setTest: function(stencilTest:Bool) {
                if (!locked) {
                    if (stencilTest) {
                        enable(gl.STENCIL_TEST);
                    } else {
                        disable(gl.STENCIL_TEST);
                    }
                }
            },
            setMask: function(stencilMask:Int) {
                if (currentStencilMask != stencilMask && !locked) {
                    gl.stencilMask(stencilMask);
                    currentStencilMask = stencilMask;
                }
            },
            setFunc: function(stencilFunc:Int, stencilRef:Int, stencilMask:Int) {
                if (currentStencilFunc != stencilFunc ||
                    currentStencilRef != stencilRef ||
                    currentStencilFuncMask != stencilMask) {
                    gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
                    currentStencilFunc = stencilFunc;
                    currentStencilRef = stencilRef;
                    currentStencilFuncMask = stencilMask;
                }
            },
            setOp: function(stencilFail:Int, stencilZFail:Int, stencilZPass:Int) {
                if (currentStencilFail != stencilFail ||
                    currentStencilZFail != stencilZFail ||
                    currentStencilZPass != stencilZPass) {
                    gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
                    currentStencilFail = stencilFail;
                    currentStencilZFail = stencilZFail;
                    currentStencilZPass = stencilZPass;
                }
            },
            setLocked: function(lock:Bool) {
                locked = lock;
            },
            setClear: function(stencil:Int) {
                if (currentStencilClear != stencil) {
                    gl.clearStencil(stencil);
                    currentStencilClear = stencil;
                }
            },
            reset: function() {
                locked = false;
                currentStencilMask = null;
                currentStencilFunc = null;
                currentStencilRef = null;
                currentStencilFuncMask = null;
                currentStencilFail = null;
                currentStencilZFail = null;
                currentStencilZPass = null;
                currentStencilClear = null;
            }
        };
    }

    // State variables and initialization
    private var colorBuffer = ColorBuffer();
    private var depthBuffer = DepthBuffer();
    private var stencilBuffer = StencilBuffer();

    private var uboBindings = new WeakMap();
    private var uboProgramMap = new WeakMap();

    private var enabledCapabilities = new Map<Int, Bool>();

    private var currentBoundFramebuffers = new Map<Int, Dynamic>();
    private var currentDrawbuffers = new WeakMap();
    private var defaultDrawbuffers = [];

    private var currentProgram:Dynamic = null;

    private var currentBlendingEnabled = false;
    private var currentBlending:Int = null;
    private var currentBlendEquation:Int = null;
    private var currentBlendSrc:Int = null;
    private var currentBlendDst:Int = null;
    private var currentBlendEquationAlpha:Int = null;
    private var currentBlendSrcAlpha:Int = null;
    private var currentBlendDstAlpha:Int = null;
    private var currentBlendColor = new Color(0, 0, 0);
    private var currentBlendAlpha:Float = 0;
    private var currentPremultipledAlpha = false;

    private var currentFlipSided:Bool = null;
    private var currentCullFace:Int = null;

    private var currentLineWidth:Float = null;

    private var currentPolygonOffsetFactor:Float = null;
    private var currentPolygonOffsetUnits:Float = null;

    private var maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

    private var lineWidthAvailable = false;
    private var version:Float = 0;
    private var glVersion = gl.getParameter(gl.VERSION);

    if (glVersion.indexOf('WebGL') != -1) {
        version = Std.parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
        lineWidthAvailable = version >= 1.0;
    } else if (glVersion.indexOf('OpenGL ES') != -1) {
        version = Std.parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
        lineWidthAvailable = version >= 2.0;
    }

    private var currentTextureSlot:Int = null;
    private var currentBoundTextures = new Map<Int, Dynamic>();

    private var scissorParam = gl.getParameter(gl.SCISSOR_BOX);
    private var viewportParam = gl.getParameter(gl.VIEWPORT);

    private var currentScissor = new Vector4().fromArray(scissorParam);
    private var currentViewport = new Vector4().fromArray(viewportParam);

    private function createTexture(type:Int, target:Int, count:Int, dimensions:Int = 1) {
        var data = new Uint8Array(4);
        var texture = gl.createTexture();

        gl.bindTexture(type, texture);
        gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        for (i in 0...count) {
            if (type == gl.TEXTURE_3D || type == gl.TEXTURE_2D_ARRAY) {
                gl.texImage3D(target, 0, gl.RGBA, 1, 1, dimensions, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
            } else {
                gl.texImage2D(target + i, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
            }
        }

        return texture;
    }

    private var emptyTextures = [
        createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, maxTextures),
        createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP_POSITIVE_X, maxTextures),
        createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, maxTextures),
        createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, maxTextures)
    ];

    function enable(id:Int) {
        if (!enabledCapabilities.exists(id)) {
            gl.enable(id);
            enabledCapabilities.set(id, true);
        }
    }

    function disable(id:Int) {
        if (enabledCapabilities.exists(id)) {
            gl.disable(id);
            enabledCapabilities.remove(id);
        }
    }

    function bindFramebuffer(target:Int, framebuffer:Dynamic) {
        if (currentBoundFramebuffers.get(target) != framebuffer) {
            gl.bindFramebuffer(target, framebuffer);
            currentBoundFramebuffers.set(target, framebuffer);
        }
    }

    function bindDrawBuffers(framebuffer:Dynamic, drawBuffers:Array<Int>) {
        if (currentDrawbuffers.get(framebuffer) == null) {
            currentDrawbuffers.set(framebuffer, []);
        }

        var cachedDrawBuffers = currentDrawbuffers.get(framebuffer);
        var buffersChanged = false;

        if (cachedDrawBuffers.length != drawBuffers.length) {
            buffersChanged = true;
        } else {
            for (i in 0...drawBuffers.length) {
                if (drawBuffers[i] != cachedDrawBuffers[i]) {
                    buffersChanged = true;
                    break;
                }
            }
        }

        if (buffersChanged) {
            if (drawBuffers.length != 0) {
                gl.drawBuffers(drawBuffers);
            } else {
                gl.drawBuffers(defaultDrawbuffers);
            }
            currentDrawbuffers.set(framebuffer, drawBuffers.copy());
        }
    }

    function useProgram(program:Dynamic) {
        if (currentProgram != program) {
            gl.useProgram(program);
            currentProgram = program;
        }
    }

    function setBlending(blending:Int, blendEquation:Int = null, blendSrc:Int = null, blendDst:Int = null, blendEquationAlpha:Int = null, blendSrcAlpha:Int = null, blendDstAlpha:Int = null, blendColor:Color = null, premultipliedAlpha:Bool = false) {
        if (blending == NoBlending) {
            if (currentBlendingEnabled) {
                disable(gl.BLEND);
                currentBlendingEnabled = false;
            }
        } else {
            if (!currentBlendingEnabled) {
                enable(gl.BLEND);
                currentBlendingEnabled = true;
            }

            if (blending != CustomBlending) {
                if (blending != currentBlending || premultipliedAlpha != currentPremultipledAlpha) {
                    if (currentBlending == null) {
                        gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
                    }

                    switch (blending) {
                        case AdditiveBlending:
                            if (premultipliedAlpha) {
                                gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
                                gl.blendFuncSeparate(gl.ONE, gl.ONE, gl.ONE, gl.ONE);
                            } else {
                                gl.blendEquation(gl.FUNC_ADD);
                                gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
                            }
                            break;
                        case SubtractiveBlending:
                            if (premultipliedAlpha) {
                                gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
                                gl.blendFuncSeparate(gl.ZERO, gl.ZERO, gl.ONE_MINUS_SRC_COLOR, gl.ONE_MINUS_SRC_ALPHA);
                            } else {
                                gl.blendEquation(gl.FUNC_ADD);
                                gl.blendFunc(gl.ZERO, gl.ONE_MINUS_SRC_COLOR);
                            }
                            break;
                        case MultiplyBlending:
                            if (premultipliedAlpha) {
                                gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
                                gl.blendFuncSeparate(gl.ZERO, gl.SRC_COLOR, gl.ZERO, gl.SRC_ALPHA);
                            } else {
                                gl.blendEquation(gl.FUNC_ADD);
                                gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
                            }
                            break;
                        default:
                            if (premultipliedAlpha) {
                                gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
                                gl.blendFuncSeparate(gl.ONE, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
                            } else {
                                gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
                                gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
                            }
                    }

                    currentBlendEquation = null;
                    currentBlendSrc = null;
                    currentBlendDst = null;
                    currentBlendEquationAlpha = null;
                    currentBlendSrcAlpha = null;
                    currentBlendDstAlpha = null;
                }

                currentBlendColor.copy(new Color(0, 0, 0));
                currentBlendAlpha = 0;
            } else {
                blendEquationAlpha ??= blendEquation;
                blendSrcAlpha ??= blendSrc;
                blendDstAlpha ??= blendDst;

                if (blendEquation != currentBlendEquation || blendEquationAlpha != currentBlendEquationAlpha) {
                    gl.blendEquationSeparate(blendEquation, blendEquationAlpha);
                    currentBlendEquation = blendEquation;
                    currentBlendEquationAlpha = blendEquationAlpha;
                }

                if (blendSrc != currentBlendSrc || blendDst != currentBlendDst || blendSrcAlpha != currentBlendSrcAlpha || blendDstAlpha != currentBlendDstAlpha) {
                    gl.blendFuncSeparate(blendSrc, blendDst, blendSrcAlpha, blendDstAlpha);
                    currentBlendSrc = blendSrc;
                    currentBlendDst = blendDst;
                    currentBlendSrcAlpha = blendSrcAlpha;
                    currentBlendDstAlpha = blendDstAlpha;
                }

                if (currentBlendColor == null) {
                    currentBlendColor = new Color(0, 0, 0);
                }

                if (blendColor != currentBlendColor || currentBlendAlpha != blendColor.a) {
                    gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendColor.a);
                    currentBlendColor.copy(blendColor);
                    currentBlendAlpha = blendColor.a;
                }
            }

            currentBlending = blending;
            currentPremultipledAlpha = premultipliedAlpha;
        }
    }

    function setMaterial(material:Material, frontFaceCW:Bool) {
        material.side == FrontSide ? setFlipSided(false) : setFlipSided(true);

        var flipSided = (material.side == BackSide) && frontFaceCW || (material.side == FrontSide) && !frontFaceCW;

        setCullFace(flipSided ? CullFaceFront : CullFaceBack);

        setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.color, material.premultipliedAlpha);

        setMaterialProperties(material);
    }

    function setFlipSided(flipSided:Bool) {
        if (currentFlipSided != flipSided) {
            gl.frontFace(flipSided ? gl.CW : gl.CCW);
            currentFlipSided = flipSided;
        }
    }

    function setCullFace(cullFace:Int) {
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

    function reset() {
        for (id in enabledCapabilities.keys()) {
            if (enabledCapabilities.exists(id)) {
                gl.disable(id);
            }
        }

        enabledCapabilities = new Map<Int, Bool>();

        colorBuffer.reset();
        depthBuffer.reset();
        stencilBuffer.reset();

        currentProgram = null;

        currentBlendingEnabled = false;
        currentBlending = null;
        currentBlendEquation = null;
        currentBlendSrc = null;
        currentBlendDst = null;
        currentBlendEquationAlpha = null;
        currentBlendSrcAlpha = null;
        currentBlendDstAlpha = null;
        currentBlendColor = new Color(0, 0, 0);
        currentBlendAlpha = 0;
        currentPremultipledAlpha = false;

        currentFlipSided = null;
        currentCullFace = null;

        currentLineWidth = null;

        currentPolygonOffsetFactor = null;
        currentPolygonOffsetUnits = null;

        currentTextureSlot = null;
        currentBoundTextures = new Map<Int, Dynamic>();

        scissorParam = gl.getParameter(gl.SCISSOR_BOX);
        viewportParam = gl.getParameter(gl.VIEWPORT);

        currentScissor = new Vector4().fromArray(scissorParam);
        currentViewport = new Vector4().fromArray(viewportParam);
    }

    function setMaterialProperties(material:Material) {
        var side = material.side;
        var frontFaceCW = material.side == FrontSide;
        setMaterial(material, frontFaceCW);
    }
}