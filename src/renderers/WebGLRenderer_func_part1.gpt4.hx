import three.constants.REVISION;
import three.constants.BackSide;
import three.constants.FrontSide;
import three.constants.DoubleSide;
import three.constants.HalfFloatType;
import three.constants.UnsignedByteType;
import three.constants.NoToneMapping;
import three.constants.LinearMipmapLinearFilter;
import three.constants.SRGBColorSpace;
import three.constants.LinearSRGBColorSpace;
import three.constants.RGBAIntegerFormat;
import three.constants.RGIntegerFormat;
import three.constants.RedIntegerFormat;
import three.constants.UnsignedIntType;
import three.constants.UnsignedShortType;
import three.constants.UnsignedInt248Type;
import three.constants.UnsignedShort4444Type;
import three.constants.UnsignedShort5551Type;
import three.constants.WebGLCoordinateSystem;
import three.constants.DisplayP3ColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Vector3;
import three.math.Vector4;
import three.webgl.WebGLAnimation;
import three.webgl.WebGLAttributes;
import three.webgl.WebGLBackground;
import three.webgl.WebGLBindingStates;
import three.webgl.WebGLBufferRenderer;
import three.webgl.WebGLCapabilities;
import three.webgl.WebGLClipping;
import three.webgl.WebGLCubeMaps;
import three.webgl.WebGLCubeUVMaps;
import three.webgl.WebGLExtensions;
import three.webgl.WebGLGeometries;
import three.webgl.WebGLIndexedBufferRenderer;
import three.webgl.WebGLInfo;
import three.webgl.WebGLMorphtargets;
import three.webgl.WebGLObjects;
import three.webgl.WebGLPrograms;
import three.webgl.WebGLProperties;
import three.webgl.WebGLRenderLists;
import three.webgl.WebGLRenderStates;
import three.WebGLRenderTarget;
import three.webgl.WebGLShadowMap;
import three.webgl.WebGLState;
import three.webgl.WebGLTextures;
import three.webgl.WebGLUniforms;
import three.webgl.WebGLUtils;
import three.webxr.WebXRManager;
import three.webgl.WebGLMaterials;
import three.webgl.WebGLUniformsGroups;
import three.utils.createCanvasElement;
import three.utils.probeAsync;
import three.math.ColorManagement;

class WebGLRenderer {
    public var domElement:Dynamic;
    public var debug:Dynamic;
    public var autoClear:Bool;
    public var autoClearColor:Bool;
    public var autoClearDepth:Bool;
    public var autoClearStencil:Bool;
    public var sortObjects:Bool;
    public var clippingPlanes:Array<Dynamic>;
    public var localClippingEnabled:Bool;
    public var toneMapping:Dynamic;
    public var toneMappingExposure:Float;
    public var capabilities:Dynamic;
    public var extensions:Dynamic;
    public var properties:Dynamic;
    public var renderLists:Dynamic;
    public var shadowMap:Dynamic;
    public var state:Dynamic;
    public var info:Dynamic;
    public var xr:Dynamic;

    private var _alpha:Bool;
    private var _isContextLost:Bool = false;
    private var _currentActiveCubeFace:Int = 0;
    private var _currentActiveMipmapLevel:Int = 0;
    private var _currentRenderTarget:Dynamic;
    private var _currentMaterialId:Int = -1;
    private var _currentCamera:Dynamic;
    private var _currentViewport:Vector4 = new Vector4();
    private var _currentScissor:Vector4 = new Vector4();
    private var _currentScissorTest:Bool = false;
    private var _currentClearColor:Color = new Color(0x000000);
    private var _currentClearAlpha:Int = 0;
    private var _width:Int;
    private var _height:Int;
    private var _pixelRatio:Float = 1;
    private var _opaqueSort:Dynamic;
    private var _transparentSort:Dynamic;
    private var _viewport:Vector4;
    private var _scissor:Vector4;
    private var _frustum:Frustum = new Frustum();
    private var _clippingEnabled:Bool = false;
    private var _localClippingEnabled:Bool = false;
    private var _projScreenMatrix:Matrix4 = new Matrix4();
    private var _vector3:Vector3 = new Vector3();
    private var _emptyScene:Dynamic = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

