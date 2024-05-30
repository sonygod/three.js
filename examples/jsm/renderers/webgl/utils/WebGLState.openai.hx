package three.js.examples.javascript.renderers.webgl.utils;

import js.html.webgl.GL;
import js.html.webgl.RenderingContext;

class WebGLState {
    public var backend:Dynamic;
    public var gl:GL;
    public var enabled:Map<Int, Bool>;
    public var currentFlipSided:Null<Bool>;
    public var currentCullFace:Null<Int>;
    public var currentProgram:Null<GLProgram>;
    public var currentBlendingEnabled:Bool;
    public var currentBlending:Null<Int>;
    public var currentBlendSrc:Null<Int>;
    public var currentBlendDst:Null<Int>;
    public var currentBlendSrcAlpha:Null<Int>;
    public var currentBlendDstAlpha:Null<Int>;
    public var currentPremultipledAlpha:Null<Bool>;
    public var currentPolygonOffsetFactor:Null<Float>;
    public var currentPolygonOffsetUnits:Null<Float>;
    public var currentColorMask:Null<Bool>;
    public var currentDepthFunc:Null<Int>;
    public var currentDepthMask:Null<Bool>;
    public var currentStencilFunc:Null<Int>;
    public var currentStencilRef:Null<Int>;
    public var currentStencilFuncMask:Null<Int>;
    public var currentStencilFail:Null<Int>;
    public var currentStencilZFail:Null<Int>;
    public var currentStencilZPass:Null<Int>;
    public var currentStencilMask:Null<Int>;
    public var currentLineWidth:Null<Float>;
    public var currentBoundFramebuffers:Map<Int, WebGLFramebuffer>;
    public var currentDrawbuffers:Map<WebGLFramebuffer, Array<Int>>;
    public var maxTextures:Int;
    public var currentTextureSlot:Null<Int>;
    public var currentBoundTextures:Map<Int, { type:Int, texture:WebGLTexture }>;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = this.backend.gl;

        this.enabled = new Map<Int, Bool>();
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
        this.currentBoundFramebuffers = new Map<Int, WebGLFramebuffer>();
        this.currentDrawbuffers = new Map<WebGLFramebuffer, Array<Int>>();
        this.maxTextures = this.gl.getParameter(GL.MAX_TEXTURE_IMAGE_UNITS);
        this.currentTextureSlot = null;
        this.currentBoundTextures = new Map<Int, { type:Int, texture:WebGLTexture }>;

