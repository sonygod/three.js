import three.js.src.constants.*;
import three.js.src.math.Color;
import three.js.src.math.Vector4;

class WebGLState {

    private var colorBuffer:ColorBuffer;
    private var depthBuffer:DepthBuffer;
    private var stencilBuffer:StencilBuffer;

    private var uboBindings:WeakMap<Dynamic, Int>;
    private var uboProgramMap:WeakMap<Dynamic, WeakMap<Dynamic, Int>>;

    private var enabledCapabilities:Map<Int, Bool>;

    private var currentBoundFramebuffers:Map<Int, Dynamic>;
    private var currentDrawbuffers:WeakMap<Dynamic, Array<Int>>;
    private var defaultDrawbuffers:Array<Int>;

    private var currentProgram:Dynamic;

    private var currentBlendingEnabled:Bool;
    private var currentBlending:Dynamic;
    private var currentBlendEquation:Dynamic;
    private var currentBlendSrc:Dynamic;
    private var currentBlendDst:Dynamic;
    private var currentBlendEquationAlpha:Dynamic;
    private var currentBlendSrcAlpha:Dynamic;
    private var currentBlendDstAlpha:Dynamic;
    private var currentBlendColor:Color;
    private var currentBlendAlpha:Float;
    private var currentPremultipledAlpha:Bool;

    private var currentFlipSided:Dynamic;
    private var currentCullFace:Dynamic;

    private var currentLineWidth:Dynamic;

    private var currentPolygonOffsetFactor:Dynamic;
    private var currentPolygonOffsetUnits:Dynamic;

    private var maxTextures:Int;

    private var lineWidthAvailable:Bool;
    private var version:Float;
    private var glVersion:String;

    private var currentTextureSlot:Dynamic;
    private var currentBoundTextures:Map<Int, Dynamic>;

    private var currentScissor:Vector4;
    private var currentViewport:Vector4;

    public function new(gl:WebGLRenderingContext) {

        colorBuffer = new ColorBuffer();
        depthBuffer = new DepthBuffer();
        stencilBuffer = new StencilBuffer();

        uboBindings = new WeakMap();
        uboProgramMap = new WeakMap();

        enabledCapabilities = {};

        currentBoundFramebuffers = {};
        currentDrawbuffers = new WeakMap();
        defaultDrawbuffers = [];

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

        maxTextures = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

        lineWidthAvailable = false;
        version = 0;
        glVersion = gl.getParameter(gl.VERSION);

        if (glVersion.indexOf("WebGL") != -1) {

            version = parseFloat(/^WebGL (\d)/.exec(glVersion)[1]);
            lineWidthAvailable = (version >= 1.0);

        } else if (glVersion.indexOf("OpenGL ES") != -1) {

            version = parseFloat(/^OpenGL ES (\d)/.exec(glVersion)[1]);
            lineWidthAvailable = (version >= 2.0);

        }

        currentTextureSlot = null;
        currentBoundTextures = {};

        currentScissor = new Vector4().fromArray(gl.getParameter(gl.SCISSOR_BOX));
        currentViewport = new Vector4().fromArray(gl.getParameter(gl.VIEWPORT));

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

    private function enable(id:Int):Void {

        if (enabledCapabilities[id] != true) {

            gl.enable(id);
            enabledCapabilities[id] = true;

        }

    }

    private function disable(id:Int):Void {

        if (enabledCapabilities[id] != false) {

            gl.disable(id);
            enabledCapabilities[id] = false;

        }

    }

    private function bindFramebuffer(target:Int, framebuffer:Dynamic):Bool {

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

    private function drawBuffers(renderTarget:Dynamic, framebuffer:Dynamic):Void {

        var drawBuffers:Array<Int> = defaultDrawbuffers;

        var needsUpdate:Bool = false;

        if (renderTarget) {

            drawBuffers = currentDrawbuffers.get(framebuffer);

            if (drawBuffers == null) {

                drawBuffers = [];
                currentDrawbuffers.set(framebuffer, drawBuffers);

            }

            var textures:Array<Dynamic> = renderTarget.textures;

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

    private function useProgram(program:Dynamic):Bool {

        if (currentProgram != program) {

            gl.useProgram(program);

            currentProgram = program;

            return true;

        }

        return false;

    }

    private function setBlending(blending:Dynamic, blendEquation:Dynamic = null, blendSrc:Dynamic = null, blendDst:Dynamic = null, blendEquationAlpha:Dynamic = null, blendSrcAlpha:Dynamic = null, blendDstAlpha:Dynamic = null, blendColor:Color = null, blendAlpha:Float = null, premultipliedAlpha:Bool = null):Void {

        if (blending == NoBlending) {

            if (currentBlendingEnabled == true) {

                disable(gl.BLEND);
                currentBlendingEnabled = false;

            }

            return;

        }

        if (currentBlendingEnabled == false) {

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
                            gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
                            break;

                        case AdditiveBlending:
                            gl.blendFunc(gl.ONE, gl.ONE);
                            break;

                        case SubtractiveBlending:
                            gl.blendFunc(gl.ZERO, gl.ONE_MINUS_SRC_COLOR);
                            break;

                        case MultiplyBlending:
                            gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
                            break;

                        default:
                            trace("THREE.WebGLState: Invalid blending: " + blending);
                            break;

                    }

                } else {

                    switch (blending) {

                        case NormalBlending:
                            gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                            break;

                        case AdditiveBlending:
                            gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
                            break;

                        case SubtractiveBlending:
                            gl.blendFunc(gl.ZERO, gl.ONE_MINUS_SRC_COLOR);
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
                currentBlendColor.set(0, 0, 0);
                currentBlendAlpha = 0;

                currentBlending = blending;
                currentPremultipledAlpha = premultipliedAlpha;

            }

            return;

        }

        // custom blending

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

        if (blendColor.equals(currentBlendColor) == false || blendAlpha != currentBlendAlpha) {

            gl.blendColor(blendColor.r, blendColor.g, blendColor.b, blendAlpha);

            currentBlendColor.copy(blendColor);
            currentBlendAlpha = blendAlpha;

        }

        currentBlending = blending;
        currentPremultipledAlpha = false;

    }

    private function setMaterial(material:Dynamic, frontFaceCW:Bool):Void {

        material.side == DoubleSide
            ? disable(gl.CULL_FACE)
            : enable(gl.CULL_FACE);

        var flipSided:Bool = (material.side == BackSide);
        if (frontFaceCW) flipSided = !flipSided;

        setFlipSided(flipSided);

        (material.blending == NormalBlending && material.transparent == false)
            ? setBlending(NoBlending)
            : setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);

        depthBuffer.setFunc(material.depthFunc);
        depthBuffer.setTest(material.depthTest);
        depthBuffer.setMask(material.depthWrite);
        colorBuffer.setMask(material.colorWrite);

        var stencilWrite:Bool = material.stencilWrite;
        stencilBuffer.setTest(stencilWrite);
        if (stencilWrite) {

            stencilBuffer.setMask(material.stencilWriteMask);
            stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
            stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);

        }

        setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

        material.alphaToCoverage == true
            ? enable(gl.SAMPLE_ALPHA_TO_COVERAGE)
            : disable(gl.SAMPLE_ALPHA_TO_COVERAGE);

    }

    // ... rest of the code ...

}