    public function new(parameters:Dynamic = null) {
        if (parameters == null) parameters = {};
        
        var canvas = parameters.canvas != null ? parameters.canvas : createCanvasElement();
        var context = parameters.context;
        var depth = parameters.depth != null ? parameters.depth : true;
        var stencil = parameters.stencil != null ? parameters.stencil : false;
        var alpha = parameters.alpha != null ? parameters.alpha : false;
        var antialias = parameters.antialias != null ? parameters.antialias : false;
        var premultipliedAlpha = parameters.premultipliedAlpha != null ? parameters.premultipliedAlpha : true;
        var preserveDrawingBuffer = parameters.preserveDrawingBuffer != null ? parameters.preserveDrawingBuffer : false;
        var powerPreference = parameters.powerPreference != null ? parameters.powerPreference : 'default';
        var failIfMajorPerformanceCaveat = parameters.failIfMajorPerformanceCaveat != null ? parameters.failIfMajorPerformanceCaveat : false;

        this.isWebGLRenderer = true;

        if (context != null) {
            if (Std.is(context, WebGLRenderingContext)) {
                throw 'THREE.WebGLRenderer: WebGL 1 is not supported since r163.';
            }
            _alpha = context.getContextAttributes().alpha;
        } else {
            _alpha = alpha;
        }

        var uintClearColor = new UInt32Array(4);
        var intClearColor = new Int32Array(4);
        var currentRenderList:Dynamic = null;
        var currentRenderState:Dynamic = null;

        var renderListStack:Array<Dynamic> = [];
        var renderStateStack:Array<Dynamic> = [];

        this.domElement = canvas;

        this.debug = {
            checkShaderErrors: true,
            onShaderError: null
        };

        this.autoClear = true;
        this.autoClearColor = true;
        this.autoClearDepth = true;
        this.autoClearStencil = true;

        this.sortObjects = true;

        this.clippingPlanes = [];
        this.localClippingEnabled = false;

        this._outputColorSpace = SRGBColorSpace;
        this._useLegacyLights = false;
        this.toneMapping = NoToneMapping;
        this.toneMappingExposure = 1.0;

        var _this = this;
        var _isContextLost = false;

        var _currentActiveCubeFace = 0;
        var _currentActiveMipmapLevel = 0;
        var _currentRenderTarget:Dynamic = null;
        var _currentMaterialId = -1;

        var _currentCamera:Dynamic = null;

        var _currentViewport = new Vector4();
        var _currentScissor = new Vector4();
        var _currentScissorTest = null;

        var _currentClearColor = new Color(0x000000);
        var _currentClearAlpha = 0;

        var _width = canvas.width;
        var _height = canvas.height;

        var _pixelRatio = 1;
        var _opaqueSort:Dynamic = null;
        var _transparentSort:Dynamic = null;

        var _viewport = new Vector4(0, 0, _width, _height);
        var _scissor = new Vector4(0, 0, _width, _height);
        var _scissorTest = false;

        var _frustum = new Frustum();

        var _clippingEnabled = false;
        var _localClippingEnabled = false;

        var _projScreenMatrix = new Matrix4();

        var _vector3 = new Vector3();

        var _emptyScene = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

        function getTargetPixelRatio() {
            return _currentRenderTarget == null ? _pixelRatio : 1;
        }

        var _gl:Dynamic = context;

        function getContext(contextName:String, contextAttributes:Dynamic) {
            return canvas.getContext(contextName, contextAttributes);
        }

        try {
            var contextAttributes = {
                alpha: true,
                depth: depth,
                stencil: stencil,
                antialias: antialias,
                premultipliedAlpha: premultipliedAlpha,
                preserveDrawingBuffer: preserveDrawingBuffer,
                powerPreference: powerPreference,
                failIfMajorPerformanceCaveat: failIfMajorPerformanceCaveat
            };

            if (Reflect.hasField(canvas, 'setAttribute')) {
                Reflect.callMethod(canvas, Reflect.field(canvas, 'setAttribute'), ['data-engine', 'three.js r' + REVISION]);
            }

            canvas.addEventListener('webglcontextlost', onContextLost, false);
            canvas.addEventListener('webglcontextrestored', onContextRestore, false);
            canvas.addEventListener('webglcontextcreationerror', onContextCreationError, false);

            if (_gl == null) {
                var contextName = 'webgl2';
                _gl = getContext(contextName, contextAttributes);

                if (_gl == null) {
                    if (getContext(contextName) == null) {
                        throw 'Error creating WebGL2 context with your own parameters.';
                    }
                }
            }

        } catch (error:Dynamic) {
            throw 'Error creating WebGL2 context: ' + error;
        }

        function onContextLost(event:Dynamic):Void {
            event.preventDefault();
            _isContextLost = true;
        }

        function onContextRestore():Void {
            _isContextLost = false;
            _gl = getContext('webgl2');
            _this.initGLContext();
        }

        function onContextCreationError(event:Dynamic):Void {
            console.error('THREE.WebGLRenderer: A WebGL context could not be created. Reason: ', event.statusMessage);
        }

        // Add the rest of your code here following the same pattern...
    }
}