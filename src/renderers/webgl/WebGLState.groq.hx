package three.js;

import haxe.ds.WeakMap;
import three.math.Color;
import three.math.Vector4;

class WebGLState {
    private var gl:WebGLRenderingContext;
    private var colorBuffer:ColorBuffer;
    private var depthBuffer:DepthBuffer;
    private var stencilBuffer:StencilBuffer;
    private var uboBindings:WeakMap<WebGLProgram, Int>;
    private var uboProgramMap:WeakMap<WebGLProgram, WeakMap<UniformsGroup, Int>>;
    private var currentBoundFramebuffers:WeakMap<Int, WebGLFramebuffer>;
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
    private var emptyTextures:Map<Int, WebGLTexture>;

    public function new(gl:WebGLRenderingContext) {
        this.gl = gl;
        colorBuffer = new ColorBuffer();
        depthBuffer = new DepthBuffer();
        stencilBuffer = new StencilBuffer();
        uboBindings = new WeakMap();
        uboProgramMap = new WeakMap();
        currentBoundFramebuffers = new WeakMap();
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
        currentScissor = new Vector4();
        currentViewport = new Vector4();
        emptyTextures = new Map();
        emptyTextures.set(gl.TEXTURE_2D, createTexture(gl.TEXTURE_2D, gl.TEXTURE_2D, 1));
        emptyTextures.set(gl.TEXTURE_CUBE_MAP, createTexture(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_CUBE_MAP, 6));
        emptyTextures.set(gl.TEXTURE_2D_ARRAY, createTexture(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_2D_ARRAY, 1, 1));
        emptyTextures.set(gl.TEXTURE_3D, createTexture(gl.TEXTURE_3D, gl.TEXTURE_3D, 1, 1));

        // init
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

    // ... (rest of the code remains the same)