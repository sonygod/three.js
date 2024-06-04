import Animation from "./Animation";
import RenderObjects from "./RenderObjects";
import Attributes from "./Attributes";
import Geometries from "./Geometries";
import Info from "./Info";
import Pipelines from "./Pipelines";
import Bindings from "./Bindings";
import RenderLists from "./RenderLists";
import RenderContexts from "./RenderContexts";
import Textures from "./Textures";
import Background from "./Background";
import Nodes from "./nodes/Nodes";
import Color4 from "./Color4";
import ClippingContext from "./ClippingContext";
import three from "three";
import {NodeMaterial} from "../../nodes/Nodes";
import QuadMesh from "../../objects/QuadMesh";

class Renderer {
	public isRenderer:Bool = true;

	public domElement:Dynamic;
	public backend:Dynamic;
	public autoClear:Bool = true;
	public autoClearColor:Bool = true;
	public autoClearDepth:Bool = true;
	public autoClearStencil:Bool = true;
	public alpha:Bool = true;
	public logarithmicDepthBuffer:Bool = false;
	public outputColorSpace:Int = three.SRGBColorSpace;
	public toneMapping:Int = three.NoToneMapping;
	public toneMappingExposure:Float = 1.0;
	public sortObjects:Bool = true;
	public depth:Bool = true;
	public stencil:Bool = false;
	public clippingPlanes:Array<Dynamic> = [];
	public info:Info = new Info();
	public toneMappingNode:Dynamic = null;
	private _pixelRatio:Float = 1;
	private _width:Int = 0;
	private _height:Int = 0;
	private _viewport:three.Vector4 = new three.Vector4(0, 0, 0, 0);
	private _scissor:three.Vector4 = new three.Vector4(0, 0, 0, 0);
	private _scissorTest:Bool = false;
	private _attributes:Attributes = null;
	private _geometries:Geometries = null;
	private _nodes:Nodes = null;
	private _animation:Animation = null;
	private _bindings:Bindings = null;
	private _objects:RenderObjects = null;
	private _pipelines:Pipelines = null;
	private _renderLists:RenderLists = null;
	private _renderContexts:RenderContexts = null;
	private _textures:Textures = null;
	private _background:Background = null;
	private _currentRenderContext:Dynamic = null;
	private _opaqueSort:Dynamic = null;
	private _transparentSort:Dynamic = null;
	private _frameBufferTarget:Dynamic = null;
	private _clearColor:Color4 = new Color4(0, 0, 0, 0);
	private _clearDepth:Float = 1;
	private _clearStencil:Int = 0;
	private _renderTarget:Dynamic = null;
	private _activeCubeFace:Int = 0;
	private _activeMipmapLevel:Int = 0;
	private _renderObjectFunction:Dynamic = null;
	private _currentRenderObjectFunction:Dynamic = null;
	private _handleObjectFunction:Dynamic = this._renderObjectDirect;
	private _initialized:Bool = false;
	private _initPromise:Dynamic = null;
	private _compilationPromises:Dynamic = null;

	public shadowMap:Dynamic = {
		enabled: false,
		type: null
	};

	public xr:Dynamic = {
		enabled: false
	};

	public constructor(backend:Dynamic, parameters:Dynamic = {}) {
		let logarithmicDepthBuffer = parameters.logarithmicDepthBuffer == null ? false : parameters.logarithmicDepthBuffer;
		let alpha = parameters.alpha == null ? true : parameters.alpha;
		this.domElement = backend.getDomElement();
		this.backend = backend;
		this.alpha = alpha;
		this.logarithmicDepthBuffer = logarithmicDepthBuffer;
		let alphaClear = this.alpha ? 0 : 1;
		this._clearColor = new Color4(0, 0, 0, alphaClear);
		this._width = this.domElement.width;
		this._height = this.domElement.height;
		this._viewport = new three.Vector4(0, 0, this._width, this._height);
		this._scissor = new three.Vector4(0, 0, this._width, this._height);
	}

