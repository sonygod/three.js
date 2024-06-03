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
import three.renderers.webgl.WebGLAnimation;
import three.renderers.webgl.WebGLAttributes;
import three.renderers.webgl.WebGLBackground;
import three.renderers.webgl.WebGLBindingStates;
import three.renderers.webgl.WebGLBufferRenderer;
import three.renderers.webgl.WebGLCapabilities;
import three.renderers.webgl.WebGLClipping;
import three.renderers.webgl.WebGLCubeMaps;
import three.renderers.webgl.WebGLCubeUVMaps;
import three.renderers.webgl.WebGLExtensions;
import three.renderers.webgl.WebGLGeometries;
import three.renderers.webgl.WebGLIndexedBufferRenderer;
import three.renderers.webgl.WebGLInfo;
import three.renderers.webgl.WebGLMorphtargets;
import three.renderers.webgl.WebGLObjects;
import three.renderers.webgl.WebGLPrograms;
import three.renderers.webgl.WebGLProperties;
import three.renderers.webgl.WebGLRenderLists;
import three.renderers.webgl.WebGLRenderStates;
import three.renderers.WebGLRenderTarget;
import three.renderers.webgl.WebGLShadowMap;
import three.renderers.webgl.WebGLState;
import three.renderers.webgl.WebGLTextures;
import three.renderers.webgl.WebGLUniforms;
import three.renderers.webgl.WebGLUtils;
import three.renderers.webxr.WebXRManager;
import three.renderers.webgl.WebGLMaterials;
import three.renderers.webgl.WebGLUniformsGroups;
import three.utils.createCanvasElement;
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
    public var _outputColorSpace:Int;
    public var _useLegacyLights:Bool;
    public var toneMapping:Int;
    public var toneMappingExposure:Float;
    public var capabilities:WebGLCapabilities;
    public var extensions:WebGLExtensions;
    public var properties:WebGLProperties;
    public var renderLists:WebGLRenderLists;
    public var shadowMap:WebGLShadowMap;
    public var state:WebGLState;
    public var info:WebGLInfo;
    public var xr:WebXRManager;

    private var _alpha:Bool;
    private var uintClearColor:Uint32Array;
    private var intClearColor:Int32Array;
    private var currentRenderList:Dynamic;
    private var currentRenderState:Dynamic;
    private var renderListStack:Array<Dynamic>;
    private var renderStateStack:Array<Dynamic>;
    private var _isContextLost:Bool;
    private var _currentActiveCubeFace:Int;
    private var _currentActiveMipmapLevel:Int;
    private var _currentRenderTarget:WebGLRenderTarget;
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
    private var programCache:WebGLPrograms;
    private var materials:WebGLMaterials;
    private var renderLists:WebGLRenderLists;
    private var renderStates:WebGLRenderStates;
    private var clipping:WebGLClipping;
    private var shadowMap:WebGLShadowMap;
    private var background:WebGLBackground;
    private var morphtargets:WebGLMorphtargets;
    private var bufferRenderer:WebGLBufferRenderer;
    private var indexedBufferRenderer:WebGLIndexedBufferRenderer;
    private var utils:WebGLUtils;
    private var bindingStates:WebGLBindingStates;
    private var uniformsGroups:WebGLUniformsGroups;

    public function new(parameters:Dynamic = {}) {
        var canvas:Dynamic = parameters.canvas != null ? parameters.canvas : createCanvasElement();
        var context:Dynamic = parameters.context != null ? parameters.context : null;
        var depth:Bool = parameters.depth != null ? parameters.depth : true;
        var stencil:Bool = parameters.stencil != null ? parameters.stencil : false;
        var alpha:Bool = parameters.alpha != null ? parameters.alpha : false;
        var antialias:Bool = parameters.antialias != null ? parameters.antialias : false;
        var premultipliedAlpha:Bool = parameters.premultipliedAlpha != null ? parameters.premultipliedAlpha : true;
        var preserveDrawingBuffer:Bool = parameters.preserveDrawingBuffer != null ? parameters.preserveDrawingBuffer : false;
        var powerPreference:String = parameters.powerPreference != null ? parameters.powerPreference : "default";
        var failIfMajorPerformanceCaveat:Bool = parameters.failIfMajorPerformanceCaveat != null ? parameters.failIfMajorPerformanceCaveat : false;

        this.isWebGLRenderer = true;

        if (context !== null) {
            if (Std.is(context, js.html.WebGLRenderingContext)) {
                throw new js.Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");
            }

            _alpha = context.getContextAttributes().alpha;
        } else {
            _alpha = alpha;
        }

        uintClearColor = new js.html.Uint32Array(4);
        intClearColor = new js.html.Int32Array(4);

        currentRenderList = null;
        currentRenderState = null;

        renderListStack = [];
        renderStateStack = [];

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

        _gl = context;

        try {
            var contextAttributes:Dynamic = {
                alpha: true,
                depth: depth,
                stencil: stencil,
                antialias: antialias,
                premultipliedAlpha: premultipliedAlpha,
                preserveDrawingBuffer: preserveDrawingBuffer,
                powerPreference: powerPreference,
                failIfMajorPerformanceCaveat: failIfMajorPerformanceCaveat,
            };

            if (canvas.hasOwnProperty("setAttribute")) {
                canvas.setAttribute("data-engine", "three.js r${REVISION}");
            }

            canvas.addEventListener("webglcontextlost", onContextLost, false);
            canvas.addEventListener("webglcontextrestored", onContextRestore, false);
            canvas.addEventListener("webglcontextcreationerror", onContextCreationError, false);

            if (_gl == null) {
                var contextName:String = "webgl2";

                _gl = canvas.getContext(contextName, contextAttributes);

                if (_gl == null) {
                    if (canvas.getContext(contextName)) {
                        throw new js.Error("Error creating WebGL context with your selected attributes.");
                    } else {
                        throw new js.Error("Error creating WebGL context.");
                    }
                }
            }
        } catch (error:Dynamic) {
            js.console.error("THREE.WebGLRenderer: " + error.message);
            throw error;
        }

        initGLContext();

        this.xr = new WebXRManager(this, _gl);
    }

    private function getTargetPixelRatio():Float {
        return _currentRenderTarget == null ? _pixelRatio : 1;
    }

    private function getContext(contextName:String, contextAttributes:Dynamic):Dynamic {
        return canvas.getContext(contextName, contextAttributes);
    }

    private function initGLContext() {
        extensions = new WebGLExtensions(_gl);
        extensions.init();

        utils = new WebGLUtils(_gl, extensions);

        capabilities = new WebGLCapabilities(_gl, extensions, parameters, utils);

        state = new WebGLState(_gl);

        info = new WebGLInfo(_gl);
        properties = new WebGLProperties();
        textures = new WebGLTextures(_gl, extensions, state, properties, capabilities, utils, info);
        cubemaps = new WebGLCubeMaps(this);
        cubeuvmaps = new WebGLCubeUVMaps(this);
        attributes = new WebGLAttributes(_gl);
        bindingStates = new WebGLBindingStates(_gl, attributes);
        geometries = new WebGLGeometries(_gl, attributes, info, bindingStates);
        objects = new WebGLObjects(_gl, geometries, attributes, info);
        morphtargets = new WebGLMorphtargets(_gl, capabilities, textures);
        clipping = new WebGLClipping(properties);
        programCache = new WebGLPrograms(this, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping);
        materials = new WebGLMaterials(this, properties);
        renderLists = new WebGLRenderLists();
        renderStates = new WebGLRenderStates(extensions);
        background = new WebGLBackground(this, cubemaps, cubeuvmaps, state, objects, _alpha, premultipliedAlpha);
        shadowMap = new WebGLShadowMap(this, objects, capabilities);
        uniformsGroups = new WebGLUniformsGroups(_gl, info, capabilities, state);

        bufferRenderer = new WebGLBufferRenderer(_gl, extensions, info);
        indexedBufferRenderer = new WebGLIndexedBufferRenderer(_gl, extensions, info);

        info.programs = programCache.programs;

        this.capabilities = capabilities;
        this.extensions = extensions;
        this.properties = properties;
        this.renderLists = renderLists;
        this.shadowMap = shadowMap;
        this.state = state;
        this.info = info;
    }

    // Public API methods will be added here based on the original JavaScript code
}