        if (!initialized) {
            _init(gl);
            initialized = true;
        }
    }

    private function _init(gl:GL):Void {
        // Store only WebGL constants here.
        equationToGL = [
            AddEquation => gl.FUNC_ADD,
            SubtractEquation => gl.FUNC_SUBTRACT,
            ReverseSubtractEquation => gl.FUNC_REVERSE_SUBTRACT
        ];

        factorToGL = [
            ZeroFactor => gl.ZERO,
            OneFactor => gl.ONE,
            SrcColorFactor => gl.SRC_COLOR,
            SrcAlphaFactor => gl.SRC_ALPHA,
            SrcAlphaSaturateFactor => gl.SRC_ALPHA_SATURATE,
            DstColorFactor => gl.DST_COLOR,
            DstAlphaFactor => gl.DST_ALPHA,
            OneMinusSrcColorFactor => gl.ONE_MINUS_SRC_COLOR,
            OneMinusSrcAlphaFactor => gl.ONE_MINUS_SRC_ALPHA,
            OneMinusDstColorFactor => gl.ONE_MINUS_DST_COLOR,
            OneMinusDstAlphaFactor => gl.ONE_MINUS_DST_ALPHA
        ];
    }

    public function enable(id:Int):Void {
        if (!enabled.exists(id)) {
            gl.enable(id);
            enabled.set(id, true);
        }
    }

    public function disable(id:Int):Void {
        if (enabled.exists(id) && enabled.get(id)) {
            gl.disable(id);
            enabled.set(id, false);
        }
    }

    public function setFlipSided(flipSided:Bool):Void {
        if (currentFlipSided != flipSided) {
            gl.frontFace(flipSided ? GL.CW : GL.CCW);
            currentFlipSided = flipSided;
        }
    }

    public function setCullFace(cullFace:Int):Void {
        if (cullFace != CullFaceNone) {
            enable(GL.CULL_FACE);
            if (cullFace != currentCullFace) {
                switch (cullFace) {
                    case CullFaceBack:
                        gl.cullFace(GL.BACK);
                    case CullFaceFront:
                        gl.cullFace(GL.FRONT);
                    default:
                        gl.cullFace(GL.FRONT_AND_BACK);
                }
            }
        } else {
            disable(GL.CULL_FACE);
        }
        currentCullFace = cullFace;
    }

    public function setLineWidth(width:Float):Void {
        if (currentLineWidth != width) {
            gl.lineWidth(width);
            currentLineWidth = width;
        }
    }

    public function setBlending(blending:Int, blendEquation:Int, blendSrc:Int, blendDst:Int, blendEquationAlpha:Int, blendSrcAlpha:Int, blendDstAlpha:Int, premultipliedAlpha:Bool):Void {
        if (blending == NoBlending) {
            if (currentBlendingEnabled) {
                disable(GL.BLEND);
                currentBlendingEnabled = false;
            }
            return;
        }

        if (!currentBlendingEnabled) {
            enable(GL.BLEND);
            currentBlendingEnabled = true;
        }

        if (blending != CustomBlending) {
            if (blending != currentBlending || premultipliedAlpha != currentPremultipledAlpha) {
                if (currentBlendEquation != AddEquation || currentBlendEquationAlpha != AddEquation) {
                    gl.blendEquation(GL.FUNC_ADD);
                    currentBlendEquation = AddEquation;
                    currentBlendEquationAlpha = AddEquation;
                }

                switch (blending) {
                    case NormalBlending:
                        gl.blendFuncSeparate(GL.ONE, GL.ONE_MINUS_SRC_ALPHA, GL.ONE, GL.ONE_MINUS_SRC_ALPHA);
                    case AdditiveBlending:
                        gl.blendFunc(GL.ONE, GL.ONE);
                    case SubtractiveBlending:
                        gl.blendFuncSeparate(GL.ZERO, GL.ONE_MINUS_SRC_COLOR, GL.ZERO, GL.ONE);
                    case MultiplyBlending:
                        gl.blendFunc(GL.ZERO, GL.SRC_COLOR);
                    default:
                        console.error('THREE.WebGLState: Invalid blending: $blending');
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

    public function setColorMask(colorMask:Bool):Void {
        if (currentColorMask != colorMask) {
            gl.colorMask(colorMask, colorMask, colorMask, colorMask);
            currentColorMask = colorMask;
        }
    }

    public function setDepthTest(depthTest:Bool):Void {
        if (depthTest) {
            enable(GL.DEPTH_TEST);
        } else {
            disable(GL.DEPTH_TEST);
        }
    }

    public function setDepthMask(depthMask:Bool):Void {
        if (currentDepthMask != depthMask) {
            gl.depthMask(depthMask);
            currentDepthMask = depthMask;
        }
    }

    public function setDepthFunc(depthFunc:Int):Void {
        if (currentDepthFunc != depthFunc) {
            switch (depthFunc) {
                case NeverDepth:
                    gl.depthFunc(GL.NEVER);
                case AlwaysDepth:
                    gl.depthFunc(GL.ALWAYS);
                case LessDepth:
                    gl.depthFunc(GL.LESS);
                case LessEqualDepth:
                    gl.depthFunc(GL.LEQUAL);
                case EqualDepth:
                    gl.depthFunc(GL.EQUAL);
                case GreaterEqualDepth:
                    gl.depthFunc(GL.GEQUAL);
                case GreaterDepth:
                    gl.depthFunc(GL.GREATER);
                case NotEqualDepth:
                    gl.depthFunc(GL.NOTEQUAL);
                default:
                    gl.depthFunc(GL.LEQUAL);
            }
            currentDepthFunc = depthFunc;
        }
    }

    public function setStencilTest(stencilTest:Bool):Void {
        if (stencilTest) {
            enable(GL.STENCIL_TEST);
        } else {
            disable(GL.STENCIL_TEST);
        }
    }

    public function setStencilMask(stencilMask:Int):Void {
        if (currentStencilMask != stencilMask) {
            gl.stencilMask(stencilMask);
            currentStencilMask = stencilMask;
        }
    }

    public function setStencilFunc(stencilFunc:Int, stencilRef:Int, stencilMask:Int):Void {
        if (currentStencilFunc != stencilFunc || currentStencilRef != stencilRef || currentStencilFuncMask != stencilMask) {
            gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
            currentStencilFunc = stencilFunc;
            currentStencilRef = stencilRef;
            currentStencilFuncMask = stencilMask;
        }
    }

    public function setStencilOp(stencilFail:Int, stencilZFail:Int, stencilZPass:Int):Void {
        if (currentStencilFail != stencilFail || currentStencilZFail != stencilZFail || currentStencilZPass != stencilZPass) {
            gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
            currentStencilFail = stencilFail;
            currentStencilZFail = stencilZFail;
            currentStencilZPass = stencilZPass;
        }
    }

    public function setMaterial(material:Dynamic, frontFaceCW:Bool):Void {
        gl = backend.gl;

        material.side == DoubleSide ? disable(GL.CULL_FACE) : enable(GL.CULL_FACE);

        let flipSided = material.side == BackSide;
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

        let stencilWrite = material.stencilWrite;
        setStencilTest(stencilWrite);
        if (stencilWrite) {
            setStencilMask(material.stencilWriteMask);
            setStencilFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
            setStencilOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
        }

        setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

        material.alphaToCoverage ? enable(GL.SAMPLE_ALPHA_TO_COVERAGE) : disable(GL.SAMPLE_ALPHA_TO_COVERAGE);
    }

    public function setPolygonOffset(polygonOffset:Bool, factor:Float, units:Float):Void {
        if (polygonOffset) {
            enable(GL.POLYGON_OFFSET_FILL);
            if (currentPolygonOffsetFactor != factor || currentPolygonOffsetUnits != units) {
                gl.polygonOffset(factor, units);
                currentPolygonOffsetFactor = factor;
                currentPolygonOffsetUnits = units;
            }
        } else {
            disable(GL.POLYGON_OFFSET_FILL);
        }
    }

    public function useProgram(program:GLProgram):Bool {
        if (currentProgram != program) {
            gl.useProgram(program);
            currentProgram = program;
            return true;
        }
        return false;
    }

    public function bindFramebuffer(target:Int, framebuffer:WebGLFramebuffer):Bool {
        if (currentBoundFramebuffers[target] != framebuffer) {
            gl.bindFramebuffer(target, framebuffer);
            currentBoundFramebuffers[target] = framebuffer;
            if (target == GL.DRAW_FRAMEBUFFER) {
                currentBoundFramebuffers[GL.FRAMEBUFFER] = framebuffer;
            }
            if (target == GL.FRAMEBUFFER) {
                currentBoundFramebuffers[GL.DRAW_FRAMEBUFFER] = framebuffer;
            }
            return true;
        }
        return false;
    }

    public function drawBuffers(renderContext:Dynamic, framebuffer:WebGLFramebuffer):Void {
        let drawBuffers = currentDrawbuffers.get(framebuffer);

        if (drawBuffers == null) {
            drawBuffers = [];
            currentDrawbuffers.set(framebuffer, drawBuffers);
        }

        let needsUpdate = false;

        if (renderContext.textures != null) {
            let textures = renderContext.textures;

            if (drawBuffers.length != textures.length || drawBuffers[0] != GL.COLOR_ATTACHMENT0) {
                for (i in 0...textures.length) {
                    drawBuffers[i] = GL.COLOR_ATTACHMENT0 + i;
                }
                drawBuffers.length = textures.length;
                needsUpdate = true;
            }
        } else {
            if (drawBuffers[0] != GL.BACK) {
                drawBuffers[0] = GL.BACK;
                needsUpdate = true;
            }
        }

        if (needsUpdate) {
            gl.drawBuffers(drawBuffers);
        }
    }

    public function activeTexture(webglSlot:Int):Void {
        if (webglSlot == null) webglSlot = GL.TEXTURE0 + maxTextures - 1;

        if (currentTextureSlot != webglSlot) {
            gl.activeTexture(webglSlot);
            currentTextureSlot = webglSlot;
        }
    }

    public function bindTexture(webglType:Int, webglTexture:WebGLTexture, webglSlot:Int):Void {
        if (webglSlot == null) {
            if (currentTextureSlot == null) {
                webglSlot = GL.TEXTURE0 + maxTextures - 1;
            } else {
                webglSlot = currentTextureSlot;
            }
        }

        let boundTexture = currentBoundTextures[webglSlot];

        if (boundTexture == null) {
            boundTexture = { type: null, texture: null };
            currentBoundTextures[webglSlot] = boundTexture;
        }

        if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
            if (currentTextureSlot != webglSlot) {
                gl.activeTexture(webglSlot);
                currentTextureSlot = webglSlot;
            }

            gl.bindTexture(webglType, webglTexture);
            boundTexture.type = webglType;
            boundTexture.texture = webglTexture;
        }
    }

    public function unbindTexture():Void {
        let boundTexture = currentBoundTextures[currentTextureSlot];

        if (boundTexture != null && boundTexture.type != null) {
            gl.bindTexture(boundTexture.type, null);
            boundTexture.type = null;
            boundTexture.texture = null;
        }
    }
}