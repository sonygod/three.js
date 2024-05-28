import js.WebGLRenderingContext;
import js.WebGLTexture;
import js.WebGLFramebuffer;
import js.WebGLProgram;
import js.WebGLActiveInfo;
import js.WebGLShader;
import js.WebGLBuffer;

import js.ArrayBuffer;
import js.Float32Array;
import js.Int16Array;
import js.Int32Array;
import js.Int8Array;
import js.Uint16Array;
import js.Uint32Array;
import js.Uint8Array;
import js.Uint8ClampedArray;

import js.DataView;

class WebGLState {
    var gl:WebGLRenderingContext;
    var colorBuffer:ColorBuffer;
    var depthBuffer:DepthBuffer;
    var stencilBuffer:StencilBuffer;
    var uboBindings:Map<WebGLProgram,Int>;
    var uboProgramMap:Map<WebGLProgram,Map<Dynamic,Int>>;
    var enabledCapabilities:Map<Int,Bool>;
    var currentBoundFramebuffers:Map<Int,WebGLFramebuffer>;
    var currentDrawbuffers:Map<WebGLFramebuffer,Array<Int>>;
    var defaultDrawbuffers:Array<Int>;
    var currentProgram:WebGLProgram;
    var currentBlendingEnabled:Bool;
    var currentBlending:Int;
    var currentBlendEquation:Int;
    var currentBlendSrc:Int;
    var currentBlendDst:Int;
    var currentBlendEquationAlpha:Int;
    var currentBlendSrcAlpha:Int;
    var currentBlendDstAlpha:Int;
    var currentBlendColor:Float;
    var currentBlendAlpha:Float;
    var currentPremultipledAlpha:Bool;
    var currentFlipSided:Bool;
    var currentCullFace:Int;
    var currentLineWidth:Float;
    var currentPolygonOffsetFactor:Float;
    var currentPolygonOffsetUnits:Float;
    var maxTextures:Int;
    var lineWidthAvailable:Bool;
    var version:Float;
    var currentTextureSlot:Int;
    var currentBoundTextures:Map<Int,TextureInfo>;
    var currentScissor:Float;
    var currentViewport:Float;

    function new() {
        enabledCapabilities = new Map();
        currentBoundFramebuffers = new Map();
        currentDrawbuffers = new Map();
        defaultDrawbuffers = [];
        currentProgram = null;
        currentBlendingEnabled = false;
        currentBlending = 0;
        currentBlendEquation = 0;
        currentBlendSrc = 0;
        currentBlendDst = 0;
        currentBlendEquationAlpha = 0;
        currentBlendSrcAlpha = 0;
        currentBlendDstAlpha = 0;
        currentBlendColor = 0;
        currentBlendAlpha = 0;
        currentPremultipledAlpha = false;
        currentFlipSided = false;
        currentCullFace = 0;
        currentLineWidth = 0;
        currentPolygonOffsetFactor = 0;
        currentPolygonOffsetUnits = 0;
        currentTextureSlot = 0;
        currentBoundTextures = new Map();
        currentScissor = 0;
        currentViewport = 0;
        colorBuffer = new ColorBuffer();
        depthBuffer = new DepthBuffer();
        stencilBuffer = new StencilBuffer();
        uboBindings = new Map();
        uboProgramMap = new Map();
    }

    function enable(id:Int) {
        if (enabledCapabilities.get(id) != true) {
            gl.enable(id);
            enabledCapabilities.set(id, true);
        }
    }

    function disable(id:Int) {
        if (enabledCapabilities.get(id) != false) {
            gl.disable(id);
            enabledCapabilities.set(id, false);
        }
    }

    function bindFramebuffer(target:Int, framebuffer:WebGLFramebuffer) {
        if (currentBoundFramebuffers.get(target) != framebuffer) {
            gl.bindFramebuffer(target, framebuffer);
            currentBoundFramebuffers.set(target, framebuffer);
            currentBoundFramebuffers.set(WebGLRenderingContext.FRAMEBUFFER, framebuffer);
            currentBoundFramebuffers.set(WebGLRenderingContext.DRAW_FRAMEBUFFER, framebuffer);
            return true;
        }
        return false;
    }

