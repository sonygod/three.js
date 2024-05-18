import haxe.ds.IntMap;
import haxe.ds.WeakMap;
import openfl.display.Vector4;
import openfl.utils.FloatIntMap;
import webgl.WebGLContext;

class WebGLState {

    private var _gl:WebGLContext;

    public function new(gl:WebGLContext) {
        _gl = gl;
    }

    // ColorBuffer
    private class ColorBuffer {
        private var _locked:Bool;
        private var _color:Vector4;
        private var _currentColorMask:Int;
        private var _currentColorClear:Vector4;

        public function new() {
            _locked = false;
            _color = new Vector4();
            _currentColorMask = 0;
            _currentColorClear = new Vector4(0, 0, 0, 0);
        }

        public function setMask(colorMask:Int) {
            if (_currentColorMask != colorMask && !_locked) {
                _gl.colorMask(colorMask, colorMask, colorMask, colorMask);
                _currentColorMask = colorMask;
            }
        }

        public function setLocked(lock:Bool) {
            _locked = lock;
        }

        public function setClear(r:Float, g:Float, b:Float, a:Float, premultipliedAlpha:Bool) {
            if (premultipliedAlpha) {
                r *= a;
                g *= a;
                b *= a;
            }
            _color.set(r, g, b, a);
            if (_currentColorClear.equals(_color) == false) {
                _gl.clearColor(r, g, b, a);
                _currentColorClear.copy(_color);
            }
        }

        public function reset() {
            _locked = false;
            _currentColorMask = 0;
            _currentColorClear.set(-1, 0, 0, 0); // set to invalid state
        }
    }

    // DepthBuffer
    private class DepthBuffer {
        private var _locked:Bool;
        private var _currentDepthMask:Int;
        private var _currentDepthFunc:Int;
        private var _currentDepthClear:Float;

        public function new() {
            _locked = false;
            _currentDepthMask = 0;
            _currentDepthFunc = 0;
            _currentDepthClear = 1.0;
        }

        public function setTest(depthTest:Bool) {
            if (depthTest) {
                _gl.enable(gl.DEPTH_TEST);
            } else {
                _gl.disable(gl.DEPTH_TEST);
            }
        }

        public function setMask(depthMask:Int) {
            if (_currentDepthMask != depthMask && !_locked) {
                _gl.depthMask(depthMask);
                _currentDepthMask = depthMask;
            }
        }

        public function setFunc(depthFunc:Int) {
            if (_currentDepthFunc != depthFunc) {
                switch (depthFunc) {
                    case NeverDepth:
                        _gl.depthFunc(gl.NEVER);
                        break;
                    case AlwaysDepth:
                        _gl.depthFunc(gl.ALWAYS);
                        break;
                    case LessDepth:
                        _gl.depthFunc(gl.LESS);
                        break;
                    case LessEqualDepth:
                        _gl.depthFunc(gl.LEQUAL);
                        break;
                    case EqualDepth:
                        _gl.depthFunc(gl.EQUAL);
                        break;
                    case GreaterEqualDepth:
                        _gl.depthFunc(gl.GEQUAL);
                        break;
                    case GreaterDepth:
                        _gl.depthFunc(gl.GREATER);
                        break;
                    case NotEqualDepth:
                        _gl.depthFunc(gl.NOTEQUAL);
                        break;
                    default:
                        _gl.depthFunc(gl.LEQUAL);
                }
                _currentDepthFunc = depthFunc;
            }
        }

        public function setLocked(lock:Bool) {
            _locked = lock;
        }

        public function setClear(depth:Float) {
            if (_currentDepthClear != depth) {
                _gl.clearDepth(depth);
                _currentDepthClear = depth;
            }
        }

        public function reset() {
            _locked = false;
            _currentDepthMask = 0;
            _currentDepthFunc = 0;
            _currentDepthClear = 1.0;
        }
    }

    // StencilBuffer
    private class StencilBuffer {
        private var _locked:Bool;
        private var _currentStencilMask:Int;
        private var _currentStencilFunc:Int;
        private var _currentStencilRef:Int;
        private var _currentStencilFuncMask:Int;
        private var _currentStencilFail:Int;
        private var _currentStencilZFail:Int;
        private var _currentStencilZPass:Int;
        private var _currentStencilClear:Int;

        public function new() {
            _locked = false;
            _currentStencilMask = 0;
            _currentStencilFunc = 0;
            _currentStencilRef = 0;
            _currentStencilFuncMask = 0;
            _currentStencilFail = 0;
            _currentStencilZFail = 0;
            _currentStencilZPass = 0;
            _currentStencilClear = 0;
        }

        public function setTest(stencilTest:Bool) {
            if (!_locked) {
                if (stencilTest) {
                    _gl.enable(gl.STENCIL_TEST);
                } else {
                    _gl.disable(gl.STENCIL_TEST);
                }
            }
        }