	public async init():Dynamic {
		if (this._initialized) {
			throw new Error("Renderer: Backend has already been initialized.");
		}
		if (this._initPromise != null) {
			return this._initPromise;
		}
		this._initPromise = new Promise(async (resolve, reject) => {
			try {
				await this.backend.init(this);
			} catch (error) {
				reject(error);
				return;
			}
			this._nodes = new Nodes(this, this.backend);
			this._animation = new Animation(this._nodes, this.info);
			this._attributes = new Attributes(this.backend);
			this._background = new Background(this, this._nodes);
			this._geometries = new Geometries(this._attributes, this.info);
			this._textures = new Textures(this, this.backend, this.info);
			this._pipelines = new Pipelines(this.backend, this._nodes);
			this._bindings = new Bindings(this.backend, this._nodes, this._textures, this._attributes, this._pipelines, this.info);
			this._objects = new RenderObjects(this, this._nodes, this._geometries, this._pipelines, this._bindings, this.info);
			this._renderLists = new RenderLists();
			this._renderContexts = new RenderContexts();
			this._initialized = true;
			resolve();
		});
		return this._initPromise;
	}

	public get coordinateSystem():Dynamic {
		return this.backend.coordinateSystem;
	}

	public async compileAsync(scene:Dynamic, camera:Dynamic, targetScene:Dynamic = null):Dynamic {
		if (!this._initialized) await this.init();
		let nodeFrame = this._nodes.nodeFrame;
		let previousRenderId = nodeFrame.renderId;
		let previousRenderContext = this._currentRenderContext;
		let previousRenderObjectFunction = this._currentRenderObjectFunction;
		let previousCompilationPromises = this._compilationPromises;
		let sceneRef = scene.isScene ? scene : new three.Scene();
		if (targetScene == null) targetScene = scene;
		let renderTarget = this._renderTarget;
		let renderContext = this._renderContexts.get(targetScene, camera, renderTarget);
		let activeMipmapLevel = this._activeMipmapLevel;
		let compilationPromises = [];
		this._currentRenderContext = renderContext;
		this._currentRenderObjectFunction = this.renderObject;
		this._handleObjectFunction = this._createObjectPipeline;
		this._compilationPromises = compilationPromises;
		nodeFrame.renderId++;
		nodeFrame.update();
		renderContext.depth = this.depth;
		renderContext.stencil = this.stencil;
		if (!renderContext.clippingContext) renderContext.clippingContext = new ClippingContext();
		renderContext.clippingContext.updateGlobal(this, camera);
		sceneRef.onBeforeRender(this, scene, camera, renderTarget);
		let renderList = this._renderLists.get(scene, camera);
		renderList.begin();
		this._projectObject(scene, camera, 0, renderList);
		if (targetScene != scene) {
			targetScene.traverseVisible(function(object) {
				if (object.isLight && object.layers.test(camera.layers)) {
					renderList.pushLight(object);
				}
			});
		}
		renderList.finish();
		if (renderTarget != null) {
			this._textures.updateRenderTarget(renderTarget, activeMipmapLevel);
			let renderTargetData = this._textures.get(renderTarget);
			renderContext.textures = renderTargetData.textures;
			renderContext.depthTexture = renderTargetData.depthTexture;
		} else {
			renderContext.textures = null;
			renderContext.depthTexture = null;
		}
		this._nodes.updateScene(sceneRef);
		this._background.update(sceneRef, renderList, renderContext);
		let opaqueObjects = renderList.opaque;
		let transparentObjects = renderList.transparent;
		let lightsNode = renderList.lightsNode;
		if (opaqueObjects.length > 0) this._renderObjects(opaqueObjects, camera, sceneRef, lightsNode);
		if (transparentObjects.length > 0) this._renderObjects(transparentObjects, camera, sceneRef, lightsNode);
		nodeFrame.renderId = previousRenderId;
		this._currentRenderContext = previousRenderContext;
		this._currentRenderObjectFunction = previousRenderObjectFunction;
		this._compilationPromises = previousCompilationPromises;
		this._handleObjectFunction = this._renderObjectDirect;
		await Promise.all(compilationPromises);
	}

	public async renderAsync(scene:Dynamic, camera:Dynamic):Dynamic {
		if (!this._initialized) await this.init();
		let renderContext = this._renderScene(scene, camera);
		await this.backend.resolveTimestampAsync(renderContext, "render");
	}

	public render(scene:Dynamic, camera:Dynamic):Dynamic {
		if (!this._initialized) {
			console.warn("THREE.Renderer: .render() called before the backend is initialized. Try using .renderAsync() instead.");
			return this.renderAsync(scene, camera);
		}
		this._renderScene(scene, camera);
	}

