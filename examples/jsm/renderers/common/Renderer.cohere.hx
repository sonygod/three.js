import haxe.Resource;
import js.Browser;
import js.html.CanvasElement;
import js.html.HtmlElement;
import js.html.Window;
import js.node.buffer.Buffer;
import js.typed_arrays.ArrayBuffer;
import js.webgl.WebGLRenderingContext;

class Renderer {
    public var isRenderer:Bool;
    public var domElement:HtmlElement;
    public var backend:Dynamic;
    public var autoClear:Bool;
    public var autoClearColor:Bool;
    public var autoClearDepth:Bool;
    public var autoClearStencil:Bool;
    public var alpha:Bool;
    public var logarithmicDepthBuffer:Bool;
    public var outputColorSpace:Dynamic;
    public var toneMapping:Dynamic;
    public var toneMappingExposure:F32;
    public var sortObjects:Bool;
    public var depth:Bool;
    public var stencil:Bool;
    public var clippingPlanes:Array<Dynamic>;
    public var info:Dynamic;
    public var toneMappingNode:Dynamic;
    public var _pixelRatio:F32;
    public var _width:Int;
    public var _height:Int;
    public var _viewport:Dynamic;
    public var _scissor:Dynamic;
    public var _scissorTest:Bool;
    public var _attributes:Dynamic;
    public var _geometries:Dynamic;
    public var _nodes:Dynamic;
    public var _animation:Dynamic;
    public var _bindings:Dynamic;
    public var _objects:Dynamic;
    public var _pipelines:Dynamic;
    public var _renderLists:Dynamic;
    public var _renderContexts:Dynamic;
    public var _textures:Dynamic;
    public var _background:Dynamic;
    public var _currentRenderContext:Dynamic;
    public var _opaqueSort:Dynamic;
    public var _transparentSort:Dynamic;
    public var _frameBufferTarget:Dynamic;
    public var _clearColor:Dynamic;
    public var _clearDepth:F32;
    public var _clearStencil:Int;
    public var _renderTarget:Dynamic;
    public var _activeCubeFace:Int;
    public var _activeMipmapLevel:Int;
    public var _renderObjectFunction:Dynamic;
    public var _currentRenderObjectFunction:Dynamic;
    public var _handleObjectFunction:Dynamic;
    public var _initialized:Bool;
    public var _initPromise:Dynamic;
    public var _compilationPromises:Dynamic;
    public var shadowMap:Dynamic;
    public var xr:Dynamic;

    public function new(backend:Dynamic, ?parameters:Dynamic) {
        if (parameters == null) {
            parameters = { };
        }
        this.isRenderer = true;
        const { logarithmicDepthBuffer, alpha } = parameters;
        this.domElement = backend.getDomElement();
        this.backend = backend;
        this.autoClear = true;
        this.autoClearColor = true;
        this.autoClearDepth = true;
        this.autoClearStencil = true;
        this.alpha = alpha;
        this.logarithmicDepthBuffer = logarithmicDepthBuffer;
        this.outputColorSpace = js.Browser.window.SRGBColorSpace;
        this.toneMapping = js.Browser.window.NoToneMapping;
        this.toneMappingExposure = 1.0;
        this.sortObjects = true;
        this.depth = true;
        this.stencil = false;
        this.clippingPlanes = [];
        this.info = new Info();
        this.toneMappingNode = null;
        this._pixelRatio = 1;
        this._width = this.domElement.width;
        this._height = this.domElement.height;
        this._viewport = new js.Browser.window.Vector4(0, 0, this._width, this._height);
        this._scissor = new js.Browser.window.Vector4(0, 0, this._width, this._height);
        this._scissorTest = false;
        this._attributes = null;
        this._geometries = null;
        this._nodes = null;
        this._animation = null;
        this._bindings = null;
        this._objects = null;
        this._pipelines = null;
        this._renderLists = null;
        this._renderContexts = null;
        this._textures = null;
        this._background = null;
        this._currentRenderContext = null;
        this._opaqueSort = null;
        this._transparentSort = null;
        this._frameBufferTarget = null;
        const alphaClear = (this.alpha == true) ? 0 : 1;
        this._clearColor = new js.Browser.window.Color4(0, 0, 0, alphaClear);
        this._clearDepth = 1;
        this._clearStencil = 0;
        this._renderTarget = null;
        this._activeCubeFace = 0;
        this._activeMipmapLevel = 0;
        this._renderObjectFunction = null;
        this._currentRenderObjectFunction = null;
        this._handleObjectFunction = this._renderObjectDirect;
        this._initialized = false;
        this._initPromise = null;
        this._compilationPromises = null;
        this.shadowMap = {
            enabled: false,
            type: null
        };
        this.xr = {
            enabled: false
        };
    }

