import Animation from './Animation.hx';
import RenderObjects from './RenderObjects.hx';
import Attributes from './Attributes.hx';
import Geometries from './Geometries.hx';
import Info from './Info.hx';
import Pipelines from './Pipelines.hx';
import Bindings from './Bindings.hx';
import RenderLists from './RenderLists.hx';
import RenderContexts from './RenderContexts.hx';
import Textures from './Textures.hx';
import Background from './Background.hx';
import Nodes from './nodes/Nodes.hx';
import Color4 from './Color4.hx';
import ClippingContext from './ClippingContext.hx';
import { Scene, Frustum, Matrix4, Vector2, Vector3, Vector4, DoubleSide, BackSide, FrontSide, SRGBColorSpace, NoColorSpace, NoToneMapping, LinearFilter, LinearSRGBColorSpace, RenderTarget, HalfFloatType, RGBAFormat } from 'three/haxe';
import { NodeMaterial } from '../../nodes/Nodes.hx';
import QuadMesh from '../../objects/QuadMesh.hx';

class Renderer {

	public var isRenderer:Bool;

	// public
	public var domElement:Dynamic;
	public var backend:Dynamic;
	public var autoClear:Bool;
	public var autoClearColor:Bool;
	public var autoClearDepth:Bool;
	public var autoClearStencil:Bool;
	public var alpha:Bool;
	public var logarithmicDepthBuffer:Bool;
	public var outputColorSpace:SRGBColorSpace;
	public var toneMapping:NoToneMapping;
	public var toneMappingExposure:Float;
	public var sortObjects:Bool;
	public var depth:Bool;
	public var stencil:Bool;
	public var clippingPlanes:Array<Dynamic>;
	public var info:Info;

	// nodes
	public var toneMappingNode:Dynamic;

	// internals
	public var _pixelRatio:Float;
	public var _width:Int;
	public var _height:Int;
	public var _viewport:Vector4;
	public var _scissor:Vector4;
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
	public var _compilationPromises:Array<Future<Dynamic>>;

	// backwards compatibility
	public var shadowMap:Dynamic;
	public var xr:Dynamic;

	public function new(backend:Dynamic, parameters:Dynamic = null) {
		this.isRenderer = true;
		this.domElement = backend.getDomElement();
		this.backend = backend;
		this.autoClear = true;
		this.autoClearColor = true;
		this.autoClearDepth = true;
		this.autoClearStencil = true;
		this.alpha = true;
		this.logarithmicDepthBuffer = false;
		this.outputColorSpace = SRGBColorSpace;
		this.toneMapping = NoToneMapping;
		this.toneMappingExposure = 1.0;
		this.sortObjects = true;
		this.depth = true;
		this.stencil = false;
		this.clippingPlanes = [];
		this.info = new Info();
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
		this._compilationPromises = [];
		this.shadowMap = { enabled: false, type: null };
		this.xr = { enabled: false };
	}

	public function async init() {
		if (this._initialized) {
			throw new Error('Renderer: Backend has already been initialized.');
		}
		if (this._initPromise !== null) {
			return this._initPromise;
		}
		this._initPromise = Future.async(async function () {
			const backend = this.backend;
			try {
				await backend.init(this);
			} catch (error) {
				throw error;
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
		});
		return this._initPromise;
	}

	public function get coordinateSystem() {
		return this.backend.coordinateSystem;
	}

	public function async compileAsync(scene:Dynamic, camera:Dynamic, targetScene:Dynamic = null) {
		if (this._initialized === false) {
			await this.init();
		}
		// preserve render tree
		// ...
		// ...
	}

	public function renderObject(object:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic, group:Dynamic, lightsNode:Dynamic) {
		// ...
	}

	// ...
	// ...

}