	private _getFrameBufferTarget():Dynamic {
		let currentColorSpace = this.currentColorSpace;
		let useToneMapping = this._renderTarget == null && (this.toneMapping != three.NoToneMapping || this.toneMappingNode != null);
		let useColorSpace = currentColorSpace != three.LinearSRGBColorSpace && currentColorSpace != three.NoColorSpace;
		if (!useToneMapping && !useColorSpace) return null;
		let width = this.getDrawingBufferSize(new three.Vector2()).width;
		let height = this.getDrawingBufferSize(new three.Vector2()).height;
		let depth = this.depth;
		let stencil = this.stencil;
		let frameBufferTarget = this._frameBufferTarget;
		if (frameBufferTarget == null) {
			frameBufferTarget = new three.RenderTarget(width, height, {
				depthBuffer: depth,
				stencilBuffer: stencil,
				type: three.HalfFloatType,
				format: three.RGBAFormat,
				colorSpace: three.LinearSRGBColorSpace,
				generateMipmaps: false,
				minFilter: three.LinearFilter,
				magFilter: three.LinearFilter,
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

	private _renderScene(scene:Dynamic, camera:Dynamic, useFrameBufferTarget:Bool = true):Dynamic {
		let frameBufferTarget = useFrameBufferTarget ? this._getFrameBufferTarget() : null;
		let nodeFrame = this._nodes.nodeFrame;
		let previousRenderId = nodeFrame.renderId;
		let previousRenderContext = this._currentRenderContext;
		let previousRenderObjectFunction = this._currentRenderObjectFunction;
		let sceneRef = scene.isScene ? scene : new three.Scene();
		let outputRenderTarget = this._renderTarget;
		let activeCubeFace = this._activeCubeFace;
		let activeMipmapLevel = this._activeMipmapLevel;
		let renderTarget = frameBufferTarget != null ? frameBufferTarget : outputRenderTarget;
		if (frameBufferTarget != null) {
			this.setRenderTarget(renderTarget);
		}
		let renderContext = this._renderContexts.get(scene, camera, renderTarget);
		this._currentRenderContext = renderContext;
		this._currentRenderObjectFunction = this._renderObjectFunction != null ? this._renderObjectFunction : this.renderObject;
		this.info.calls++;
		this.info.render.calls++;
		nodeFrame.renderId = this.info.calls;
		let coordinateSystem = this.coordinateSystem;
		if (camera.coordinateSystem != coordinateSystem) {
			camera.coordinateSystem = coordinateSystem;
			camera.updateProjectionMatrix();
		}
		if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
		if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
		let viewport = this._viewport;
		let scissor = this._scissor;
		let pixelRatio = this._pixelRatio;
		if (renderTarget != null) {
			viewport = renderTarget.viewport;
			scissor = renderTarget.scissor;
			pixelRatio = 1;
		}
		this.getDrawingBufferSize(new three.Vector2());
		new three.Vector4(0, 0, this.getDrawingBufferSize(new three.Vector2()).width, this.getDrawingBufferSize(new three.Vector2()).height);
		let minDepth = viewport.minDepth == null ? 0 : viewport.minDepth;
		let maxDepth = viewport.maxDepth == null ? 1 : viewport.maxDepth;
		renderContext.viewportValue.copy(viewport).multiplyScalar(pixelRatio).floor();
		renderContext.viewportValue.width >>= activeMipmapLevel;
		renderContext.viewportValue.height >>= activeMipmapLevel;
		renderContext.viewportValue.minDepth = minDepth;
		renderContext.viewportValue.maxDepth = maxDepth;
		renderContext.viewport = !renderContext.viewportValue.equals(new three.Vector4(0, 0, this.getDrawingBufferSize(new three.Vector2()).width, this.getDrawingBufferSize(new three.Vector2()).height));
		renderContext.scissorValue.copy(scissor).multiplyScalar(pixelRatio).floor();
		renderContext.scissor = this._scissorTest && !renderContext.scissorValue.equals(new three.Vector4(0, 0, this.getDrawingBufferSize(new three.Vector2()).width, this.getDrawingBufferSize(new three.Vector2()).height));
		renderContext.scissorValue.width >>= activeMipmapLevel;
		renderContext.scissorValue.height >>= activeMipmapLevel;
		if (!renderContext.clippingContext) renderContext.clippingContext = new ClippingContext();
		renderContext.clippingContext.updateGlobal(this, camera);
		sceneRef.onBeforeRender(this, scene, camera, renderTarget);
		new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
		new three.Frustum().setFromProjectionMatrix(new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse), coordinateSystem);
		let renderList = this._renderLists.get(scene, camera);
		renderList.begin();
		this._projectObject(scene, camera, 0, renderList);
		renderList.finish();
		if (this.sortObjects) {
			renderList.sort(this._opaqueSort, this._transparentSort);
		}
		if (renderTarget != null) {
			this._textures.updateRenderTarget(renderTarget, activeMipmapLevel);
			let renderTargetData = this._textures.get(renderTarget);
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
		let opaqueObjects = renderList.opaque;
		let transparentObjects = renderList.transparent;
		let lightsNode = renderList.lightsNode;
		if (opaqueObjects.length > 0) this._renderObjects(opaqueObjects, camera, sceneRef, lightsNode);
		if (transparentObjects.length > 0) this._renderObjects(transparentObjects, camera, sceneRef, lightsNode);
		this.backend.finishRender(renderContext);
		nodeFrame.renderId = previousRenderId;
		this._currentRenderContext = previousRenderContext;
		this._currentRenderObjectFunction = previousRenderObjectFunction;
		if (frameBufferTarget != null) {
			this.setRenderTarget(outputRenderTarget, activeCubeFace, activeMipmapLevel);
			new QuadMesh(new NodeMaterial()).material.fragmentNode = this._nodes.getOutputNode(renderTarget.texture);
			this._renderScene(new QuadMesh(new NodeMaterial()), new QuadMesh(new NodeMaterial()).camera, false);
		}
		sceneRef.onAfterRender(this, scene, camera, renderTarget);
		return renderContext;
	}

	public getMaxAnisotropy():Dynamic {
		return this.backend.getMaxAnisotropy();
	}

	public getActiveCubeFace():Int {
		return this._activeCubeFace;
	}

	public getActiveMipmapLevel():Int {
		return this._activeMipmapLevel;
	}

	public async setAnimationLoop(callback:Dynamic):Dynamic {
		if (!this._initialized) await this.init();
		this._animation.setAnimationLoop(callback);
	}

	public getArrayBuffer(attribute:Dynamic):Dynamic {
		console.warn("THREE.Renderer: getArrayBuffer() is deprecated. Use getArrayBufferAsync() instead.");
		return this.getArrayBufferAsync(attribute);
	}

	public async getArrayBufferAsync(attribute:Dynamic):Dynamic {
		return await this.backend.getArrayBufferAsync(attribute);
	}

	public getContext():Dynamic {
		return this.backend.getContext();
	}

	public getPixelRatio():Float {
		return this._pixelRatio;
	}

	public getDrawingBufferSize(target:three.Vector2):three.Vector2 {
		return target.set(this._width * this._pixelRatio, this._height * this._pixelRatio).floor();
	}

	public getSize(target:three.Vector2):three.Vector2 {
		return target.set(this._width, this._height);
	}

	public setPixelRatio(value:Float = 1):Void {
		this._pixelRatio = value;
		this.setSize(this._width, this._height, false);
	}

	public setDrawingBufferSize(width:Int, height:Int, pixelRatio:Float):Void {
		this._width = width;
		this._height = height;
		this._pixelRatio = pixelRatio;
		this.domElement.width = Math.floor(width * pixelRatio);
		this.domElement.height = Math.floor(height * pixelRatio);
		this.setViewport(0, 0, width, height);
		if (this._initialized) this.backend.updateSize();
	}

	public setSize(width:Int, height:Int, updateStyle:Bool = true):Void {
		this._width = width;
		this._height = height;
		this.domElement.width = Math.floor(width * this._pixelRatio);
		this.domElement.height = Math.floor(height * this._pixelRatio);
		if (updateStyle) {
			this.domElement.style.width = width + "px";
			this.domElement.style.height = height + "px";
		}
		this.setViewport(0, 0, width, height);
		if (this._initialized) this.backend.updateSize();
	}

	public setOpaqueSort(method:Dynamic):Void {
		this._opaqueSort = method;
	}

	public setTransparentSort(method:Dynamic):Void {
		this._transparentSort = method;
	}

	public getScissor(target:three.Vector4):three.Vector4 {
		let scissor = this._scissor;
		target.x = scissor.x;
		target.y = scissor.y;
		target.width = scissor.width;
		target.height = scissor.height;
		return target;
	}

	public setScissor(x:Dynamic, y:Int, width:Int, height:Int):Void {
		let scissor = this._scissor;
		if (x.isVector4) {
			scissor.copy(x);
		} else {
			scissor.set(x, y, width, height);
		}
	}

	public getScissorTest():Bool {
		return this._scissorTest;
	}

	public setScissorTest(boolean:Bool):Void {
		this._scissorTest = boolean;
		this.backend.setScissorTest(boolean);
	}

	public getViewport(target:three.Vector4):three.Vector4 {
		return target.copy(this._viewport);
	}

	public setViewport(x:Dynamic, y:Int, width:Int, height:Int, minDepth:Float = 0, maxDepth:Float = 1):Void {
		let viewport = this._viewport;
		if (x.isVector4) {
			viewport.copy(x);
		} else {
			viewport.set(x, y, width, height);
		}
		viewport.minDepth = minDepth;
		viewport.maxDepth = maxDepth;
	}

	public getClearColor(target:Color4):Color4 {
		return target.copy(this._clearColor);
	}

	public setClearColor(color:Dynamic, alpha:Float = 1):Void {
		this._clearColor.set(color);
		this._clearColor.a = alpha;
	}

	public getClearAlpha():Float {
		return this._clearColor.a;
	}

	public setClearAlpha(alpha:Float):Void {
		this._clearColor.a = alpha;
	}

	public getClearDepth():Float {
		return this._clearDepth;
	}

	public setClearDepth(depth:Float):Void {
		this._clearDepth = depth;
	}

	public getClearStencil():Int {
		return this._clearStencil;
	}

	public setClearStencil(stencil:Int):Void {
		this._clearStencil = stencil;
	}

	public isOccluded(object:Dynamic):Dynamic {
		let renderContext = this._currentRenderContext;
		return renderContext && this.backend.isOccluded(renderContext, object);
	}

	public clear(color:Bool = true, depth:Bool = true, stencil:Bool = true):Void {
		if (!this._initialized) {
			console.warn("THREE.Renderer: .clear() called before the backend is initialized. Try using .clearAsync() instead.");
			return this.clearAsync(color, depth, stencil);
		}
		let renderTarget = this._renderTarget != null ? this._renderTarget : this._getFrameBufferTarget();
		let renderTargetData = null;
		if (renderTarget != null) {
			this._textures.updateRenderTarget(renderTarget);
			renderTargetData = this._textures.get(renderTarget);
		}
		this.backend.clear(color, depth, stencil, renderTargetData);
	}

	public clearColor():Void {
		this.clear(true, false, false);
	}

	public clearDepth():Void {
		this.clear(false, true, false);
	}

	public clearStencil():Void {
		this.clear(false, false, true);
	}

	public async clearAsync(color:Bool = true, depth:Bool = true, stencil:Bool = true):Dynamic {
		if (!this._initialized) await this.init();
		this.clear(color, depth, stencil);
	}

	public clearColorAsync():Dynamic {
		return this.clearAsync(true, false, false);
	}

	public clearDepthAsync():Dynamic {
		return this.clearAsync(false, true, false);
	}

	public clearStencilAsync():Dynamic {
		return this.clearAsync(false, false, true);
	}

	public get currentColorSpace():Int {
		let renderTarget = this._renderTarget;
		if (renderTarget != null) {
			let texture = renderTarget.texture;
			return (Array.isArray(texture) ? texture[0] : texture).colorSpace;
		}
		return this.outputColorSpace;
	}

	public dispose():Void {
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

	public setRenderTarget(renderTarget:Dynamic, activeCubeFace:Int = 0, activeMipmapLevel:Int = 0):Void {
		this._renderTarget = renderTarget;
		this._activeCubeFace = activeCubeFace;
		this._activeMipmapLevel = activeMipmapLevel;
	}

	public getRenderTarget():Dynamic {
		return this._renderTarget;
	}

	public setRenderObjectFunction(renderObjectFunction:Dynamic):Void {
		this._renderObjectFunction = renderObjectFunction;
	}

	public getRenderObjectFunction():Dynamic {
		return this._renderObjectFunction;
	}

	public async computeAsync(computeNodes:Dynamic):Dynamic {
		if (!this._initialized) await this.init();
		let nodeFrame = this._nodes.nodeFrame;
		let previousRenderId = nodeFrame.renderId;
		this.info.calls++;
		this.info.compute.calls++;
		this.info.compute.computeCalls++;
		nodeFrame.renderId = this.info.calls;
		let backend = this.backend;
		let pipelines = this._pipelines;
		let bindings = this._bindings;
		let nodes = this._nodes;
		let computeList = Array.isArray(computeNodes) ? computeNodes : [computeNodes];
		if (computeList[0] == null || !computeList[0].isComputeNode) {
			throw new Error("THREE.Renderer: .compute() expects a ComputeNode.");
		}
		backend.beginCompute(computeNodes);
		for (let computeNode of computeList) {
			if (!pipelines.has(computeNode)) {
				let dispose = () => {
					computeNode.removeEventListener("dispose", dispose);
					pipelines.delete(computeNode);
					bindings.delete(computeNode);
					nodes.delete(computeNode);
				};
				computeNode.addEventListener("dispose", dispose);
				computeNode.onInit({ renderer: this });
			}
			nodes.updateForCompute(computeNode);
			bindings.updateForCompute(computeNode);
			let computeBindings = bindings.getForCompute(computeNode);
			let computePipeline = pipelines.getForCompute(computeNode, computeBindings);
			backend.compute(computeNodes, computeNode, computeBindings, computePipeline);
		}
		backend.finishCompute(computeNodes);
		await this.backend.resolveTimestampAsync(computeNodes, "compute");
		nodeFrame.renderId = previousRenderId;
	}

	public async hasFeatureAsync(name:String):Dynamic {
		if (!this._initialized) await this.init();
		return this.backend.hasFeature(name);
	}

	public hasFeature(name:String):Bool {
		if (!this._initialized) {
			console.warn("THREE.Renderer: .hasFeature() called before the backend is initialized. Try using .hasFeatureAsync() instead.");
			return false;
		}
		return this.backend.hasFeature(name);
	}

	public copyFramebufferToTexture(framebufferTexture:Dynamic):Void {
		let renderContext = this._currentRenderContext;
		this._textures.updateTexture(framebufferTexture);
		this.backend.copyFramebufferToTexture(framebufferTexture, renderContext);
	}

	public copyTextureToTexture(srcTexture:Dynamic, dstTexture:Dynamic, srcRegion:Dynamic = null, dstPosition:Dynamic = null, level:Int = 0):Void {
		this._textures.updateTexture(srcTexture);
		this._textures.updateTexture(dstTexture);
		this.backend.copyTextureToTexture(srcTexture, dstTexture, srcRegion, dstPosition, level);
	}

	public readRenderTargetPixelsAsync(renderTarget:Dynamic, x:Int, y:Int, width:Int, height:Int, index:Int = 0):Dynamic {
		return this.backend.copyTextureToBuffer(renderTarget.textures[index], x, y, width, height);
	}

	private _projectObject(object:Dynamic, camera:Dynamic, groupOrder:Int, renderList:RenderLists):Void {
		if (!object.visible) return;
		let visible = object.layers.test(camera.layers);
		if (visible) {
			if (object.isGroup) {
				groupOrder = object.renderOrder;
			} else if (object.isLOD) {
				if (object.autoUpdate) object.update(camera);
			} else if (object.isLight) {
				renderList.pushLight(object);
			} else if (object.isSprite) {
				if (!object.frustumCulled || new three.Frustum().intersectsSprite(object)) {
					if (this.sortObjects) {
						new three.Vector3().setFromMatrixPosition(object.matrixWorld).applyMatrix4(new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse));
					}
					let geometry = object.geometry;
					let material = object.material;
					if (material.visible) {
						renderList.push(object, geometry, material, groupOrder, new three.Vector3().setFromMatrixPosition(object.matrixWorld).applyMatrix4(new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse)).z, null);
					}
				}
			} else if (object.isLineLoop) {
				console.error("THREE.Renderer: Objects of type THREE.LineLoop are not supported. Please use THREE.Line or THREE.LineSegments.");
			} else if (object.isMesh || object.isLine || object.isPoints) {
				if (!object.frustumCulled || new three.Frustum().intersectsObject(object)) {
					let geometry = object.geometry;
					let material = object.material;
					if (this.sortObjects) {
						if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
						new three.Vector3().copy(geometry.boundingSphere.center).applyMatrix4(object.matrixWorld).applyMatrix4(new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse));
					}
					if (Array.isArray(material)) {
						let groups = geometry.groups;
						for (let i = 0, l = groups.length; i < l; i++) {
							let group = groups[i];
							let groupMaterial = material[group.materialIndex];
							if (groupMaterial && groupMaterial.visible) {
								renderList.push(object, geometry, groupMaterial, groupOrder, new three.Vector3().copy(geometry.boundingSphere.center).applyMatrix4(object.matrixWorld).applyMatrix4(new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse)).z, group);
							}
						}
					} else if (material.visible) {
						renderList.push(object, geometry, material, groupOrder, new three.Vector3().copy(geometry.boundingSphere.center).applyMatrix4(object.matrixWorld).applyMatrix4(new three.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse)).z, null);
					}
				}
			}
		}
		let children = object.children;
		for (let i = 0, l = children.length; i < l; i++) {
			this._projectObject(children[i], camera, groupOrder, renderList);
		}
	}