    public function init():Void {
        if (this._initialized) {
            throw new js.Error('Renderer: Backend has already been initialized.');
        }
        if (this._initPromise != null) {
            return this._initPromise;
        }
        this._initPromise = new haxe.Resource(async () -> {
            const backend = this.backend;
            try {
                await backend.init(this);
            } catch (_g) {
                const error = _g;
                reject(error);
                return;
            }
            this._nodes = new Nodes(this, backend);
            this._animation = new Animation(this._nodes, this.info);
            this._attributes = new Attributes(backend);
            this._background = new Background(this, this._nodes);
            this._geometries = new Geometries(this._attributes, this.info);
            this._textures = new Textures(this, backend, this.info);
            this._pipelines = new Pipelines(backend, this._nodes);
            this._bindings = new Bindings(backend, this._nodes, this._textures, this._attributes, this._pipelines, this.info);
            this._objects = new RenderObjects(this, this._nodes, this._geometries, this._pipelines, this._bindings, this.info);
            this._renderLists = new RenderLists();
            this._renderContexts = new RenderContexts();
            this._initialized = true;
            resolve();
        });
        return this._initPromise;
    }

    public function get coordinateSystem():Dynamic {
        return this.backend.coordinateSystem;
    }

    public async function compileAsync(scene:Dynamic, camera:Dynamic, ?targetScene:Dynamic):Void {
        if (!this._initialized) {
            await this.init();
        }
        const nodeFrame = this._nodes.nodeFrame;
        const previousRenderId = nodeFrame.renderId;
        const previousRenderContext = this._currentRenderContext;
        const previousRenderObjectFunction = this._currentRenderObjectFunction;
        const previousCompilationPromises = this._compilationPromises;
        const sceneRef = (scene.isScene == true) ? scene : _scene;
        if (targetScene == null) {
            targetScene = scene;
        }
        const renderTarget = this._renderTarget;
        const renderContext = this._renderContexts.get(targetScene, camera, renderTarget);
        const activeMipmapLevel = this._activeMipmapLevel;
        const compilationPromises = [];
        this._currentRenderContext = renderContext;
        this._currentRenderObjectFunction = this.renderObject;
        this._handleObjectFunction = this._createObjectPipeline;
        this._compilationPromises = compilationPromises;
        nodeFrame.renderId++;
        nodeFrame.update();
        renderContext.depth = this.depth;
        renderContext.stencil = this.stencil;
        if (!renderContext.clippingContext) {
            renderContext.clippingContext = new ClippingContext();
        }
        renderContext.clippingContext.updateGlobal(this, camera);
        sceneRef.onBeforeRender(this, scene, camera, renderTarget);
        const renderList = this._renderLists.get(scene, camera);
        renderList.begin();
        this._projectObject(scene, camera, 0, renderList);
        if (targetScene != scene) {
            targetScene.traverseVisible((object) -> {
                if (object.isLight && object.layers.test(camera.layers)) {
                    renderList.pushLight(object);
                }
            });
        }
        renderList.finish();
        if (renderTarget != null) {
            this._textures.updateRenderTarget(renderTarget, activeMipmapLevel);
            const renderTargetData = this._textures.get(renderTarget);
            renderContext.textures = renderTargetData.textures;
            renderContext.depthTexture = renderTargetData.depthTexture;
        } else {
            renderContext.textures = null;
            renderContext.depthTexture = null;
        }
        this._nodes.updateScene(sceneRef);
        this._background.update(sceneRef, renderList, renderContext);
        const opaqueObjects = renderList.opaque;
        const transparentObjects = renderList.transparent;
        const lightsNode = renderList.lightsNode;
        if (opaqueObjects.length > 0) {
            this._renderObjects(opaqueObjects, camera, sceneRef, lightsNode);
        }
        if (transparentObjects.length > 0) {
            this._renderObjects(transparentObjects, camera, sceneRef, lightsNode);
        }
        nodeFrame.renderId = previousRenderId;
        this._currentRenderContext = previousRenderContext;
        this._currentRenderObjectFunction = previousRenderObjectFunction;
        this._compilationPromises = previousCompilationPromises;
        this._handleObjectFunction = this._renderObjectDirect;
        await Promise.all(compilationPromises);
    }

