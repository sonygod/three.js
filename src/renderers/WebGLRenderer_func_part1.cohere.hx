import js.html.canvas.CanvasElement;
import js.html.canvas.OffscreenCanvas;
import js.html.event.Event;
import js.html.event.EventListener;
import js.html.window.Window;
import js.WebGLRenderingContext as GL;
import js.WebGL2RenderingContext as GL2;

class WebGLRenderer {
    public isWebGLRenderer:Bool;
    public domElement:CanvasElement;
    public debug:Debug;
    public autoClear:Bool;
    public autoClearColor:Bool;
    public autoClearDepth:Bool;
    public autoClearStencil:Bool;
    public sortObjects:Bool;
    public clippingPlanes:Array<ClippingPlane>;
    public localClippingEnabled:Bool;
    public _outputColorSpace:ColorSpace;
    public _useLegacyLights:Bool;
    public toneMapping:ToneMapping;
    public toneMappingExposure:Float;
    private _isContextLost:Bool;
    private _currentActiveCubeFace:Int;
    private _currentActiveMipmapLevel:Int;
    private _currentRenderTarget:WebGLRenderTarget;
    private _currentMaterialId:Int;
    private _currentCamera:Camera;
    private _currentViewport:Vector4;
    private _currentScissor:Vector4;
    private _currentScissorTest:ScissorTest;
    private _currentClearColor:Color;
    private _currentClearAlpha:Float;
    private _width:Int;
    private _height:Int;
    private _pixelRatio:Float;
    private _opaqueSort:OpaqueSort;
    private _transparentSort:TransparentSort;
    private _viewport:Vector4;
    private _scissor:Vector4;
    private _scissorTest:Bool;
    private _frustum:Frustum;
    private _clippingEnabled:Bool;
    private _localClippingEnabled:Bool;
    private _projScreenMatrix:Matrix4;
    private _vector3:Vector3;
    private _emptyScene:EmptyScene;
    private _gl:GL;
    private extensions:WebGLExtensions;
    private utils:WebGLUtils;
    private capabilities:WebGLCapabilities;
    private state:WebGLState;
    private info:WebGLInfo;
    private properties:WebGLProperties;
    private textures:WebGLTextures;
    private cubemaps:WebGLCubeMaps;
    private cubeuvmaps:WebGLCubeUVMaps;
    private attributes:WebGLAttributes;
    private bindingStates:WebGLBindingStates;
    private geometries:WebGLGeometries;
    private objects:WebGLObjects;
    private morphtargets:WebGLMorphtargets;
    private clipping:WebGLClipping;
    private programCache:WebGLPrograms;
    private materials:WebGLMaterials;
    private renderLists:WebGLRenderLists;
    private renderStates:WebGLRenderStates;
    private background:WebGLBackground;
    private shadowMap:WebGLShadowMap;
    private uniformsGroups:WebGLUniformsGroups;
    private bufferRenderer:WebGLBufferRenderer;
    private indexedBufferRenderer:WebGLIndexedBufferRenderer;
    public xr:WebXRManager;

    public function new(parameters:Dynamic) {
        var canvas = parameters.canvas ?? createCanvasElement();
        var context = parameters.context ?? null;
        var depth = parameters.depth ?? true;
        var stencil = parameters.stencil ?? false;
        var alpha = parameters.alpha ?? false;
        var antialias = parameters.antialias ?? false;
        var premultipliedAlpha = parameters.premultipliedAlpha ?? true;
        var preserveDrawingBuffer = parameters.preserveDrawingBuffer ?? false;
        var powerPreference = parameters.powerPreference ?? 'default';
        var failIfMajorPerformanceCaveat = parameters.failIfMajorPerformanceCaveat ?? false;

        this.isWebGLRenderer = true;
        var _alpha = if (context != null) {
            if (context instanceof GL || context instanceof GL2) {
                throw "THREE.WebGLRenderer: WebGL 1 is not supported.";
            }
            context.getContextAttributes().alpha;
        } else {
            alpha;
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

        _emptyScene = {
            background: null,
            fog: null,
            environment: null,
            overrideMaterial: null,
            isScene: true
        };

        function getTargetPixelRatio() return if (_currentRenderTarget == null) _pixelRatio else 1;

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
                canvas.setAttribute('data-engine', 'three.js');
            }

            canvas.addEventListener('webglcontextlost', onContextLost);
            canvas.addEventListener('webglcontextrestored', onContextRestore);
            canvas.addEventListener('webglcontextcreationerror', onContextCreationError);

            if (_gl == null) {
                var contextName = 'webgl2';
                _gl = getContext(contextName, contextAttributes);

                if (_gl == null) {
                    if (getContext(contextName) != null) {
                        throw 'Error creating WebGL context with your selected attributes.';
                    } else {
                        throw 'Error creating WebGL context.';
                    }
                }
            }

            function getContext(contextName, contextAttributes) {
                return canvas.getContext(contextName, contextAttributes);
            }
        } catch (error) {
            trace('THREE.WebGLRenderer: $error');
            throw error;
        }

