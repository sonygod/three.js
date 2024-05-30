import three.js.src.constants.REVISION;
import three.js.src.constants.BackSide;
import three.js.src.constants.FrontSide;
import three.js.src.constants.DoubleSide;
import three.js.src.constants.HalfFloatType;
import three.js.src.constants.UnsignedByteType;
import three.js.src.constants.NoToneMapping;
import three.js.src.constants.LinearMipmapLinearFilter;
import three.js.src.constants.SRGBColorSpace;
import three.js.src.constants.LinearSRGBColorSpace;
import three.js.src.constants.RGBAIntegerFormat;
import three.js.src.constants.RGIntegerFormat;
import three.js.src.constants.RedIntegerFormat;
import three.js.src.constants.UnsignedIntType;
import three.js.src.constants.UnsignedShortType;
import three.js.src.constants.UnsignedInt248Type;
import three.js.src.constants.UnsignedShort4444Type;
import three.js.src.constants.UnsignedShort5551Type;
import three.js.src.constants.WebGLCoordinateSystem;
import three.js.src.constants.DisplayP3ColorSpace;
import three.js.src.constants.LinearDisplayP3ColorSpace;
import three.js.src.math.Color;
import three.js.src.math.Frustum;
import three.js.src.math.Matrix4;
import three.js.src.math.Vector3;
import three.js.src.math.Vector4;
import three.js.src.renderers.webgl.WebGLAnimation;
import three.js.src.renderers.webgl.WebGLAttributes;
import three.js.src.renderers.webgl.WebGLBackground;
import three.js.src.renderers.webgl.WebGLBindingStates;
import three.js.src.renderers.webgl.WebGLBufferRenderer;
import three.js.src.renderers.webgl.WebGLCapabilities;
import three.js.src.renderers.webgl.WebGLClipping;
import three.js.src.renderers.webgl.WebGLCubeMaps;
import three.js.src.renderers.webgl.WebGLCubeUVMaps;
import three.js.src.renderers.webgl.WebGLExtensions;
import three.js.src.renderers.webgl.WebGLGeometries;
import three.js.src.renderers.webgl.WebGLIndexedBufferRenderer;
import three.js.src.renderers.webgl.WebGLInfo;
import three.js.src.renderers.webgl.WebGLMorphtargets;
import three.js.src.renderers.webgl.WebGLObjects;
import three.js.src.renderers.webgl.WebGLPrograms;
import three.js.src.renderers.webgl.WebGLProperties;
import three.js.src.renderers.webgl.WebGLRenderLists;
import three.js.src.renderers.webgl.WebGLRenderStates;
import three.js.src.renderers.WebGLRenderTarget;
import three.js.src.renderers.webgl.WebGLShadowMap;
import three.js.src.renderers.webgl.WebGLState;
import three.js.src.renderers.webgl.WebGLTextures;
import three.js.src.renderers.webgl.WebGLUniforms;
import three.js.src.renderers.webgl.WebGLUtils;
import three.js.src.webxr.WebXRManager;
import three.js.src.renderers.webgl.WebGLMaterials;
import three.js.src.renderers.webgl.WebGLUniformsGroups;
import three.js.src.utils.createCanvasElement;
import three.js.src.utils.probeAsync;
import three.js.src.math.ColorManagement;

class WebGLRenderer {
    public var isWebGLRenderer:Bool = true;
    public var domElement:HtmlElement;
    public var debug:DebugConfig;

    public var autoClear:Bool = true;
    public var autoClearColor:Bool = true;
    public var autoClearDepth:Bool = true;
    public var autoClearStencil:Bool = true;

    public var sortObjects:Bool = true;

    public var clippingPlanes:Array<Dynamic>;
    public var localClippingEnabled:Bool = false;

    private var _outputColorSpace:Int = SRGBColorSpace;
    private var _useLegacyLights:Bool = false;

    public var toneMapping:Int = NoToneMapping;
    public var toneMappingExposure:Float = 1.0;

    private var _isContextLost:Bool = false;

    private var _currentActiveCubeFace:Int = 0;
    private var _currentActiveMipmapLevel:Int = 0;
    private var _currentRenderTarget:WebGLRenderTarget;
    private var _currentMaterialId:Int = -1;

    private var _currentCamera:Camera;

    private var _currentViewport:Vector4;
    private var _currentScissor:Vector4;
    private var _currentScissorTest:Bool;

    private var _currentClearColor:Color;
    private var _currentClearAlpha:Float;

    private var _width:Int;
    private var _height:Int;

    private var _pixelRatio:Float = 1;
    private var _opaqueSort:Dynamic;
    private var _transparentSort:Dynamic;

    private var _viewport:Vector4;
    private var _scissor:Vector4;
    private var _scissorTest:Bool = false;

    private var _frustum:Frustum;

    private var _clippingEnabled:Bool = false;
    private var _localClippingEnabled:Bool = false;

    private var _projScreenMatrix:Matrix4;

    private var _vector3:Vector3;

    private var _emptyScene:Dynamic;

    private var _gl:WebGLRenderingContext;