    public async function renderAsync(scene:Dynamic, camera:Dynamic):Dynamic {
        if (!this._initialized) {
            await this.init();
        }
        const renderContext = this._renderScene(scene, camera);
        await this.backend.resolveTimestampAsync(renderContext, 'render');
        return renderContext;
    }

    public function render(scene:Dynamic, camera:Dynamic):Dynamic {
        if (!this._initialized) {
            js.Browser.console.warn('THREE.Renderer: .render() called before the backend is initialized. Try using .renderAsync() instead.');
            return this.renderAsync(scene, camera);
        }
        return this._renderScene(scene, camera);
    }

    public function _getFrameBufferTarget():Dynamic {
        const { currentColorSpace } = this;
        const useToneMapping = (this._renderTarget == null) && ((this.toneMapping != js.Browser.window.NoToneMapping) || (this.toneMappingNode != null));
        const useColorSpace = (currentColorSpace != js.Browser.window.LinearSRGBColorSpace) && (currentColorSpace != js.Browser.window.NoColorSpace);
        if (!useToneMapping && !useColorSpace) {
            return null;
        }
        const { width, height } = this.getDrawingBufferSize(_drawingBufferSize);
        const { depth, stencil } = this;
        let frameBufferTarget = this._frameBufferTarget;
        if (frameBufferTarget == null) {
            frameBufferTarget = new RenderTarget(width, height, {
                depthBuffer: depth,
                stencilBuffer: stencil,
                type: js.Browser.window.HalfFloatType,
                format: js.Browser.window.RGBAFormat,
                colorSpace: js.Browser.window.LinearSRGBColorSpace,
                generateMipmaps: false,
                minFilter: js.Browser.window.LinearFilter,
                magFilter: js.Browser.window.LinearFilter,
                samples: this.backend.parameters.antialias ? 4 : 0
            });
            frameBufferTarget.isPostProcessingRenderTarget = true;
            this._frameBufferTarget = frameBufferTarget;
        }
        frameBufferTarget.depthBuffer = depth;
        frameBufferTarget.stencilBuffer = stencil;
        frameBufferTarget.setSize(width, height);
        frameBufferTarget.viewport.copy(this._viewport);
        frameBufferTarget.scissor.copy(this._scissor);
        frameBufferTarget.viewport.multiplyScalar(this._pixelRatio);
        frameBufferTarget.scissor.multiplyScalar(this._pixelRatio);
        frameBufferTarget.scissorTest = this._scissorTest;
        return frameBufferTarget;
    }