	private _renderObjects(renderList:Array<Dynamic>, camera:Dynamic, scene:Dynamic, lightsNode:Dynamic):Void {
		for (let i = 0, il = renderList.length; i < il; i++) {
			let renderItem = renderList[i];
			let object = renderItem.object;
			let geometry = renderItem.geometry;
			let material = renderItem.material;
			let group = renderItem.group;
			object.onBeforeRender(this, scene, camera, geometry, material, group);
			material.onBeforeRender(this, scene, camera, geometry, material, group);
			if (scene.overrideMaterial != null) {
				let overrideMaterial = scene.overrideMaterial;
				if (material.positionNode && material.positionNode.isNode) {
					overrideMaterial.positionNode = material.positionNode;
				}
				if (overrideMaterial.isShadowNodeMaterial) {
					overrideMaterial.side = material.shadowSide == null ? material.side : material.shadowSide;
					if (material.depthNode && material.depthNode.isNode) {
						overrideMaterial.depthNode = material.depthNode;
					}
					if (material.shadowNode && material.shadowNode.isNode) {
						overrideMaterial.fragmentNode = material.shadowNode;
					}
					if (this.localClippingEnabled) {
						if (material.clipShadows) {
							if (
					overrideMaterial.clippingPlanes != material.clippingPlanes) {
							overrideMaterial.clippingPlanes = material.clippingPlanes;
							overrideMaterial.needsUpdate = true;
						}
						if (overrideMaterial.clipIntersection != material.clipIntersection) {
							overrideMaterial.clipIntersection = material.clipIntersection;
						}
					} else if (Array.isArray(overrideMaterial.clippingPlanes)) {
						overrideMaterial.clippingPlanes = null;
						overrideMaterial.needsUpdate = true;
					}
				}
				material = overrideMaterial;
			}
			material = overrideMaterial;
		}
		if (material.transparent && material.side == three.DoubleSide && !material.forceSinglePass) {
			material.side = three.BackSide;
			this._handleObjectFunction(object, material, scene, camera, lightsNode, group, "backSide");
			material.side = three.FrontSide;
			this._handleObjectFunction(object, material, scene, camera, lightsNode, group);
			material.side = three.DoubleSide;
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

	private _renderObjectDirect(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, group:Dynamic, passId:String):Void {
		let renderObject = this._objects.get(object, material, scene, camera, lightsNode, this._currentRenderContext, passId);
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

	private _createObjectPipeline(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, passId:String):Void {
		let renderObject = this._objects.get(object, material, scene, camera, lightsNode, this._currentRenderContext, passId);
		this._nodes.updateBefore(renderObject);
		this._nodes.updateForRender(renderObject);
		this._geometries.updateForRender(renderObject);
		this._bindings.updateForRender(renderObject);
		this._pipelines.getForRender(renderObject, this._compilationPromises);
	}

	public get compute():Dynamic {
		return this.computeAsync;
	}

	public get compile():Dynamic {
		return this.compileAsync;
	}

}

export default Renderer;