    function drawBuffers(renderTarget:Dynamic, framebuffer:WebGLFramebuffer) {
        var drawBuffers = defaultDrawbuffers;
        var needsUpdate = false;
        if (renderTarget != null) {
            drawBuffers = currentDrawbuffers.get(framebuffer);
            if (drawBuffers == null) {
                drawBuffers = [];
                currentDrawbuffers.set(framebuffer, drawBuffers);
            }
            var textures = renderTarget.textures;
            if (drawBuffers.length != textures.length || drawBuffers[0] != WebGLRenderingContext.COLOR_ATTACHMENT0) {
                for (i in 0...textures.length) {
                    drawBuffers[i] = WebGLRenderingContext.COLOR_ATTACHMENT0 + i;
                }
                drawBuffers.length = textures.length;
                needsUpdate = true;
            }
        } else {
            if (drawBuffers[0] != WebGLRenderingContext.BACK) {
                drawBuffers[0] = WebGLRenderingContext.BACK;
                needsUpdate = true;
            }
        }
        if (needsUpdate) {
            gl.drawBuffers(drawBuffers);
        }
    }

    function useProgram(program:WebGLProgram) {
        if (currentProgram != program) {
            gl.useProgram(program);
            currentProgram = program;
            return true;
        }
        return false;
    }

    static var equationToGL:Map<Int,Int>;
    static var factorToGL:Map<Int,Int>;

    function setBlending(blending:Int, blendEquation:Int, blendSrc:Int, blendDst:Int, blendEquationAlpha:Int, blendSrcAlpha:Int, blendDstAlpha:Int, blendColor:Float, blendAlpha:Float, premultipliedAlpha:Bool) {
        if (blending == WebGLRenderingContext.NO_BLENDING) {
            if (currentBlendingEnabled == true) {
                disable(WebGLRenderingContext.BLEND);
                currentBlendingEnabled = false;
            }
            return;
        }
        if (currentBlendingEnabled == false) {
            enable(WebGLRenderingContext.BLEND);
            currentBlendingEnabled = true;
        }
        if (blending != WebGLRenderingContext.CUSTOM_BLENDING) {
            if (blending != currentBlending || premultipliedAlpha != currentPremultipledAlpha) {
                if (currentBlendEquation != WebGLRenderingContext.FUNC_ADD || currentBlendEquationAlpha != WebGLRenderingContext.FUNC_ADD) {
                    gl.blendEquation(WebGLRenderingContext.FUNC_ADD);
                    currentBlendEquation = WebGLRenderingContext.FUNC_ADD;
                    currentBlendEquationAlpha = WebGLRenderingContext.FUNC_ADD;
                }
                if (premultipliedAlpha) {
                    switch (blending) {
                        case WebGLRenderingContext.NORMAL_BLENDING:
                            gl.blendFuncSeparate(WebGLRenderingContext.ONE, WebGLRenderingContext.ONE_MINUS_SRC_ALPHA, WebGLRenderingContext.ONE, WebGLRenderingContext.ONE_MINUS_SRC_ALPHA);
                            break;
                        case WebGLRenderingContext.ADDITIVE_BLENDING:
                            gl.blendFunc(WebGLRenderingContext.ONE, WebGLRenderingContext.ONE);
                            break;
                        case WebGLRenderingContext.SUBTRACTIVE_BLENDING:
                            gl.blendFuncSeparate(WebGLRenderingContext.ZERO, WebGLRenderingContext.ONE_MINUS_SRC_COLOR, WebGLRenderingContext.ZERO, WebGLRenderingContext.ONE);
                            break;
                        case WebGLRenderingContext.MULTIPLY_BLENDING:
                            gl.blendFuncSeparate(WebGLRenderingContext.ZERO, WebGLRenderingContext.SRC_COLOR, WebGLRenderingContext.ZERO, WebGLRenderingContext.SRC_ALPHA);
                            break;
                        default:
                            trace("WebGLState: Invalid blending: " + blending);
                            break;
                    }
                } else {
                    switch (blending) {
                        case WebGLRenderingContext.NORMAL_BLENDING:
                            gl.blendFuncSeparate(WebGLRenderingContext.SRC_ALPHA, WebGLRenderingContext.ONE_MINUS_SRC_ALPHA, WebGLRenderingContext.ONE, WebGLRenderingContext.ONE_MINUS_SRC_ALPHA);
                            break;
                        case WebGLRenderingContext.ADDITIVE_BLENDING:
                            gl.blendFunc(WebGLRenderingContext.SRC_ALPHA, WebGLRenderingContext.ONE);
                            break;
                        case WebGLRenderingContext.SUBTRACTIVE_BLENDING:
                            gl.blendFuncSeparate(WebGLRenderingContext.ZERO, WebGLRenderingContext.ONE_MINUS_SRC_COLOR, WebGLRenderingContext.ZERO, WebGLRenderingContext.ONE);
                            break;
                        case WebGLRenderingContext.MULTIPLY_BLENDING:
                            gl.blendFunc(WebGLRenderingContext.ZERO, WebGLRenderingContext.SRC_COLOR);
                            break;
                        default:
                            trace("WebGLState: Invalid blending: " + blending);
                            break;
                    }
                }
                currentBlendSrc = 0;
                currentBlendDst = 0;
                currentBlendSrcAlpha = 0;
                currentBlendDstAlpha = 0;
                currentBlendColor = 0;
                currentBlendAlpha = 0;
                currentBlending = blending;
                currentPremultipledAlpha = premultipliedAlpha;
            }
            return;
        }
        // custom blending
        blendEquationAlpha = blendEquationAlpha == null ? blendEquation : blendEquationAlpha;
        blendSrcAlpha = blendSrcAlpha == null ? blendSrc : blendSrcAlpha;
        blendDstAlpha = blendDstAlpha == null ? blendDst : blendDstAlpha;
        if (blendEquation != currentBlendEquation || blendEquationAlpha != currentBlendEquationAlpha) {
            gl.blendEquationSeparate(equationToGL.get(blendEquation), equationToGL.get(blendEquationAlpha));
            currentBlendEquation = blendEquation;
            currentBlendEquationAlpha = blendEquationAlpha;
        }
        if (blendSrc != currentBlendSrc || blendDst != currentBlendDst || blendSrcAlpha != currentBlendSrcAlpha || blendDstAlpha != currentBlendDstAlpha) {
            gl.blendFuncSeparate(factorToGL.get(blendSrc), factorToGL.get(blendDst), factorToGL.get(blendSrcAlpha), factorToGL.get(blendDstAlpha));
            currentBlendSrc = blendSrc;
            currentBlendDst = blendDst;
            currentBlendSrcAlpha = blendSrcAlpha;
            currentBlendDstAlpha = blendDstAlpha;
        }
        if (blendColor != currentBlendColor || blendAlpha != currentBlendAlpha) {
            gl.blendColor(blendColor, blendAlpha);
            currentBlendColor = blendColor;
            currentBlendAlpha = blendAlpha;
        }
        currentBlending = blending;
        currentPremultipledAlpha = false;
    }

