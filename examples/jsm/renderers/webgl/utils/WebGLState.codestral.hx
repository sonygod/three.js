import three.CullFaceNone;
import three.CullFaceBack;
import three.CullFaceFront;
import three.DoubleSide;
import three.BackSide;
import three.NormalBlending;
import three.NoBlending;
import three.CustomBlending;
import three.AddEquation;
import three.AdditiveBlending;
import three.SubtractiveBlending;
import three.MultiplyBlending;
import three.SubtractEquation;
import three.ReverseSubtractEquation;
import three.ZeroFactor;
import three.OneFactor;
import three.SrcColorFactor;
import three.SrcAlphaFactor;
import three.SrcAlphaSaturateFactor;
import three.DstColorFactor;
import three.DstAlphaFactor;
import three.OneMinusSrcColorFactor;
import three.OneMinusSrcAlphaFactor;
import three.OneMinusDstColorFactor;
import three.OneMinusDstAlphaFactor;
import three.NeverDepth;
import three.AlwaysDepth;
import three.LessDepth;
import three.LessEqualDepth;
import three.EqualDepth;
import three.GreaterEqualDepth;
import three.GreaterDepth;
import three.NotEqualDepth;

class WebGLState {

    private var initialized:Bool = false;
    private var equationToGL:haxe.ds.IntMap;
    private var factorToGL:haxe.ds.IntMap;

    public var backend:Dynamic;
    public var gl:Dynamic;
    public var enabled:haxe.ds.IntMap;
    public var currentFlipSided:Bool;
    public var currentCullFace:Int;
    public var currentProgram:Dynamic;
    public var currentBlendingEnabled:Bool;
    public var currentBlending:Int;
    public var currentBlendSrc:Int;
    public var currentBlendDst:Int;
    public var currentBlendSrcAlpha:Int;
    public var currentBlendDstAlpha:Int;
    public var currentPremultipledAlpha:Bool;
    public var currentPolygonOffsetFactor:Float;
    public var currentPolygonOffsetUnits:Float;
    public var currentColorMask:Bool;
    public var currentDepthFunc:Int;
    public var currentDepthMask:Bool;
    public var currentStencilFunc:Int;
    public var currentStencilRef:Int;
    public var currentStencilFuncMask:Int;
    public var currentStencilFail:Int;
    public var currentStencilZFail:Int;
    public var currentStencilZPass:Int;
    public var currentStencilMask:Int;
    public var currentLineWidth:Float;
    public var currentBoundFramebuffers:haxe.ds.IntMap;
    public var currentDrawbuffers:haxe.ds.WeakMap;
    public var maxTextures:Int;
    public var currentTextureSlot:Int;
    public var currentBoundTextures:haxe.ds.IntMap;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = this.backend.gl;
        this.enabled = new haxe.ds.IntMap();
        this.currentDrawbuffers = new haxe.ds.WeakMap();
        this.currentBoundTextures = new haxe.ds.IntMap();
        this.maxTextures = this.gl.getParameter(this.gl.MAX_TEXTURE_IMAGE_UNITS);

        if (!initialized) {
            this._init(this.gl);
            initialized = true;
        }
    }

    private function _init(gl:Dynamic):Void {
        equationToGL = new haxe.ds.IntMap();
        equationToGL.set(AddEquation, gl.FUNC_ADD);
        equationToGL.set(SubtractEquation, gl.FUNC_SUBTRACT);
        equationToGL.set(ReverseSubtractEquation, gl.FUNC_REVERSE_SUBTRACT);

        factorToGL = new haxe.ds.IntMap();
        factorToGL.set(ZeroFactor, gl.ZERO);
        factorToGL.set(OneFactor, gl.ONE);
        factorToGL.set(SrcColorFactor, gl.SRC_COLOR);
        factorToGL.set(SrcAlphaFactor, gl.SRC_ALPHA);
        factorToGL.set(SrcAlphaSaturateFactor, gl.SRC_ALPHA_SATURATE);
        factorToGL.set(DstColorFactor, gl.DST_COLOR);
        factorToGL.set(DstAlphaFactor, gl.DST_ALPHA);
        factorToGL.set(OneMinusSrcColorFactor, gl.ONE_MINUS_SRC_COLOR);
        factorToGL.set(OneMinusSrcAlphaFactor, gl.ONE_MINUS_SRC_ALPHA);
        factorToGL.set(OneMinusDstColorFactor, gl.ONE_MINUS_DST_COLOR);
        factorToGL.set(OneMinusDstAlphaFactor, gl.ONE_MINUS_DST_ALPHA);
    }

    public function enable(id:Int):Void {
        if (!enabled.exists(id)) {
            gl.enable(id);
            enabled.set(id, true);
        }
    }

    public function disable(id:Int):Void {
        if (enabled.exists(id)) {
            gl.disable(id);
            enabled.set(id, false);
        }
    }

    public function setFlipSided(flipSided:Bool):Void {
        if (currentFlipSided != flipSided) {
            if (flipSided) {
                gl.frontFace(gl.CW);
            } else {
                gl.frontFace(gl.CCW);
            }
            currentFlipSided = flipSided;
        }
    }

    public function setCullFace(cullFace:Int):Void {
        if (cullFace != CullFaceNone) {
            this.enable(gl.CULL_FACE);
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
            this.disable(gl.CULL_FACE);
        }
        currentCullFace = cullFace;
    }

    public function setLineWidth(width:Float):Void {
        if (width != currentLineWidth) {
            gl.lineWidth(width);
            currentLineWidth = width;
        }
    }

    // other methods...
}