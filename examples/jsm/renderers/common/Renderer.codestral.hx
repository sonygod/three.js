import Animation from './Animation';
import RenderObjects from './RenderObjects';
import Attributes from './Attributes';
import Geometries from './Geometries';
import Info from './Info';
import Pipelines from './Pipelines';
import Bindings from './Bindings';
import RenderLists from './RenderLists';
import RenderContexts from './RenderContexts';
import Textures from './Textures';
import Background from './Background';
import Nodes from './nodes/Nodes';
import Color4 from './Color4';
import ClippingContext from './ClippingContext';
import { Scene, Frustum, Matrix4, Vector2, Vector3, Vector4, DoubleSide, BackSide, FrontSide, SRGBColorSpace, NoColorSpace, NoToneMapping, LinearFilter, LinearSRGBColorSpace, RenderTarget, HalfFloatType, RGBAFormat } from 'three';
import { NodeMaterial } from '../../nodes/Nodes';
import QuadMesh from '../../objects/QuadMesh';

var _scene = new Scene();
var _drawingBufferSize = new Vector2();
var _screen = new Vector4();
var _frustum = new Frustum();
var _projScreenMatrix = new Matrix4();
var _vector3 = new Vector3();
var _quad = new QuadMesh( new NodeMaterial() );

class Renderer {

	var backend: any;
	var parameters: Dynamic;
	var isRenderer: Bool;
	var logarithmicDepthBuffer: Bool;
	var alpha: Bool;
	var domElement: any;
	var autoClear: Bool;
	var autoClearColor: Bool;
	var autoClearDepth: Bool;
	var autoClearStencil: Bool;
	var outputColorSpace: Int;
	var toneMapping: Int;
	var toneMappingExposure: Float;
	var sortObjects: Bool;
	var depth: Bool;
	var stencil: Bool;
	var clippingPlanes: Array<any>;
	var info: Info;
	var toneMappingNode: any;
	var _pixelRatio: Float;
	var _width: Int;
	var _height: Int;
	var _viewport: Vector4;
	var _scissor: Vector4;
	var _scissorTest: Bool;
	var _attributes: Attributes;
	var _geometries: Geometries;
	var _nodes: Nodes;
	var _animation: Animation;
	var _bindings: Bindings;
	var _objects: RenderObjects;
	var _pipelines: Pipelines;
	var _renderLists: RenderLists;
	var _renderContexts: RenderContexts;
	var _textures: Textures;
	var _background: Background;
	var _currentRenderContext: any;
	var _opaqueSort: any;
	var _transparentSort: any;
	var _frameBufferTarget: RenderTarget;
	var _clearColor: Color4;
	var _clearDepth: Float;
	var _clearStencil: Int;
	var _renderTarget: RenderTarget;
	var _activeCubeFace: Int;
	var _activeMipmapLevel: Int;
	var _renderObjectFunction: any;
	var _currentRenderObjectFunction: any;
	var _handleObjectFunction: any;
	var _initialized: Bool;
	var _initPromise: Promise<Void>;
	var _compilationPromises: Array<Promise<Void>>;
	var shadowMap: Dynamic;
	var xr: Dynamic;