    function setMaterial(material:Dynamic, frontFaceCW:Bool) {
        if (material.side == WebGLRenderingContext.DOUBLE_SIDED) {
            disable(WebGLRenderingContext.CULL_FACE);
        } else {
            enable(WebGLRenderingContext.CULL_FACE);
        }
        var flipSided = (material.side == WebGLRenderingContext.BACK_SIDE);
        if (frontFaceCW) flipSided = !flipSided;
        setFlipSided(flipSided);
        if (material.blending == WebGLRenderingContext.NORMAL_BLENDING && material.transparent == false) {
            setBlending(WebGLRenderingContext.NO_BLENDING);
        } else {
            setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst, material.blendEquationAlpha, material.blendSrcAlpha, material.blendDstAlpha, material.blendColor, material.blendAlpha, material.premultipliedAlpha);
        }
        depthBuffer.setFunc(material.depthFunc);
        depthBuffer.setTest(material.depthTest);
        depthBuffer.setMask(material.depthWrite);
        colorBuffer.setMask(material.colorWrite);
        var stencilWrite = material.stencilWrite;
        stencilBuffer.setTest(stencilWrite);
        if (stencilWrite) {
            stencilBuffer.setMask(material.stencilWriteMask);
            stencilBuffer.setFunc(material.stencilFunc, material.stencilRef, material.stencilFuncMask);
            stencilBuffer.setOp(material.stencilFail, material.stencilZFail, material.stencilZPass);
        }
        setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
        if (material.alphaToCoverage == true) {
            enable(WebGLRenderingContext.SAMPLE_ALPHA_TO_COVERAGE);
        } else {
            disable(WebGLRenderingContext.SAMPLE_ALPHA_TO_COVERAGE);
        }
    }

    function setFlipSided(flipSided:Bool) {
        if (currentFlipSided != flipSided) {
            if (flipSided) {
                gl.frontFace(WebGLRenderingContext.CW);
            } else {
                gl.frontFace(WebGLRenderingContext.CCW);
            }
            currentFlipSided = flipSided;
        }
    }

    function setCullFace(cullFace:Int) {
        if (cullFace != WebGLRenderingContext.CULL_FACE_NONE) {
            enable(WebGLRenderingContext.CULL_FACE);
            if (cullFace != currentCullFace) {
                if (cullFace == WebGLRenderingContext.CULL_FACE_BACK) {
                    gl.cullFace(WebGLRenderingContext.BACK);
                } else if (cullFace == WebGLRenderingContext.CULL_FACE_FRONT) {
                    gl.cullFace(WebGLRenderingContext.FRONT);
                } else {
                    gl.cullFace(WebGLRenderingContext.FRONT_AND_BACK);
                }
            }
        } else {
            disable(WebGLRenderingContext.CULL_FACE);
        }
        currentCullFace = cullFace;
    }

    function setLineWidth(width:Float) {
        if (width != currentLineWidth) {
            if (lineWidthAvailable) gl.lineWidth(width);
            currentLineWidth = width;
        }
    }

    function setPolygonOffset(polygonOffset:Bool, factor:Float, units:Float) {
        if (polygonOffset) {
            enable(WebGLRenderingContext.POLYGON_OFFSET_FILL);
            if (currentPolygonOffsetFactor != factor || currentPolygonOffsetUnits != units) {
                gl.polygonOffset(factor, units);
                currentPolygonOffsetFactor = factor;
                currentPolygonOffsetUnits = units;
            }
        } else {
            disable(WebGLRenderingContext.POLYGON_OFFSET_FILL);
        }
    }

    function setScissorTest(scissorTest:Bool) {
        if (scissorTest) {
            enable(WebGLRenderingContext.SCISSOR_TEST);
        } else {
            disable(WebGLRenderingContext.SCISSOR_TEST);
        }
    }

    function activeTexture(webglSlot:Int) {
        if (webglSlot == null) webglSlot = gl.TEXTURE0 + maxTextures - 1;
        if (currentTextureSlot != webglSlot) {
            gl.activeTexture(webglSlot);
            currentTextureSlot = webglSlot;
        }
    }

    function bindTexture(webglType:Int, webglTexture:WebGLTexture, webglSlot:Int) {
        if (webglSlot == null) {
            if (currentTextureSlot == null) {
                webglSlot = gl.TEXTURE0 + maxTextures - 1;
            } else {
                webglSlot = currentTextureSlot;
            }
        }
        var boundTexture = currentBoundTextures.get(webglSlot);
        if (boundTexture == null) {
            boundTexture = { type: null, texture: null };
            currentBoundTextures.set(webglSlot, boundTexture);
        }
        if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
            if (currentTextureSlot != webglSlot) {
                gl.activeTexture(webglSlot);
                currentTextureSlot = webglSlot;
            }
            gl.bindTexture(webglType, webglTexture == null ? emptyTextures.get(webglType) : webglTexture);
            boundTexture.type = webglType;
            boundTexture.texture = webglTexture;
        }
    }

    function unbindTexture() {
        var boundTexture = currentBoundTextures.get(currentTextureSlot);
        if (boundTexture != null && boundTexture.type != null) {
            gl.bindTexture(boundTexture.type, null);
            boundTexture.type = null;
            boundTexture.texture = null;
        }
    }

    function compressedTexImage2D() {
        try {
            gl.compressedTexImage2D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function compressedTexImage3D() {
        try {
            gl.compressedTexImage3D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function texSubImage2D() {
        try {
            gl.texSubImage2D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function texSubImage3D() {
        try {
            gl.texSubImage3D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function compressedTexSubImage2D() {
        try {
            gl.compressedTexSubImage2D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function compressedTexSubImage3D() {
        try {
            gl.compressedTexSubImage3D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function texStorage2D() {
        try {
            gl.texStorage2D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function texStorage3D() {
        try {
            gl.texStorage3D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function texImage2D() {
        try {
            gl.texImage2D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
    }

    function texImage3D() {
        try {
            gl.texImage3D.apply(gl, arguments);
        } catch (error) {
            trace("WebGLState: " + error);
        }
    }

    function scissor(scissor:Float) {
        if (currentScissor != scissor) {
            gl.scissor(scissor.x, scissor.y, scissor.z, scissor.w);
            currentScissor = scissor;
        }
    }

    function viewport(viewport:Float) {
        if (currentViewport != viewport) {
            gl.viewport(viewport.x, viewport.y, viewport.z, viewport.w);
            currentViewport = viewport;
        }
    }

    function updateUBOMapping(uniformsGroup:Dynamic, program:WebGLProgram) {
        var mapping = uboProgramMap.get(program);
        if (mapping == null) {
            mapping = new Map();
            uboProgramMap.set(program, mapping);
        }
        var blockIndex = mapping.get(uniformsGroup);
        if (blockIndex == null) {
            blockIndex = gl.getUniformBlockIndex(program, uniformsGroup.name);
            mapping.set(uniformsGroup, blockIndex);
        }
    }

    function uniformBlockBinding(uniformsGroup:Dynamic, program:WebGLProgram) {
        var mapping = uboProgramMap.get(program);
        var blockIndex = mapping.get(uniformsGroup);
        if (uboBindings.get(program) != blockIndex) {
            // bind shader specific block index to global block point
            gl.uniformBlockBinding(program, blockIndex, uniformsGroup.__bindingPointIndex);
            uboBindings.set(program, blockIndex);
        }
    }

    function reset() {
        // reset state
        gl.disable(WebGLRenderingContext.BLEND);
        gl.disable(WebGLRenderingContext.CULL_FACE);
        gl.disable(WebGLRenderingContext.DEPTH_TEST);
        gl.disable(WebGLRenderingContext.POLYGON_OFFSET_FILL);
        gl.disable(WebGLRenderingContext.SCISSOR_TEST);
        gl.disable(WebGLRenderingContext.STENCIL_TEST);
        gl.disable(WebGLRenderingContext.SAMPLE_ALPHA_TO_COVERAGE);
        gl.blendEquation(WebGLRenderingContext.FUNC_ADD);
        gl.blendFunc(WebGLRenderingContext.ONE, WebGLRenderingContext.ZERO);
        gl.blendFuncSeparate(WebGLRenderingContext.ONE, WebGLRenderingContext.ZERO, WebGLRenderingContext.ONE, WebGLRenderingContext.ZERO);
        gl.blendColor(0, 0, 0, 0);
        gl.colorMask(true, true, true, true);
        gl.clearColor(0, 0, 0, 0);
        gl.depthMask(true);
        gl.depthFunc(WebGLRenderingContext.LESS);
        gl.clearDepth(1);
        gl.stencilMask(0xffffffff);
        gl.stencilFunc(WebGLRenderingContext.ALWAYS, 0, 0xffffffff);
        gl.stencilOp(WebGLRenderingContext.KEEP, WebGLRenderingContext.KEEP, WebGLRenderingContext.KEEP);
        gl.clearStencil(0);
        gl.cullFace(WebGLRenderingContext.BACK);
        gl.frontFace(WebGLRenderingContext.CCW);
        gl.polygonOffset(0, 0);
        gl.activeTexture(WebGLRenderingContext.TEXTURE0);
        gl.bindFramebuffer(WebGLRenderingContext.FRAMEBUFFER, null);
        gl.bindFramebuffer(WebGLRenderingContext.DRAW_FRAMEBUFFER, null);
        gl.bindFramebuffer(WebGLRenderingContext.READ_FRAMEBUFFER, null);
        gl.useProgram(null);
        gl.lineWidth(1);
        gl.scissor(0, 0, gl.canvas.width, gl.canvas.height);
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
        // reset internals
        enabledCapabilities = new Map();
        currentTextureSlot = null;
        currentBoundTextures = new Map();
        currentBoundFramebuffers = new Map();
        currentDrawbuffers = new Map();
        defaultDrawbuffers = [];
        currentProgram = null;
        currentBlendingEnabled = false;
        currentBlending = 0;
        currentBlendEquation = 0;
        currentBlendSrc = 0;
        currentBlendDst = 0;
        currentBlendEquationAlpha = 0;
        currentBlendSrcAlpha = 0;
        currentBlendDstAlpha = 0;
        currentBlendColor = 0;
        currentBlendAlpha = 0;
        currentPremultipledAlpha = false;
        currentFlipSided = false;
        currentCullFace = 0;
        currentLineWidth = 0;
        currentPolygonOffsetFactor = 0;
        currentPolygonOffsetUnits = 0;
        currentScissor = 0;
        currentViewport = 0;
        colorBuffer.reset();
        depthBuffer.reset();
        stencilBuffer.reset();
    }

    public function new(gl:WebGLRenderingContext) {
        this.gl = gl;
        maxTextures = gl.getParameter(WebGLRenderingContext.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
        var scissorParam = gl.getParameter(WebGLRenderingContext.SCISSOR_BOX);
        var viewportParam = gl.getParameter(WebGLRenderingContext.VIEWPORT);
        currentScissor = new Float(scissorParam[0], scissorParam[1], scissorParam[2], scissorParam[3]);
        currentViewport = new Float(viewportParam[0], viewportParam[1], viewportParam[2], viewportParam[3]);
        emptyTextures = new Map();
        emptyTextures.set(WebGLRenderingContext.TEXTURE_2D, createTexture(WebGLRenderingContext.TEXTURE_2D, WebGLRenderingContext.TEXTURE_2D, 1));
        emptyTextures.set(WebGLRenderingContext.TEXTURE_CUBE_MAP, createTexture(WebGLRenderingContext.TEXTURE_CUBE_MAP, WebGLRenderingContext.TEXTURE_CUBE_MAP_POSITIVE_X, 6));
        emptyTextures.set(WebGLRenderingContext.TEXTURE_2D_ARRAY, createTexture(WebGLRenderingContext.TEXTURE_2D_ARRAY, WebGLRenderingContext.TEXTURE_2D_ARRAY, 1, 1));
        emptyTextures.set(WebGLRenderingContext.TEXTURE_3D, createTexture(WebGLRenderingContext.TEXTURE_3D, WebGLRenderingContext.TEXTURE_3D, 1, 1));
        colorBuffer.setClear(0, 0, 0, 1);
        depthBuffer.setClear(1);
        stencilBuffer.setClear(0);
        enable(WebGLRenderingContext.DEPTH_TEST);
        depthBuffer.setFunc(WebGLRenderingContext.LEQUAL);
        setFlipSided(false);
        setCullFace(WebGLRenderingContext.CULL_FACE_BACK);
        enable(WebGLRenderingContext.CULL_FACE);
        setBlending(WebGLRenderingContext.NO_BLENDING);
    }

    function createTexture(type:Int, target:Int, count:Int, dimensions:Int) {
        var data = new Uint8Array(4); // 4 is required to match default unpack alignment of 4.
        var texture = gl.createTexture();
        gl.bindTexture(type, texture);
        gl.texParameteri(type, WebGLRenderingContext.TEXTURE_MIN_FILTER, WebGLRenderingContext.NEAREST);
        gl.texParameteri(type, WebGLRenderingContext.TEXTURE_MAG_FILTER, WebGLRenderingContext.NEAREST);
        for (i in 0...count) {
            if (type == WebGLRenderingContext.TEXTURE_3D || type == WebGLRenderingContext.TEXTURE_2D_ARRAY) {
                gl.texImage3D(target, 0, WebGLRenderingContext.RGBA, 1, 1, dimensions, 0, WebGLRenderingContext.RGBA, WebGLRenderingContext.UNSIGNED_BYTE, data);
            } else {
                gl.texImage2D(target + i, 0, WebGLRenderingContext.RGBA, 1, 1, 0, WebGLRenderingContext.RGBA, WebGLRenderingContext.UNSIGNED_BYTE, data);
            }
        }
        return texture;
    }

    class ColorBuffer {
        var locked:Bool;
        var color:Float;
        var currentColorMask:Bool;
        var currentColorClear:Float;

        function new() {
            locked = false;
            color = new Float(0, 0, 0, 0);
            currentColorMask = null;
            currentColorClear = new Float(0, 0, 0, 0);
        }

        function setMask(colorMask:Bool) {
            if (currentColorMask != colorMask && !locked) {
                gl.colorMask(colorMask, colorMask, colorMask, colorMask);
                currentColorMask = colorMask;
            }
        }

        function setLocked(lock:Bool) {
            locked = lock;
        }

        function setClear(r:Float, g:Float, b:Float, a:Float, premultipliedAlpha:Bool) {
            if (premultipliedAlpha == true) {
                r *= a;
                g *= a;
                b *= a;
            }
            color.set(r, g, b, a);
            if (currentColorClear != color) {
                gl.clearColor(r, g, b, a);
                currentColorClear = color;
            }
        }

        function reset() {
            locked = false;
            currentColorMask = null;
            currentColorClear.set(-1, 0, 0, 0); // set to invalid state
        }
    }

    class DepthBuffer {
        var locked:Bool;
        var currentDepthMask:Bool;
        var currentDepthFunc:Int;
        var currentDepthClear:Float;

        function new() {
            locked = false;
            currentDepthMask = null;
            currentDepthFunc = null;
            currentDepthClear = null;
        }

        function setTest(depthTest:Bool) {
            if (depthTest) {
                enable(WebGLRenderingContext.DEPTH_TEST);
            } else {
                disable(WebGLRenderingContext.DEPTH_TEST);
            }
        }

        function setMask(depthMask:Bool) {
            if (currentDepthMask != depthMask && !locked) {
                gl.depthMask(depthMask);
                currentDepthMask = depthMask;
            }
        }

        function setFunc(depthFunc:Int) {
            if (currentDepthFunc != depthFunc) {
                switch (depthFunc) {
                    case WebGLRenderingContext.NEVER:
                        gl.depthFunc(WebGLRenderingContext.NEVER);
                        break;
                    case WebGLRenderingContext.ALWAYS:
                        gl.depthFunc(WebGLRenderingContext.ALWAYS);
                        break;
                    case WebGLRenderingContext.LESS:
                        gl.depthFunc(WebGLRenderingContext.LESS);
                        break;
                    case WebGLRenderingContext.LEQUAL:
                        gl.depthFunc(WebGLRenderingContext.LEQUAL);
                        break;
                    case WebGLRenderingContext.EQUAL:
                        gl.depthFunc(WebGLRenderingContext.EQUAL);
                        break;
                    case WebGLRenderingContext.GEQUAL:
                        gl.depthFunc(WebGLRenderingContext.GEQUAL);
                        break;
                    case WebGLRenderingContext.GREATER:
                        gl.depthFunc(WebGLRenderingContext.GREATER);
                        break;
                    case WebGLRenderingContext.NOTEQUAL:
                        gl.depthFunc(WebGLRenderingContext.NOTEQUAL);
                        break;
                    default:
                        gl.depthFunc(WebGLRenderingContext.LEQUAL);
                        break;
                }
                currentDepthFunc = depthFunc;
            }
        }

        function setLocked(lock:Bool) {
            locked = lock;
        }

        function setClear(depth:Float) {
            if (currentDepthClear != depth) {
                gl.clearDepth(depth);
                currentDepthClear = depth;
            }
        }

        function reset() {
            locked = false;
            currentDepthMask = null;
            currentDepthFunc = null;
            currentDepthClear = null;
        }
    }

    class StencilBuffer {
        var locked:Bool;
        var currentStencilMask:Int;
        var currentStencilFunc:Int;
        var currentStencilRef:Int;
        var currentStencilFuncMask:Int;
        var currentStencilFail:Int;
        var currentStencilZFail:Int;
        var currentStencilZPass:Int;
        var currentStencilClear:Int;

        function new() {
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

        function setTest(stencilTest:Bool) {
            if (!locked) {
                if (stencilTest) {
                    enable(WebGLRenderingContext.STENCIL_TEST);
                } else {
                    disable(WebGLRenderingContext.STENCIL_TEST);
                }
            }
        }

        function setMask(stencilMask:Int) {
            if (currentStencilMask != stencilMask && !locked) {
                gl.stencilMask(stencilMask);
                currentStencilMask = stencilMask;
            }
        }

        function setFunc(stencilFunc:Int, stencilRef:Int, stencilMask:Int) {
            if (currentStencilFunc != stencilFunc || currentStencilRef != stencilRef || currentStencilFuncMask != stencilMask) {
                gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
                currentStencilFunc = stencilFunc;
                currentStencilRef = stencilRef;
                currentStencilFuncMask = stencilMask;
            }
        }

        function setOp(stencilFail:Int, stencilZFail:Int, stencilZPass:Int) {
            if (currentStencilFail != stencilFail || currentStencilZFail != stencilZFail || currentStencilZPass != stencilZPass) {
                gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
                currentStencilFail = stencilFail;
                currentStencilZFail = stencilZFail;
                currentStencilZPass = stencilZPass;
            }
        }

        function setLocked(lock:Bool) {
            locked = lock;
        }

        function setClear(stencil:Int) {
            if (currentStencilClear != stencil) {
                gl.clearStencil(stencil);
                currentStencilClear = stencil;
            }
        }

        function reset() {
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
    }
}

class TextureInfo {
    var type:Int;
    var texture:WebGLTexture;
}