        public function setMask(stencilMask:Int) {
            if (_currentStencilMask != stencilMask && !_locked) {
                _gl.stencilMask(stencilMask);
                _currentStencilMask = stencilMask;
            }
        }

        public function setFunc(stencilFunc:Int, stencilRef:Int, stencilMask:Int) {
            if (_currentStencilFunc != stencilFunc || _currentStencilRef != stencilRef || _currentStencilFuncMask != stencilMask) {
                _gl.stencilFunc(stencilFunc, stencilRef, stencilMask);
                _currentStencilFunc = stencilFunc;
                _currentStencilRef = stencilRef;
                _currentStencilFuncMask = stencilMask;
            }
        }

        public function setOp(stencilFail:Int, stencilZFail:Int, stencilZPass:Int) {
            if (_currentStencilFail != stencilFail || _currentStencilZFail != stencilZFail || _currentStencilZPass != stencilZPass) {
                _gl.stencilOp(stencilFail, stencilZFail, stencilZPass);
                _currentStencilFail = stencilFail;
                _currentStencilZFail = stencilZFail;
                _currentStencilZPass = stencilZPass;
            }
        }

        public function setLocked(lock:Bool) {
            _locked = lock;
        }

        public function setClear(stencil:Int) {
            if (_currentStencilClear != stencil) {
                _gl.clearStencil(stencil);
                _currentStencilClear = stencil;
            }
        }

        public function reset() {
            _locked = false;
            _currentStencilMask = 0;
            _currentStencilFunc = 0;
            _currentStencilRef = 0;
            _currentStencilFuncMask = 0;
            _currentStencilFail = 0;
            _currentStencilZFail = 0;
            _currentStencilZPass = 0;
            _currentStencilClear = 0;
        }
    }

    // WebGLState
    private var _colorBuffer:ColorBuffer;
    private var _depthBuffer:DepthBuffer;
    private var _stencilBuffer:StencilBuffer;
    private var _uboBindings:WeakMap<Dynamic, Int>;
    private var _uboProgramMap:WeakMap<Dynamic, WeakMap<Dynamic, Int>>;
    private var _enabledCapabilities:IntMap<Bool>;
    private var _currentBoundFramebuffers:Dynamic;
    private var _currentDrawbuffers:WeakMap<Dynamic, Array<Int>>;
    private var _defaultDrawbuffers:Array<Int>;
    private var _currentProgram:Dynamic;
    private var _currentBlendingEnabled:Bool;
    private var _currentBlending:Int;
    private var _currentBlendEquation:Int;
    private var _currentBlendSrc:Int;
    private var _currentBlendDst:Int;
    private var _currentBlendEquationAlpha:Int;
    private var _currentBlendSrcAlpha:Int;
    private var _currentBlendDstAlpha:Int;
    private var _currentBlendColor:Vector4;
    private var _currentBlendAlpha:Float;
    private var _currentPremultipledAlpha:Bool;
    private var _currentFlipSided:Int;
    private var _currentCullFace:Int;
    private var _currentLineWidth:Float;
    private var _currentPolygonOffsetFactor:Float;
    private var _currentPolygonOffsetUnits:Float;
    private var _maxTextures:Int;
    private var _lineWidthAvailable:Bool;
    private var _version:Int;
    private var _currentTextureSlot:Int;
    private var _currentBoundTextures:Dynamic;

    public function new() {
        _uboBindings = new WeakMap<Dynamic, Int>();
        _uboProgramMap = new WeakMap<Dynamic, WeakMap<Dynamic, Int>>();
        _enabledCapabilities = new IntMap<Bool>();
        _currentBoundFramebuffers = {};
        _currentDrawbuffers = new WeakMap<Dynamic, Array<Int>>();
        _defaultDrawbuffers = [gl.BACK];
        _currentProgram = null;
        _currentBlendingEnabled = false;
        _currentBlending = 0;
        _currentBlendEquation = 0;
        _currentBlendSrc = 0;
        _currentBlendDst = 0;
        _currentBlendEquationAlpha = 0;
        _currentBlendSrcAlpha = 0;
        _currentBlendDstAlpha = 0;
        _currentBlendColor = new Vector4(0, 0, 0);
        _currentBlendAlpha = 0;
        _currentPremultipledAlpha = false;
        _currentFlipSided = 0;
        _currentCullFace = 0;
        _currentLineWidth = 1;
        _currentPolygonOffsetFactor = 0;
        _currentPolygonOffsetUnits = 0;
        _maxTextures = _gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
        _lineWidthAvailable = false;
        _version = 0;
        _currentTextureSlot = 0;
        _currentBoundTextures = {};
    }

    // ... (Other methods from the original code)

}