	public function new(backend: any, parameters: Dynamic = {}) {
		this.isRenderer = true;

		this.logarithmicDepthBuffer = Std.isOfType(parameters.logarithmicDepthBuffer, Bool) ? parameters.logarithmicDepthBuffer : false;
		this.alpha = Std.isOfType(parameters.alpha, Bool) ? parameters.alpha : true;

		this.domElement = backend.getDomElement();
		this.backend = backend;

		this.autoClear = true;
		this.autoClearColor = true;
		this.autoClearDepth = true;
		this.autoClearStencil = true;

		this.outputColorSpace = SRGBColorSpace;
		this.toneMapping = NoToneMapping;
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

		this._viewport = new Vector4(0, 0, this._width, this._height);
		this._scissor = new Vector4(0, 0, this._width, this._height);
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

		var alphaClear = this.alpha ? 0 : 1;

		this._clearColor = new Color4(0, 0, 0, alphaClear);
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

	public async function init(): Promise<Void> {
		if (this._initialized) {
			throw new Error("Renderer: Backend has already been initialized.");
		}

		if (this._initPromise != null) {
			return this._initPromise;
		}

		this._initPromise = new Promise(async (resolve: Void -> Void, reject: Dynamic -> Void) => {
			var backend = this.backend;

			try {
				await backend.init(this);
			} catch (error: Dynamic) {
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

	public function get coordinateSystem(): Int {
		return this.backend.coordinateSystem;
	}

	public async function compileAsync(scene: Scene, camera: any, targetScene: Scene = null): Promise<Void> {
		if (!this._initialized) await this.init();

		var previousRenderId = this._nodes.nodeFrame.renderId;
		var previousRenderContext = this._currentRenderContext;
		var previousRenderObjectFunction = this._currentRenderObjectFunction;
		var previousCompilationPromises = this._compilationPromises;

		var sceneRef = scene.isScene == true ? scene : _scene;

		if (targetScene == null) targetScene = scene;

		var renderTarget = this._renderTarget;
		var renderContext = this._renderContexts.get(targetScene, camera, renderTarget);
		var activeMipmapLevel = this._activeMipmapLevel;

		var compilationPromises = [];

		this._currentRenderContext = renderContext;
		this._currentRenderObjectFunction = this.renderObject;

		this._handleObjectFunction = this._createObjectPipeline;

		this._compilationPromises = compilationPromises;

		this._nodes.nodeFrame.renderId++;

		this._nodes.nodeFrame.update();

		renderContext.depth = this.depth;
		renderContext.stencil = this.stencil;

		if (!renderContext.clippingContext) renderContext.clippingContext = new ClippingContext();
		renderContext.clippingContext.updateGlobal(this, camera);

		sceneRef.onBeforeRender(this, scene, camera, renderTarget);

		var renderList = this._renderLists.get(scene, camera);
		renderList.begin();

		this._projectObject(scene, camera, 0, renderList);

		if (targetScene != scene) {
			targetScene.traverseVisible(function (object) {
				if (object.isLight && object.layers.test(camera.layers)) {
					renderList.pushLight(object);
				}
			});
		}

		renderList.finish();

		if (renderTarget != null) {
			this._textures.updateRenderTarget(renderTarget, activeMipmapLevel);

			var renderTargetData = this._textures.get(renderTarget);

			renderContext.textures = renderTargetData.textures;
			renderContext.depthTexture = renderTargetData.depthTexture;
		} else {
			renderContext.textures = null;
			renderContext.depthTexture = null;
		}

		this._nodes.updateScene(sceneRef);

		this._background.update(sceneRef, renderList, renderContext);

		var opaqueObjects = renderList.opaque;
		var transparentObjects = renderList.transparent;
		var lightsNode = renderList.lightsNode;

		if (opaqueObjects.length > 0) this._renderObjects(opaqueObjects, camera, sceneRef, lightsNode);
		if (transparentObjects.length > 0) this._renderObjects(transparentObjects, camera, sceneRef, lightsNode);

		this._nodes.nodeFrame.renderId = previousRenderId;

		this._currentRenderContext = previousRenderContext;
		this._currentRenderObjectFunction = previousRenderObjectFunction;
		this._compilationPromises = previousCompilationPromises;

		this._handleObjectFunction = this._renderObjectDirect;

		await Promise.all(compilationPromises);
	}

	public async function renderAsync(scene: Scene, camera: any): Promise<Void> {
		if (!this._initialized) await this.init();

		var renderContext = this._renderScene(scene, camera);

		await this.backend.resolveTimestampAsync(renderContext, 'render');
	}

	public function render(scene: Scene, camera: any): Void {
		if (!this._initialized) {
			console.warn("THREE.Renderer: .render() called before the backend is initialized. Try using .renderAsync() instead.");

			return this.renderAsync(scene, camera);
		}

		this._renderScene(scene, camera);
	}

	public function _getFrameBufferTarget(): RenderTarget {
		var currentColorSpace = this.currentColorSpace;

		var useToneMapping = this._renderTarget == null && (this.toneMapping != NoToneMapping || this.toneMappingNode != null);
		var useColorSpace = currentColorSpace != LinearSRGBColorSpace && currentColorSpace != NoColorSpace;

		if (useToneMapping == false && useColorSpace == false) return null;

		var width = this.getDrawingBufferSize(_drawingBufferSize).x;
		var height = this.getDrawingBufferSize(_drawingBufferSize).y;
		var depth = this.depth;
		var stencil = this.stencil;

		if (this._frameBufferTarget == null) {
			this._frameBufferTarget = new RenderTarget(width, height, {
				depthBuffer: depth,
				stencilBuffer: stencil,
				type: HalfFloatType,
				format: RGBAFormat,
				colorSpace: LinearSRGBColorSpace,
				generateMipmaps: false,
				minFilter: LinearFilter,
				magFilter: LinearFilter,
				samples: this.backend.parameters.antialias ? 4 : 0
			});

			this._frameBufferTarget.isPostProcessingRenderTarget = true;
		}

		this._frameBufferTarget.depthBuffer = depth;
		this._frameBufferTarget.stencilBuffer = stencil;
		this._frameBufferTarget.setSize(width, height);
		this._frameBufferTarget.viewport.copy(this._viewport);
		this._frameBufferTarget.scissor.copy(this._scissor);
		this._frameBufferTarget.viewport.multiplyScalar(this._pixelRatio);
		this._frameBufferTarget.scissor.multiplyScalar(this._pixelRatio);
		this._frameBufferTarget.scissorTest = this._scissorTest;

		return this._frameBufferTarget;
	}

	public function _renderScene(scene: Scene, camera: any, useFrameBufferTarget: Bool = true): any {
		var frameBufferTarget = useFrameBufferTarget ? this._getFrameBufferTarget() : null;

		var previousRenderId = this._nodes.nodeFrame.renderId;
		var previousRenderContext = this._currentRenderContext;
		var previousRenderObjectFunction = this._currentRenderObjectFunction;

		var sceneRef = scene.isScene == true ? scene : _scene;

		var outputRenderTarget = this._renderTarget;

		var activeCubeFace = this._activeCubeFace;
		var activeMipmapLevel = this._activeMipmapLevel;

		var renderTarget = frameBufferTarget != null ? frameBufferTarget : outputRenderTarget;

		var renderContext = this._renderContexts.get(scene, camera, renderTarget);

		this._currentRenderContext = renderContext;
		this._currentRenderObjectFunction = this._renderObjectFunction != null ? this._renderObjectFunction : this.renderObject;

		this.info.calls++;
		this.info.render.calls++;

		this._nodes.nodeFrame.renderId = this.info.calls;

		var coordinateSystem = this.coordinateSystem;

		if (camera.coordinateSystem != coordinateSystem) {
			camera.coordinateSystem = coordinateSystem;

			camera.updateProjectionMatrix();
		}

		if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

		if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

		var viewport = this._viewport;
		var scissor = this._scissor;
		var pixelRatio = this._pixelRatio;

		if (renderTarget != null) {
			viewport = renderTarget.viewport;
			scissor = renderTarget.scissor;
			pixelRatio = 1;
		}

		this.getDrawingBufferSize(_drawingBufferSize);

		_screen.set(0, 0, _drawingBufferSize.width, _drawingBufferSize.height);

		var minDepth = viewport.minDepth != null ? viewport.minDepth : 0;
		var maxDepth = viewport.maxDepth != null ? viewport.maxDepth : 1;

		renderContext.viewportValue.copy(viewport).multiplyScalar(pixelRatio).floor();
		renderContext.viewportValue.width >>= activeMipmapLevel;
		renderContext.viewportValue.height >>= activeMipmapLevel;
		renderContext.viewportValue.minDepth = minDepth;
		renderContext.viewportValue.maxDepth = maxDepth;
		renderContext.viewport = !renderContext.viewportValue.equals(_screen);

		renderContext.scissorValue.copy(scissor).multiplyScalar(pixelRatio).floor();
		renderContext.scissor = this._scissorTest && !renderContext.scissorValue.equals(_screen);
		renderContext.scissorValue.width >>= activeMipmapLevel;
		renderContext.scissorValue.height >>= activeMipmapLevel;

		if (!renderContext.clippingContext) renderContext.clippingContext = new ClippingContext();
		renderContext.clippingContext.updateGlobal(this, camera);

		sceneRef.onBeforeRender(this, scene, camera, renderTarget);

		_projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
		_frustum.setFromProjectionMatrix(_projScreenMatrix, coordinateSystem);

		var renderList = this._renderLists.get(scene, camera);
		renderList.begin();

		this._projectObject(scene, camera, 0, renderList);

		renderList.finish();

		if (this.sortObjects) {
			renderList.sort(this._opaqueSort, this._transparentSort);
		}

		if (renderTarget != null) {
			this._textures.updateRenderTarget(renderTarget, activeMipmapLevel);

			var renderTargetData = this._textures.get(renderTarget);

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

		var opaqueObjects = renderList.opaque;
		var transparentObjects = renderList.transparent;
		var lightsNode = renderList.lightsNode;

		if (opaqueObjects.length > 0) this._renderObjects(opaqueObjects, camera, sceneRef, lightsNode);
		if (transparentObjects.length > 0) this._renderObjects(transparentObjects, camera, sceneRef, lightsNode);

		this.backend.finishRender(renderContext);

		this._nodes.nodeFrame.renderId = previousRenderId;

		this._currentRenderContext = previousRenderContext;
		this._currentRenderObjectFunction = previousRenderObjectFunction;

		if (frameBufferTarget != null) {
			this.setRenderTarget(outputRenderTarget, activeCubeFace, activeMipmapLevel);

			_quad.material.fragmentNode = this._nodes.getOutputNode(renderTarget.texture);

			this._renderScene(_quad, _quad.camera, false);
		}

		sceneRef.onAfterRender(this, scene, camera, renderTarget);

		return renderContext;
	}

	public function getMaxAnisotropy(): Int {
		return this.backend.getMaxAnisotropy();
	}

	public function getActiveCubeFace(): Int {
		return this._activeCubeFace;
	}

	public function getActiveMipmapLevel(): Int {
		return this._activeMipmapLevel;
	}

	public async function setAnimationLoop(callback: (time: Float) -> Void): Promise<Void> {
		if (!this._initialized) await this.init();

		this._animation.setAnimationLoop(callback);
	}

	public function getArrayBuffer(attribute: any): Array<Float> {
		console.warn("THREE.Renderer: getArrayBuffer() is deprecated. Use getArrayBufferAsync() instead.");

		return this.getArrayBufferAsync(attribute);
	}

	public async function getArrayBufferAsync(attribute: any): Promise<Array<Float>> {
		return await this.backend.getArrayBufferAsync(attribute);
	}

	public function getContext(): any {
		return this.backend.getContext();
	}

	public function getPixelRatio(): Float {
		return this._pixelRatio;
	}

	public function getDrawingBufferSize(target: Vector2): Vector2 {
		target.x = this._width * this._pixelRatio;
		target.y = this._height * this._pixelRatio;
		target.floor();
		return target;
	}

	public function getSize(target: Vector2): Vector2 {
		target.x = this._width;
		target.y = this._height;
		return target;
	}

	public function setPixelRatio(value: Float = 1): Void {
		this._pixelRatio = value;

		this.setSize(this._width, this._height, false);
	}

	public function setDrawingBufferSize(width: Int, height: Int, pixelRatio: Float): Void {
		this._width = width;
		this._height = height;

		this._pixelRatio = pixelRatio;

		this.domElement.width = (width * pixelRatio) | 0;
		this.domElement.height = (height * pixelRatio) | 0;

		this.setViewport(0, 0, width, height);

		if (this._initialized) this.backend.updateSize();
	}

	public function setSize(width: Int, height: Int, updateStyle: Bool = true): Void {
		this._width = width;
		this._height = height;

		this.domElement.width = (width * this._pixelRatio) | 0;
		this.domElement.height = (height * this._pixelRatio) | 0;

		if (updateStyle) {
			this.domElement.style.width = width + "px";
			this.domElement.style.height = height + "px";
		}

		this.setViewport(0, 0, width, height);

		if (this._initialized) this.backend.updateSize();
	}

	public function setOpaqueSort(method: any): Void {
		this._opaqueSort = method;
	}

	public function setTransparentSort(method: any): Void {
		this._transparentSort = method;
	}

	public function getScissor(target: Vector4): Vector4 {
		var scissor = this._scissor;

		target.x = scissor.x;
		target.y = scissor.y;
		target.width = scissor.width;
		target.height = scissor.height;

		return target;
	}

	public function setScissor(x: Float, y: Float, width: Float, height: Float): Void {
		var scissor = this._scissor;

		if (Std.is(x, Vector4)) {
			scissor.copy(x);
		} else {
			scissor.set(x, y, width, height);
		}
	}

	public function getScissorTest(): Bool {
		return this._scissorTest;
	}

	public function setScissorTest(boolean: Bool): Void {
		this._scissorTest = boolean;

		this.backend.setScissorTest(boolean);
	}

	public function getViewport(target: Vector4): Vector4 {
		return target.copy(this._viewport);
	}

	public function setViewport(x: Float, y: Float, width: Float, height: Float, minDepth: Float = 0, maxDepth: Float = 1): Void {
		var viewport = this._viewport;

		if (Std.is(x, Vector4)) {
			viewport.copy(x);
		} else {
			viewport.set(x, y, width, height);
		}

		viewport.minDepth = minDepth;
		viewport.maxDepth = maxDepth;
	}

	public function getClearColor(target: Color4): Color4 {
		return target.copy(this._clearColor);
	}

	public function setClearColor(color: Int, alpha: Float = 1): Void {
		this._clearColor.set(color);
		this._clearColor.a = alpha;
	}

	public function getClearAlpha(): Float {
		return this._clearColor.a;
	}

	public function setClearAlpha(alpha: Float): Void {
		this._clearColor.a = alpha;
	}

	public function getClearDepth(): Float {
		return this._clearDepth;
	}

	public function setClearDepth(depth: Float): Void {
		this._clearDepth = depth;
	}

	public function getClearStencil(): Int {
		return this._clearStencil;
	}

	public function setClearStencil(stencil: Int): Void {
		this._clearStencil = stencil;
	}

	public function isOccluded(object: any): Bool {
		var renderContext = this._currentRenderContext;

		return renderContext != null && this.backend.isOccluded(renderContext, object);
	}

	public function clear(color: Bool = true, depth: Bool = true, stencil: Bool = true): Void {
		if (!this._initialized) {
			console.warn("THREE.Renderer: .clear() called before the backend is initialized. Try using .clearAsync() instead.");

			return this.clearAsync(color, depth, stencil);
		}

		var renderTarget = this._renderTarget != null ? this._renderTarget : this._getFrameBufferTarget();

		var renderTargetData = null;

		if (renderTarget != null) {
			this._textures.updateRenderTarget(renderTarget);

			renderTargetData = this._textures.get(renderTarget);
		}

		this.backend.clear(color, depth, stencil, renderTargetData);
	}

	public function clearColor(): Void {
		return this.clear(true, false, false);
	}

	public function clearDepth(): Void {
		return this.clear(false, true, false);
	}

	public function clearStencil(): Void {
		return this.clear(false, false, true);
	}

	public async function clearAsync(color: Bool = true, depth: Bool = true, stencil: Bool = true): Promise<Void> {
		if (!this._initialized) await this.init();

		this.clear(color, depth, stencil);
	}

	public function clearColorAsync(): Promise<Void> {
		return this.clearAsync(true, false, false);
	}

	public function clearDepthAsync(): Promise<Void> {
		return this.clearAsync(false, true, false);
	}

	public function clearStencilAsync(): Promise<Void> {
		return this.clearAsync(false, false, true);
	}

	public function get currentColorSpace(): Int {
		var renderTarget = this._renderTarget;

		if (renderTarget != null) {
			var texture = renderTarget.texture;

			return (Std.is(texture, Array) ? texture[0] : texture).colorSpace;
		}

		return this.outputColorSpace;
	}

	public function dispose(): Void {
		this.info.dispose();

		this._animation.dispose();
		this._objects.dispose();
		this._pipelines.dispose();
		this._nodes.dispose();
		this._bindings.dispose();
		this._renderLists.dispose();
		this._renderContexts.dispose();
		this._textures.dispose();

		this.setRenderTarget(null);
		this.setAnimationLoop(null);
	}

	public function setRenderTarget(renderTarget: RenderTarget, activeCubeFace: Int = 0, activeMipmapLevel: Int = 0): Void {
		this._renderTarget = renderTarget;
		this._activeCubeFace = activeCubeFace;
		this._activeMipmapLevel = activeMipmapLevel;
	}

	public function getRenderTarget(): RenderTarget {
		return this._renderTarget;
	}

	public function setRenderObjectFunction(renderObjectFunction: (object: any, scene: Scene, camera: any, geometry: any, material: any, group: any, lightsNode: any) -> Void): Void {
		this._renderObjectFunction = renderObjectFunction;
	}

	public function getRenderObjectFunction(): (object: any, scene: Scene, camera: any, geometry: any, material: any, group: any, lightsNode: any) -> Void {
		return this._renderObjectFunction;
	}

	public async function computeAsync(computeNodes: Array<any>): Promise<Void> {
		if (!this._initialized) await this.init();

		var previousRenderId = this._nodes.nodeFrame.renderId;

		this.info.calls++;
		this.info.compute.calls++;
		this.info.compute.computeCalls++;

		this._nodes.nodeFrame.renderId = this.info.calls;

		var backend = this.backend;
		var pipelines = this._pipelines;
		var bindings = this._bindings;
		var nodes = this._nodes;
		var computeList = Std.is(computeNodes, Array) ? computeNodes : [computeNodes];

		if (computeList[0] == null || computeList[0].isComputeNode != true) {
			throw new Error("THREE.Renderer: .compute() expects a ComputeNode.");
		}

		backend.beginCompute(computeNodes);

		for (var computeNode in computeList) {
			if (!pipelines.has(computeNode)) {
				function dispose() {
					computeNode.removeEventListener('dispose', dispose);

					pipelines.delete(computeNode);
					bindings.delete(computeNode);
					nodes.delete(computeNode);
				}

				computeNode.addEventListener('dispose', dispose);

				computeNode.onInit({ renderer: this });
			}

			nodes.updateForCompute(computeNode);
			bindings.updateForCompute(computeNode);

			var computeBindings = bindings.getForCompute(computeNode);
			var computePipeline = pipelines.getForCompute(computeNode, computeBindings);

			backend.compute(computeNodes, computeNode, computeBindings, computePipeline);
		}

		backend.finishCompute(computeNodes);

		await this.backend.resolveTimestampAsync(computeNodes, 'compute');

		this._nodes.nodeFrame.renderId = previousRenderId;
	}

	public async function hasFeatureAsync(name: String): Promise<Bool> {
		if (!this._initialized) await this.init();

		return await this.backend.hasFeature(name);
	}

	public function hasFeature(name: String): Bool {
		if (!this._initialized) {
			console.warn("THREE.Renderer: .hasFeature() called before the backend is initialized. Try using .hasFeatureAsync() instead.");

			return false;
		}

		return this.backend.hasFeature(name);
	}

	public function copyFramebufferToTexture(framebufferTexture: any): Void {
		var renderContext = this._currentRenderContext;

		this._textures.updateTexture(framebufferTexture);

		this.backend.copyFramebufferToTexture(framebufferTexture, renderContext);
	}

	public function copyTextureToTexture(srcTexture: any, dstTexture: any, srcRegion: any = null, dstPosition: any = null, level: Int = 0): Void {
		this._textures.updateTexture(srcTexture);
		this._textures.updateTexture(dstTexture);

		this.backend.copyTextureToTexture(srcTexture, dstTexture, srcRegion, dstPosition, level);
	}

	public async function readRenderTargetPixelsAsync(renderTarget: RenderTarget, x: Int, y: Int, width: Int, height: Int, index: Int = 0): Promise<Array<Float>> {
		return await this.backend.copyTextureToBuffer(renderTarget.textures[index], x, y, width, height);
	}

	public function _projectObject(object: any, camera: any, groupOrder: Int, renderList: RenderList): Void {
		if (object.visible == false) return;

		var visible = object.layers.test(camera.layers);

		if (visible) {
			if (object.isGroup) {
				groupOrder = object.renderOrder;
			} else if (object.isLOD) {
				if (object.autoUpdate) object.update(camera);
			} else if (object.isLight) {
				renderList.pushLight(object);
			} else if (object.isSprite) {
				if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
					if (this.sortObjects) {
						_vector3.setFromMatrixPosition(object.matrixWorld).applyMatrix4(_projScreenMatrix);
					}

					var geometry = object.geometry;
					var material = object.material;

					if (material.visible) {
						renderList.push(object, geometry, material, groupOrder, _vector3.z, null);
					}
				}
			} else if (object.isLineLoop) {
				console.error("THREE.Renderer: Objects of type THREE.LineLoop are not supported. Please use THREE.Line or THREE.LineSegments.");
			} else if (object.isMesh || object.isLine || object.isPoints) {
				if (!object.frustumCulled || _frustum.intersectsObject(object)) {
					var geometry = object.geometry;
					var material = object.material;

					if (this.sortObjects) {
						if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

						_vector3.copy(geometry.boundingSphere.center).applyMatrix4(object.matrixWorld).applyMatrix4(_projScreenMatrix);
					}

					if (Std.is(material, Array)) {
						var groups = geometry.groups;

						for (var i = 0, l = groups.length; i < l; i++) {
							var group = groups[i];
							var groupMaterial = material[group.materialIndex];

							if (groupMaterial && groupMaterial.visible) {
								renderList.push(object, geometry, groupMaterial, groupOrder, _vector3.z, group);
							}
						}
					} else if (material.visible) {
						renderList.push(object, geometry, material, groupOrder, _vector3.z, null);
					}
				}
			}
		}

		var children = object.children;

		for (var i = 0, l = children.length; i < l; i++) {
			this._projectObject(children[i], camera, groupOrder, renderList);
		}
	}

	public function _renderObjects(renderList: Array<any>, camera: any, scene: Scene, lightsNode: any): Void {
		for (var i = 0, il = renderList.length; i < il; i++) {
			var renderItem = renderList[i];

			var object = renderItem.object;
			var geometry = renderItem.geometry;
			var material = renderItem.material;
			var group = renderItem.group;

			if (camera.isArrayCamera) {
				var cameras = camera.cameras;

				for (var j = 0, jl = cameras.length; j < jl; j++) {
					var camera2 = cameras[j];

					if (object.layers.test(camera2.layers)) {
						var vp = camera2.viewport;
						var minDepth = vp.minDepth != null ? vp.minDepth : 0;
						var maxDepth = vp.maxDepth != null ? vp.maxDepth : 1;

						var viewportValue = this._currentRenderContext.viewportValue;
						viewportValue.copy(vp).multiplyScalar(this._pixelRatio).floor();
						viewportValue.minDepth = minDepth;
						viewportValue.maxDepth = maxDepth;

						this.backend.updateViewport(this._currentRenderContext);

						this._currentRenderObjectFunction(object, scene, camera2, geometry, material, group, lightsNode);
					}
				}
			} else {
				this._currentRenderObjectFunction(object, scene, camera, geometry, material, group, lightsNode);
			}
		}
	}

	public function renderObject(object: any, scene: Scene, camera: any, geometry: any, material: any, group: any, lightsNode: any): Void {
		var overridePositionNode: any;
		var overrideFragmentNode: any;
		var overrideDepthNode: any;

		object.onBeforeRender(this, scene, camera, geometry, material, group);

		material.onBeforeRender(this, scene, camera, geometry, material, group);

		if (scene.overrideMaterial != null) {
			var overrideMaterial = scene.overrideMaterial;

			if (material.positionNode && material.positionNode.isNode) {
				overridePositionNode = overrideMaterial.positionNode;
				overrideMaterial.positionNode = material.positionNode;
			}

			if (overrideMaterial.isShadowNodeMaterial) {
				overrideMaterial.side = material.shadowSide == null ? material.side : material.shadowSide;

				if (material.depthNode && material.depthNode.isNode) {
					overrideDepthNode = overrideMaterial.depthNode;
					overrideMaterial.depthNode = material.depthNode;
				}

				if (material.shadowNode && material.shadowNode.isNode) {
					overrideFragmentNode = overrideMaterial.fragmentNode;
					overrideMaterial.fragmentNode = material.shadowNode;
				}

				if (this.localClippingEnabled) {
					if (material.clipShadows) {
						if (overrideMaterial.clippingPlanes != material.clippingPlanes) {
							overrideMaterial.clippingPlanes = material.clippingPlanes;
							overrideMaterial.needsUpdate = true;
						}

						if (overrideMaterial.clipIntersection != material.clipIntersection) {
							overrideMaterial.clipIntersection = material.clipIntersection;
						}
					} else if (Std.is(overrideMaterial.clippingPlanes, Array)) {
						overrideMaterial.clippingPlanes = null;
						overrideMaterial.needsUpdate = true;
					}
				}
			}

			material = overrideMaterial;
		}

		if (material.transparent && material.side == DoubleSide && !material.forceSinglePass) {
			material.side = BackSide;
			this._handleObjectFunction(object, material, scene, camera, lightsNode, group, 'backSide');

			material.side = FrontSide;
			this._handleObjectFunction(object, material, scene, camera, lightsNode, group);

			material.side = DoubleSide;
		} else {
			this._handleObjectFunction(object, material, scene, camera, lightsNode, group);
		}

		if (overridePositionNode != null) {
			scene.overrideMaterial.positionNode = overridePositionNode;
		}

		if (overrideDepthNode != null) {
			scene.overrideMaterial.depthNode = overrideDepthNode;
		}

		if (overrideFragmentNode != null) {
			scene.overrideMaterial.fragmentNode = overrideFragmentNode;
		}

		object.onAfterRender(this, scene, camera, geometry, material, group);
	}

	public function _renderObjectDirect(object: any, material: any, scene: Scene, camera: any, lightsNode: any, group: any, passId: String): Void {
		var renderObject = this._objects.get(object, material, scene, camera, lightsNode, this._currentRenderContext, passId);
		renderObject.drawRange = group != null ? group : object.geometry.drawRange;

		this._nodes.updateBefore(renderObject);

		object.modelViewMatrix.multiplyMatrices(camera.matrixWorldInverse, object.matrixWorld);
		object.normalMatrix.getNormalMatrix(object.modelViewMatrix);

		this._nodes.updateForRender(renderObject);
		this._geometries.updateForRender(renderObject);
		this._bindings.updateForRender(renderObject);
		this._pipelines.updateForRender(renderObject);

		this.backend.draw(renderObject, this.info);
	}

	public function _createObjectPipeline(object: any, material: any, scene: Scene, camera: any, lightsNode: any, passId: String): Void {
		var renderObject = this._objects.get(object, material, scene, camera, lightsNode, this._currentRenderContext, passId);

		this._nodes.updateBefore(renderObject);

		this._nodes.updateForRender(renderObject);
		this._geometries.updateForRender(renderObject);
		this._bindings.updateForRender(renderObject);

		this._pipelines.getForRender(renderObject, this._compilationPromises);
	}

	public function get compute(): (computeNodes: Array<any>) -> Promise<Void> {
		return this.computeAsync;
	}

	public function get compile(): (scene: Scene, camera: any, targetScene: Scene = null) -> Promise<Void> {
		return this.compileAsync;
	}
}