    public function _renderScene(scene:Dynamic, camera:Dynamic, ?useFrameBufferTarget:Bool):Dynamic {
        const frameBufferTarget = (useFrameBufferTarget == true) ? this._getFrameBufferTarget() : null;
        const nodeFrame = this._nodes.nodeFrame;
        const previousRenderId = nodeFrame.renderId;
        const previousRenderContext = this._currentRenderContext;
        const previousRenderObjectFunction = this._currentRenderObjectFunction;
        const sceneRef = (scene.isScene == true) ? scene : _scene;
        const outputRenderTarget = this._renderTarget;
        const activeCubeFace = this._activeCubeFace;
        const activeMipmapLevel = this._activeMipmapLevel;
        let renderTarget;
        if (frameBufferTarget != null) {
            renderTarget = frameBufferTarget;
            this.setRenderTarget(renderTarget);
        } else {
            renderTarget = outputRenderTarget;
        }
        const renderContext = this._renderContexts.get(scene, camera, renderTarget);
        this._currentRenderContext = renderContext;
        this._currentRenderObjectFunction = (this._renderObjectFunction != null) ? this._renderObjectFunction : this.renderObject;
        this.info.calls++;
        this.info.render.calls++;
        nodeFrame.renderId = this.info.calls;
        const coordinateSystem = this.coordinateSystem;
        if (camera.coordinateSystem != coordinateSystem) {
            camera.coordinateSystem = coordinateSystem;
            camera.updateProjectionMatrix();
        }
        if (scene.matrixWorldAutoUpdate == true) {
            scene.updateMatrixWorld();
        }
        if ((camera.parent == null) && (camera.matrixWorldAutoUpdate == true)) {
            camera.updateMatrixWorld();
        }
        let viewport = this._viewport;
        let scissor = this._scissor;
        let pixelRatio = this._pixelRatio;
        if (renderTarget != null) {
            viewport = renderTarget.viewport;
            scissor = renderTarget.scissor;
            pixelRatio = 1;
        }
        this.getDrawingBufferSize(_drawingBufferSize);
        _screen.set(0, 0, _drawingBufferSize.width, _drawingBufferSize.height);
        const minDepth = (viewport.minDepth == null) ? 0 : viewport.minDepth;
        const maxDepth = (viewport.maxDepth == null) ? 1 : viewport.maxDepth;
        renderContext.viewportValue.copy(viewport).multiplyScalar(pixelRatio).floor();
        renderContext.viewportValue.width >>= activeMipmapLevel;
        renderContext.viewportValue.height >>= activeMipmapLevel;
        renderContext.viewportValue.minDepth = minDepth;
        renderContext.viewportValue.maxDepth = maxDepth;
        renderContext.viewport = renderContext.viewportValue.equals(_screen) == false;
        renderContext.scissorValue.copy(scissor).multiplyScalar(pixelRatio).floor();
        renderContext.scissor = (this._scissorTest && renderContext.scissorValue.equals(_screen) == false);
        renderContext.scissorValue.width >>= activeMipmapLevel;
        renderContext.scissorValue.height >>= activeMipmapLevel;
        if (!renderContext.clippingContext) {
            renderContext.clippingContext = new ClippingContext();
        }
        renderContext.clippingContext.updateGlobal(this, camera);
        sceneRef.onBeforeRender(this, scene, camera, renderTarget);
        _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
        _frustum.setFromProjectionMatrix(_projScreenMatrix, coordinateSystem);
        const renderList = this._renderLists.get(scene, camera);
        renderList.begin();
        this._projectObject(scene, camera, 0, renderList);
        renderList.finish();
        if (this.sortObjects == true) {
            renderList.sort(this._opaqueSort, this._transparentSort);
        }
        if (renderTarget != null) {
            this._textures.updateRenderTarget(renderTarget, activeMipmapLevel);
            const renderTargetData = this._textures.get(renderTarget);
            renderContext.textures = renderTargetData.textures;
            renderContext.depthTexture = renderTargetData.depthTexture;
            renderContext.width = renderTargetData.width;
            renderContext.height = renderTargetData.height;
            renderContext.renderTarget = renderTarget;
            renderContext.depth = renderTarget.depthBuffer;
            renderContext.stencil = renderTarget.stencilBuffer;
        } else {
            renderContext.textures = null;
            renderContext.depthTexture = null;
            renderContext.width = this.domElement.width;
            renderContext.height = this.domElement.height;
            renderContext.depth = this.depth;
            renderContext.stencil = this.stencil;
        }
        renderContext.width >>= activeMipmapLevel;
        renderContext.height >>= activeMipmapLevel;
        renderContext.activeCubeFace = activeCubeFace;
        renderContext.activeMipmapLevel = activeMipmapLevel;
        renderContext.occlusionQueryCount = renderList.occlusionQueryCount;
        this._nodes.updateScene(sceneRef);
        this._background.update(sceneRef, renderList, renderContext);
        this.backend.beginRender(renderContext);
        const opaqueObjects = renderList.opaque;
        const transparentObjects = renderList.transparent;
        const lightsNode = renderList.lightsNode;
        if (opaqueObjects.length > 0) {
            this._renderObjects(opaqueObjects, camera, sceneRef, lightsNode);
        }
        if (transparentObjects.length > 0) {