        var extensions, capabilities, state, info;
        var properties, textures, cubemaps, cubeuvmaps, attributes, geometries, objects;
        var programCache, materials, renderLists, renderStates, clipping, shadowMap;

        var background, morphtargets, bufferRenderer, indexedBufferRenderer;

        var utils, bindingStates, uniformsGroups;

        function initGLContext() {
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

        initGLContext();

        xr = new WebXRManager(this, _gl);

        this.xr = xr;

        this.getContext = function() return _gl;

        this.getContextAttributes = function() return _gl.getContextAttributes();

        this.forceContextLoss = function() {
            var extension = extensions.get('WEBGL_lose_context');
            if (extension != null) extension.loseContext();
        };

        this.forceContextRestore = function() {
            var extension = extensions.get('WEBGL_lose_context');
            if (extension != null) extension.restoreContext();
        };

        this.getPixelRatio = function() return _pixelRatio;

        this.setPixelRatio = function(value) {
            if (value == null) return;

            _pixelRatio = value;

            this.setSize(_width, _height, false);
        };

        this.getSize = function(target) {
            return target.set(_width, _height);
        };

        this.setSize = function(width, height, updateStyle = true) {
            if (xr.isPresenting) {
                trace('THREE.WebGLRenderer: Can\'t change size while VR device is presenting.');
                return;
            }

            _width = width;
            _height = height;

            canvas.width = Std.int(width * _pixelRatio);
            canvas.height = Std.int(height * _pixelRatio);

            if (updateStyle) {
                canvas.style.width = width + 'px';
                canvas.style.height = height + 'px';
            }

            this.setViewport(0, 0, width, height);
        };

        this.getDrawingBufferSize = function(target) {
            return target.set(_width * _pixelRatio, _height * _pixelRatio).floor();
        };

        this.setDrawingBufferSize = function(width, height, pixelRatio) {
            _width = width;
            _height = height;

            _pixelRatio = pixelRatio;

            canvas.width = Std.int(width * pixelRatio);
            canvas.height = Std.int(height * pixelRatio);

            this.setViewport(0, 0, width, height);
        };

        this.getCurrentViewport = function(target) {
            return target.copy(_currentViewport);
        };

        this.getViewport = function(target) {
            return target.copy(_viewport);
        };

        this.setViewport = function(x, y, width, height) {
            if (x is Vector4) {
                _viewport.set(x.x, x.y, x.z, x.w);
            } else {
                _viewport.set(x, y, width, height);
            }

            state.viewport(_currentViewport.copy(_viewport).multiplyScalar(_pixelRatio).round());
        };

        this.getScissor = function(target) {
            return target.copy(_scissor);
        };

        this.setScissor = function(x, y, width, height) {
            if (x is Vector4) {
                _scissor.set(x.x, x.y, x.z, x.w);
            } else {
                _scissor.set(x, y, width, height);
            }

            state.scissor(_currentScissor.copy(_scissor).multiplyScalar(_pixelRatio).round());
        };

        this.getScissorTest = function() return _scissorTest;

        this.setScissorTest = function(boolean) {
            state.setScissorTest(_scissorTest = boolean);
        };

        this.setOpaqueSort = function(method) {
            _opaqueSort = method;
        };

        this.setTransparentSort = function(method) {
            _transparentSort = method;
        };

        // Clearing

        this.getClearColor = function(target) {
            return target.copy(background.getClearColor());
        };

        this.setClearColor = function() {
            background.setClearColor.apply(background, arguments);
        };

        this.getClearAlpha = function() {
            return background.getClearAlpha();
        };

        this.setClearAlpha = function() {
            background.setClearAlpha.apply(background, arguments);
        };

        this.clear = function(color = true, depth = true, stencil = true) {
            var bits = 0;

            if (color) {
                // check if we're trying to clear an integer target
                var isIntegerFormat = false;
                if (_currentRenderTarget != null) {
                    var targetFormat = _currentRenderTarget.texture.format;
                    isIntegerFormat = targetFormat == RGBAIntegerFormat ||
                        targetFormat == RGIntegerFormat ||
                        targetFormat == RedIntegerFormat;
                }

                // use the appropriate clear functions to clear the target if it's a signed
                // or unsigned integer target
                if (isIntegerFormat) {
                    var targetType = _currentRenderTarget.texture.type;
                    var isUnsignedType = targetType == UnsignedByteType ||
                        targetType == UnsignedIntType ||
                        targetType == UnsignedShortType ||
                        targetType == UnsignedInt248Type ||
                        targetType == UnsignedShort4444Type ||
                        targetType == UnsignedShort5551Type;