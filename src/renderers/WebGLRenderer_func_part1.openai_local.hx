import three.constants.*;
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

    public var isWebGLRenderer:Bool;
    public var domElement:Dynamic;
    public var debug:Dynamic;
    public var autoClear:Bool;
    public var autoClearColor:Bool;
    public var autoClearDepth:Bool;
    public var autoClearStencil:Bool;
    public var sortObjects:Bool;
    public var clippingPlanes:Array<Dynamic>;
    public var localClippingEnabled:Bool;
    public var _outputColorSpace:ColorSpace;
    public var _useLegacyLights:Bool;
    public var toneMapping:ToneMapping;
    public var toneMappingExposure:Float;

    private var _this:WebGLRenderer;
    private var _isContextLost:Bool;

    private var _currentActiveCubeFace:Int;
    private var _currentActiveMipmapLevel:Int;
    private var _currentRenderTarget:Dynamic;
    private var _currentMaterialId:Int;

    private var _currentCamera:Dynamic;

    private var _currentViewport:Vector4;
    private var _currentScissor:Vector4;
    private var _currentScissorTest:Dynamic;

    private var _currentClearColor:Color;
    private var _currentClearAlpha:Float;

    private var _width:Int;
    private var _height:Int;

    private var _pixelRatio:Float;
    private var _opaqueSort:Dynamic;
    private var _transparentSort:Dynamic;

    private var _viewport:Vector4;
    private var _scissor:Vector4;
    private var _scissorTest:Bool;

    private var _frustum:Frustum;
    private var _clippingEnabled:Bool;
    private var _localClippingEnabled:Bool;
    private var _projScreenMatrix:Matrix4;
    private var _vector3:Vector3;
    private var _emptyScene:Dynamic;

    private var _gl:Dynamic;

    private var extensions:WebGLExtensions;
    private var capabilities:WebGLCapabilities;
    private var state:WebGLState;
    private var info:WebGLInfo;
    private var properties:WebGLProperties;
    private var textures:WebGLTextures;
    private var cubemaps:WebGLCubeMaps;
    private var cubeuvmaps:WebGLCubeUVMaps;
    private var attributes:WebGLAttributes;
    private var geometries:WebGLGeometries;
    private var objects:WebGLObjects;
    private var morphtargets:WebGLMorphtargets;
    private var clipping:WebGLClipping;
    private var programCache:WebGLPrograms;
    private var materials:WebGLMaterials;
    private var renderLists:WebGLRenderLists;
    private var renderStates:WebGLRenderStates;
    private var background:WebGLBackground;
    private var shadowMap:WebGLShadowMap;
    private var uniformsGroups:WebGLUniformsGroups;
    private var bufferRenderer:WebGLBufferRenderer;
    private var indexedBufferRenderer:WebGLIndexedBufferRenderer;
    private var xr:WebXRManager;

    public function new(parameters:Dynamic = {}) {
        var canvas = if (parameters.exists("canvas")) parameters.canvas else createCanvasElement();
        var context = if (parameters.exists("context")) parameters.context else null;
        var depth = if (parameters.exists("depth")) parameters.depth else true;
        var stencil = if (parameters.exists("stencil")) parameters.stencil else false;
        var alpha = if (parameters.exists("alpha")) parameters.alpha else false;
        var antialias = if (parameters.exists("antialias")) parameters.antialias else false;
        var premultipliedAlpha = if (parameters.exists("premultipliedAlpha")) parameters.premultipliedAlpha else true;
        var preserveDrawingBuffer = if (parameters.exists("preserveDrawingBuffer")) parameters.preserveDrawingBuffer else false;
        var powerPreference = if (parameters.exists("powerPreference")) parameters.powerPreference else 'default';
        var failIfMajorPerformanceCaveat = if (parameters.exists("failIfMajorPerformanceCaveat")) parameters.failIfMajorPerformanceCaveat else false;

        this.isWebGLRenderer = true;

        var _alpha;

        if (context != null) {
            if (Type.getClassName(Type.getClass(context)) == "WebGLRenderingContext") {
                throw "THREE.WebGLRenderer: WebGL 1 is not supported since r163.";
            }
            _alpha = context.getContextAttributes().alpha;
        } else {
            _alpha = alpha;
        }

        var uintClearColor = new Uint32Array(4);
        var intClearColor = new Int32Array(4);

        var currentRenderList = null;
        var currentRenderState = null;

        var renderListStack = [];
        var renderStateStack = [];

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

        _this = this;

        _isContextLost = false;

        _currentActiveCubeFace = 0;
        _currentActiveMipmapLevel = 0;
        _currentRenderTarget = null;
        _currentMaterialId = -1;

        _currentCamera = null;

        _currentViewport = new Vector4();
        _currentScissor = new Vector4();
        _currentScissorTest = null;

        _currentClearColor = new Color(0x000000);
        _currentClearAlpha = 0;

        _width = canvas.width;
        _height = canvas.height;

        _pixelRatio = 1;
        _opaqueSort = null;
        _transparentSort = null;

        _viewport = new Vector4(0, 0, _width, _height);
        _scissor = new Vector4(0, 0, _width, _height);
        _scissorTest = false;

        _frustum = new Frustum();

        _clippingEnabled = false;
        _localClippingEnabled = false;

        _projScreenMatrix = new Matrix4();

        _vector3 = new Vector3();

        _emptyScene = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

        function getTargetPixelRatio():Float {
            return _currentRenderTarget == null ? _pixelRatio : 1;
        }

        _gl = context;

        function getContext(contextName:String, contextAttributes:Dynamic):Dynamic {
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

            if (Reflect.hasField(canvas, "setAttribute")) {
                canvas.setAttribute("data-engine", "three.js r" + REVISION);
            }

            canvas.addEventListener("webglcontextlost", onContextLost, false);
            canvas.addEventListener("webglcontextrestored", onContextRestore, false);
            canvas.addEventListener("webglcontextcreationerror", onContextCreationError, false);

            if (_gl == null) {
                var contextName = "webgl2";
                _gl = getContext(contextName, contextAttributes);

                if (_gl == null) {
                    if (getContext(contextName)) {
                        throw "Error creating WebGL context with your selected attributes.";
                    } else {
                        throw "Error creating WebGL context.";
                    }
                }
            }
        } catch (error) {
            haxe.Log.trace('THREE.WebGLRenderer: ${error.message}', { fileName: "WebGLRenderer_func_part1.hx", lineNumber: 169 });
        }
    }

    // Function to handle context lost
    function onContextLost(event:Dynamic):Void {
        event.preventDefault();

        haxe.Log.trace('THREE.WebGLRenderer: Context Lost.', { fileName: "WebGLRenderer_func_part1.hx", lineNumber: 177 });

        _isContextLost = true;

        // Notify all materials of the loss, so they can re-initialize their GL state
        properties.dispose();
    }

    // Function to handle context restoration
    function onContextRestore():Void {
        haxe.Log.trace('THREE.WebGLRenderer: Context Restored.', { fileName: "WebGLRenderer_func_part1.hx", lineNumber: 185 });

        _isContextLost = false;

        initGLContext();
    }

    // Function to handle context creation error
    function onContextCreationError(event:Dynamic):Void {
        haxe.Log.trace('THREE.WebGLRenderer: Context creation error.', { fileName: "WebGLRenderer_func_part1.hx", lineNumber: 193 });
    }

    function initGLContext():Void {
        // Initialize WebGL context and associated states
        haxe.Log.trace('THREE.WebGLRenderer: Initializing GL Context.', { fileName: "WebGLRenderer_func_part1.hx", lineNumber: 198 });

        // Initialize state, capabilities, etc.
        extensions = new WebGLExtensions(_gl);
        capabilities = new WebGLCapabilities(_gl, extensions, parameters);
        state = new WebGLState(_gl, extensions, capabilities);
        info = new WebGLInfo(_gl);
        properties = new WebGLProperties();
        textures = new WebGLTextures(_gl, extensions, state, properties, capabilities, info);
        cubemaps = new WebGLCubeMaps(_gl);
        cubeuvmaps = new WebGLCubeUVMaps(_gl);
        attributes = new WebGLAttributes(_gl);
        geometries = new WebGLGeometries(_gl, attributes);
        objects = new WebGLObjects(_gl, geometries, attributes, properties);
        morphtargets = new WebGLMorphtargets(_gl);
        clipping = new WebGLClipping(properties);
        programCache = new WebGLPrograms(_this, _gl, extensions, capabilities, clipping);
        materials = new WebGLMaterials(_this);
        renderLists = new WebGLRenderLists();
        renderStates = new WebGLRenderStates();
        background = new WebGLBackground(_this, _gl, state, objects, properties, capabilities);
        shadowMap = new WebGLShadowMap(_this, objects, capabilities.maxTextureSize);
        uniformsGroups = new WebGLUniformsGroups(_this);
        bufferRenderer = new WebGLBufferRenderer(_gl, extensions, info, capabilities);
        indexedBufferRenderer = new WebGLIndexedBufferRenderer(_gl, extensions, info, capabilities);
        xr = new WebXRManager(_this, _gl, capabilities);

        state.scissor(_currentScissor.copy(_scissor).multiplyScalar(_pixelRatio));
        state.viewport(_currentViewport.copy(_viewport).multiplyScalar(_pixelRatio));

        info.autoReset = true;
    }
}