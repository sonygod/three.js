package three;

import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;

class WebGLState {
    private var gl:WebGLRenderingContext;
    private var colorBuffer:ColorBuffer;
    private var depthBuffer:DepthBuffer;
    private var stencilBuffer:StencilBuffer;

    private var uboBindings:WeakMap<WebGLProgram, Dynamic>;
    private var uboProgramMap:WeakMap<WebGLProgram, Dynamic>;

    private var enabledCapabilities:Map<Int, Bool>;
    private var currentBoundFramebuffers:Map<Int, WebGLFramebuffer>;
    private var currentDrawbuffers:WeakMap<WebGLFramebuffer, Array<Int>>;
    private var defaultDrawbuffers:Array<Int>;

    private var currentProgram:WebGLProgram;

    private var currentBlendingEnabled:Bool;
    private var currentBlending:Int;
    private var currentBlendEquation:Int;
    private var currentBlendSrc:Int;
    private var currentBlendDst:Int;
    private var currentBlendEquationAlpha:Int;
    private var currentBlendSrcAlpha:Int;
    private var currentBlendDstAlpha:Int;
    private var currentBlendColor:Color;
    private var currentBlendAlpha:Float;
    private var currentPremultipledAlpha:Bool;

    private var currentFlipSided:Null<Bool>;
    private var currentCullFace:Null<Int>;

    private var currentLineWidth:Null<Float>;

    private var currentPolygonOffsetFactor:Null<Float>;
    private var currentPolygonOffsetUnits:Null<Float>;

    private var currentScissor:Vector4;
    private var currentViewport:Vector4;

    public function new(gl:WebGLRenderingContext) {
        this.gl = gl;

        this.colorBuffer = new ColorBuffer();
        this.depthBuffer = new DepthBuffer();
        this.stencilBuffer = new StencilBuffer();

        this.uboBindings = new WeakMap();
        this.uboProgramMap = new WeakMap();

        this.enabledCapabilities = new Map();
        this.currentBoundFramebuffers = new Map();
        this.currentDrawbuffers = new WeakMap();
        this.defaultDrawbuffers = [];

        this.currentProgram = null;

        this.currentBlendingEnabled = false;
        this.currentBlending = null;
        this.currentBlendEquation = null;
        this.currentBlendSrc = null;
        this.currentBlendDst = null;
        this.currentBlendEquationAlpha = null;
        this.currentBlendSrcAlpha = null;
        this.currentBlendDstAlpha = null;
        this.currentBlendColor = new Color(0, 0, 0);
        this.currentBlendAlpha = 0;
        this.currentPremultipledAlpha = false;

        this.currentFlipSided = null;
        this.currentCullFace = null;

        this.currentLineWidth = null;

        this.currentPolygonOffsetFactor = null;
        this.currentPolygonOffsetUnits = null;

        this.currentScissor = new Vector4();
        this.currentViewport = new Vector4();

        init();
    }

    private function init() {
        this.colorBuffer.setClear(0, 0, 0, 1);
        this.depthBuffer.setClear(1);
        this.stencilBuffer.setClear(0);

        this.gl.enable(this.gl.DEPTH_TEST);
        this.depthBuffer.setFunc(LessEqualDepth);

        this.setFlipSided(false);
        this.setCullFace(CullFaceBack);
        this.gl.enable(this.gl.CULL_FACE);

        this.setBlending(NoBlending);
    }

    // ... rest of the code ...

    public function enable(id:Int) {
        if (!enabledCapabilities.exists(id)) {
            this.gl.enable(id);
            enabledCapabilities.set(id, true);
        }
    }

    public function disable(id:Int) {
        if (enabledCapabilities.exists(id)) {
            this.gl.disable(id);
            enabledCapabilities.set(id, false);
        }
    }

    public function bindFramebuffer(target:Int, framebuffer:WebGLFramebuffer) {
        if (currentBoundFramebuffers[target] != framebuffer) {
            this.gl.bindFramebuffer(target, framebuffer);
            currentBoundFramebuffers[target] = framebuffer;
            return true;
        }
        return false;
    }

    public function drawBuffers(renderTarget: RENDER_TARGET, framebuffer:WebGLFramebuffer) {
        var drawBuffers:Array<Int>;
        if (renderTarget != null) {
            drawBuffers = currentDrawbuffers.get(framebuffer);
            if (drawBuffers == null) {
                drawBuffers = [];
                currentDrawbuffers.set(framebuffer, drawBuffers);
            }

            var textures = renderTarget.textures;
            if (drawBuffers.length != textures.length || drawBuffers[0] != gl.COLOR_ATTACHMENT0) {
                for (i in 0...textures.length) {
                    drawBuffers[i] = gl.COLOR_ATTACHMENT0 + i;
                }
                drawBuffers.length = textures.length;
            }
        } else {
            drawBuffers = defaultDrawbuffers;
        }

        if (drawBuffers[0] != gl.BACK) {
            drawBuffers[0] = gl.BACK;
        }

        this.gl.drawBuffers(drawBuffers);
    }

    public function useProgram(program:WebGLProgram) {
        if (currentProgram != program) {
            this.gl.useProgram(program);
            currentProgram = program;
            return true;
        }
        return false;
    }

    // ... rest of the code ...
}