    public function new(parameters:Dynamic = {}) {
        const {
            canvas = createCanvasElement(),
            context = null,
            depth = true,
            stencil = false,
            alpha = false,
            antialias = false,
            premultipliedAlpha = true,
            preserveDrawingBuffer = false,
            powerPreference = 'default',
            failIfMajorPerformanceCaveat = false,
        } = parameters;

        this.domElement = canvas;

        this.debug = {
            checkShaderErrors: true,
            onShaderError: null
        };

        _currentClearColor = new Color(0x000000);

        _width = canvas.width;
        _height = canvas.height;

        _pixelRatio = 1;

        _viewport = new Vector4(0, 0, _width, _height);
        _scissor = new Vector4(0, 0, _width, _height);

        _frustum = new Frustum();

        _projScreenMatrix = new Matrix4();

        _vector3 = new Vector3();

        _emptyScene = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

        _currentViewport = new Vector4();
        _currentScissor = new Vector4();

        _currentClearColor = new Color(0x000000);

        _currentRenderTarget = null;

        _currentCamera = null;

        _currentMaterialId = -1;

        _clippingEnabled = false;
        _localClippingEnabled = false;

        _gl = context;

        initGLContext();

        const xr = new WebXRManager(this, _gl);

        this.xr = xr;
    }

    public function getContext():WebGLRenderingContext {
        return _gl;
    }

    public function getContextAttributes():Dynamic {
        return _gl.getContextAttributes();
    }

    public function forceContextLoss():Void {
        const extension = extensions.get('WEBGL_lose_context');
        if (extension) extension.loseContext();
    }

    public function forceContextRestore():Void {
        const extension = extensions.get('WEBGL_lose_context');
        if (extension) extension.restoreContext();
    }

    public function getPixelRatio():Float {
        return _pixelRatio;
    }

    public function setPixelRatio(value:Float):Void {
        if (value === undefined) return;

        _pixelRatio = value;

        this.setSize(_width, _height, false);
    }

    public function getSize(target:Vector2):Vector2 {
        return target.set(_width, _height);
    }

    public function setSize(width:Int, height:Int, updateStyle:Bool = true):Void {
        if (xr.isPresenting) {
            console.warn('THREE.WebGLRenderer: Can\'t change size while VR device is presenting.');
            return;
        }

        _width = width;
        _height = height;

        canvas.width = Math.floor(width * _pixelRatio);
        canvas.height = Math.floor(height * _pixelRatio);

        if (updateStyle === true) {
            canvas.style.width = width + 'px';
            canvas.style.height = height + 'px';
        }

        this.setViewport(0, 0, width, height);
    }

    public function getDrawingBufferSize(target:Vector2):Vector2 {
        return target.set(_width * _pixelRatio, _height * _pixelRatio).floor();
    }

    public function setDrawingBufferSize(width:Int, height:Int, pixelRatio:Float):Void {
        _width = width;
        _height = height;

        _pixelRatio = pixelRatio;

        canvas.width = Math.floor(width * pixelRatio);
        canvas.height = Math.floor(height * pixelRatio);

        this.setViewport(0, 0, width, height);
    }

    public function getCurrentViewport(target:Vector4):Vector4 {
        return target.copy(_currentViewport);
    }

    public function getViewport(target:Vector4):Vector4 {
        return target.copy(_viewport);
    }

    public function setViewport(x:Int, y:Int, width:Int, height:Int):Void {
        if (x.isVector4) {
            _viewport.set(x.x, x.y, x.z, x.w);
        } else {
            _viewport.set(x, y, width, height);
        }

        state.viewport(_currentViewport.copy(_viewport).multiplyScalar(_pixelRatio).round());
    }

    public function getScissor(target:Vector4):Vector4 {
        return target.copy(_scissor);
    }

    public function setScissor(x:Int, y:Int, width:Int, height:Int):Void {
        if (x.isVector4) {
            _scissor.set(x.x, x.y, x.z, x.w);
        } else {
            _scissor.set(x, y, width, height);
        }

        state.scissor(_currentScissor.copy(_scissor).multiplyScalar(_pixelRatio).round());
    }

    public function getScissorTest():Bool {
        return _scissorTest;
    }

    public function setScissorTest(boolean:Bool):Void {
        state.setScissorTest(_scissorTest = boolean);
    }

    public function setOpaqueSort(method:Dynamic):Void {
        _opaqueSort = method;
    }

    public function setTransparentSort(method:Dynamic):Void {
        _transparentSort = method;
    }

    public function getClearColor(target:Color):Color {
        return target.copy(background.getClearColor());
    }

    public function setClearColor():Void {
        background.setClearColor.apply(background, arguments);
    }

    public function getClearAlpha():Float {
        return background.getClearAlpha();
    }

    public function setClearAlpha():Void {
        background.setClearAlpha.apply(background, arguments);
    }

    public function clear(color:Bool = true, depth:Bool = true, stencil:Bool = true):Void {
        let bits = 0;

        if (color) {
            // check if we're trying to clear an integer target
            let isIntegerFormat:Bool = false;
            if (_currentRenderTarget !== null) {
                const targetFormat = _currentRenderTarget.texture.format;
                isIntegerFormat = targetFormat === RGBAIntegerFormat ||
                    targetFormat === RGIntegerFormat ||
                    targetFormat === RedIntegerFormat;
            }

            // use the appropriate clear functions to clear the target if it's a signed
            // or unsigned integer target
            if (isIntegerFormat) {
                const targetType = _currentRenderTarget.texture.type;
                const isUnsignedType = targetType === UnsignedByteType ||
                    targetType === UnsignedIntType ||
                    targetType === UnsignedShortType ||
                    targetType === UnsignedInt248Type ||
                    targetType === UnsignedShort4444Type ||
                    targetType === UnsignedShort5551Type;

                // ...
            }
        }
    }

    private function initGLContext():Void {
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
}