package three.js.examples.jsm.renderers.common;

import three.js.Animation;
import three.js.RenderObjects;
import three.js.Attributes;
import three.js.Geometries;
import three.js.Info;
import three.js.Pipelines;
import three.js.Bindings;
import three.js.RenderLists;
import three.js.RenderContexts;
import three.js.Textures;
import three.js.Background;
import three.js.nodes.Nodes;
import three.js.Color4;
import three.js.ClippingContext;
import three.js.Scene;
import three.js.Frustum;
import three.js.Matrix4;
import three.js.Vector2;
import three.js.Vector3;
import three.js.Vector4;
import three.js.DoubleSide;
import three.js.BackSide;
import three.js.FrontSide;
import three.js.SRGBColorSpace;
import three.js.NoColorSpace;
import three.js.NoToneMapping;
import three.js.LinearFilter;
import three.js.LinearSRGBColorSpace;
import three.js.RenderTarget;
import three.js.HalfFloatType;
import three.js.RGBAFormat;
import three.js.QuadMesh;
import three.js.NodeMaterial;

class Renderer {
    public var isRenderer:Bool = true;
    public var domElement:Dynamic;
    public var backend:Dynamic;
    public var autoClear:Bool = true;
    public var autoClearColor:Bool = true;
    public var autoClearDepth:Bool = true;
    public var autoClearStencil:Bool = true;
    public var alpha:Bool;
    public var logarithmicDepthBuffer:Bool;
    public var outputColorSpace:Int;
    public var toneMapping:Int;
    public var toneMappingExposure:Float = 1.0;
    public var sortObjects:Bool = true;
    public var depth:Bool = true;
    public var stencil:Bool = false;
    public var clippingPlanes:Array<Dynamic>;
    public var info:Info;
    public var toneMappingNode:Dynamic;
    public var pixelRatio:Float = 1;
    public var width:Int;
    public var height:Int;
    public var viewport:Vector4;
    public var scissor:Vector4;
    public var scissorTest:Bool = false;
    public var attributes:Attributes;
    public var geometries:Geometries;
    public var nodes:Nodes;
    public var animation:Animation;
    public var bindings:Bindings;
    public var objects:RenderObjects;
    public var pipelines:Pipelines;
    public var renderLists:RenderLists;
    public var renderContexts:RenderContexts;
    public var textures:Textures;
    public var background:Background;
    public var currentRenderContext:Dynamic;
    public var opaqueSort:Dynamic;
    public var transparentSort:Dynamic;
    public var frameBufferTarget:RenderTarget;
    public var renderTarget:RenderTarget;
    public var activeCubeFace:Int = 0;
    public var activeMipmapLevel:Int = 0;
    public var renderObjectFunction:Dynamic;
    public var currentRenderObjectFunction:Dynamic;
    public var handleObjectFunction:Dynamic;
    public var initialized:Bool = false;
    public var initPromise:Promise<Dynamic>;
    public var compilationPromises:Array<Promise<Dynamic>>;
    public var shadowMap:Dynamic;
    public var xr:Dynamic;

    public function new(backend:Dynamic, ?parameters:Dynamic = {}) {
        this.backend = backend;
        this.domElement = backend.getDomElement();
        this.alpha = parameters.alpha == null ? true : parameters.alpha;
        this.logarithmicDepthBuffer = parameters.logarithmicDepthBuffer == null ? false : parameters.logarithmicDepthBuffer;
        this.outputColorSpace = SRGBColorSpace;
        this.toneMapping = NoToneMapping;
        this.toneMappingExposure = 1.0;
        this.sortObjects = true;
        this.depth = true;
        this.stencil = false;
        this.clippingPlanes = [];
        this.info = new Info();
        this.toneMappingNode = null;
        this.pixelRatio = 1;
        this.width = this.domElement.width;
        this.height = this.domElement.height;
        this.viewport = new Vector4(0, 0, this.width, this.height);
        this.scissor = new Vector4(0, 0, this.width, this.height);
        this.scissorTest = false;
        this.attributes = null;
        this.geometries = null;
        this.nodes = null;
        this.animation = null;
        this.bindings = null;
        this.objects = null;
        this.pipelines = null;
        this.renderLists = null;
        this.renderContexts = null;
        this.textures = null;
        this.background = null;
        this.currentRenderContext = null;
        this.opaqueSort = null;
        this.transparentSort = null;
        this.frameBufferTarget = null;
        this.renderTarget = null;
        this.activeCubeFace = 0;
        this.activeMipmapLevel = 0;
        this.renderObjectFunction = null;
        this.currentRenderObjectFunction = null;
        this.handleObjectFunction = _renderObjectDirect;
        this.initialized = false;
        this.initPromise = null;
        this.compilationPromises = null;
        this.shadowMap = { enabled: false, type: null };
        this.xr = { enabled: false };
    }

    public function init():Promise<Dynamic> {
        if (this.initialized) {
            throw new Error('Renderer: Backend has already been initialized.');
        }
        if (this.initPromise != null) {
            return this.initPromise;
        }
        this.initPromise = new Promise((resolve, reject) -> {
            try {
                this.backend.init(this);
                this.nodes = new Nodes(this, this.backend);
                this.animation = new Animation(this.nodes, this.info);
                this.attributes = new Attributes(this.backend);
                this.background = new Background(this, this.nodes);
                this.geometries = new Geometries(this.attributes, this.info);
                this.textures = new Textures(this, this.backend, this.info);
                this.pipelines = new Pipelines(this.backend, this.nodes);
                this.bindings = new Bindings(this.backend, this.nodes, this.textures, this.attributes, this.pipelines, this.info);
                this.objects = new RenderObjects(this, this.nodes, this.geometries, this.pipelines, this.bindings, this.info);
                this.renderLists = new RenderLists();
                this.renderContexts = new RenderContexts();
                this.initialized = true;
                resolve();
            } catch (error:Dynamic) {
                reject(error);
            }
        });
        return this.initPromise;
    }

    public function get_coordinateSystem():Dynamic {
        return this.backend.coordinateSystem;
    }

    public function compileAsync(scene:Scene, camera:Dynamic, ?targetScene:Scene = null):Promise<Dynamic> {
        if (!this.initialized) {
            await this.init();
        }
        // ...
    }

    public function renderAsync(scene:Scene, camera:Dynamic):Promise<Dynamic> {
        if (!this.initialized) {
            await this.init();
        }
        // ...
    }

    public function render(scene:Scene, camera:Dynamic) {
        if (!this.initialized) {
            console.warn('THREE.Renderer: .render() called before the backend is initialized. Try using .renderAsync() instead.');
            return this.renderAsync(scene, camera);
        }
        this._renderScene(scene, camera);
    }

    public function _getFrameBufferTarget():RenderTarget {
        // ...
    }

    public function _renderScene(scene:Scene, camera:Dynamic, useFrameBufferTarget:Bool = true):Dynamic {
        // ...
    }

    public function _renderObjects(objects:Array<Dynamic>, camera:Dynamic, scene:Scene, lightsNode:Dynamic) {
        // ...
    }
}