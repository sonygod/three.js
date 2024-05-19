import Animation from './Animation.js';
import RenderObjects from './RenderObjects.js';
import Attributes from './Attributes.js';
import Geometries from './Geometries.js';
import Info from './Info.js';
import Pipelines from './Pipelines.js';
import Bindings from './Bindings.js';
import RenderLists from './RenderLists.js';
import RenderContexts from './RenderContexts.js';
import Textures from './Textures.js';
import Background from './Background.js';
import Nodes from './nodes/Nodes.js';
import Color4 from './Color4.js';
import ClippingContext from './ClippingContext.js';
import { Scene, Frustum, Matrix4, Vector2, Vector3, Vector4, DoubleSide, BackSide, FrontSide, SRGBColorSpace, NoColorSpace, NoToneMapping, LinearFilter, LinearSRGBColorSpace, RenderTarget, HalfFloatType, RGBAFormat } from 'three';
import { NodeMaterial } from '../../nodes/Nodes.js';
import QuadMesh from '../../objects/QuadMesh.js';

const _scene = new Scene();
const _drawingBufferSize = new Vector2();
const _screen = new Vector4();
const _frustum = new Frustum();
const _projScreenMatrix = new Matrix4();
const _vector3 = new Vector3();
const _quad = new QuadMesh( new NodeMaterial() );


class Renderer {

	constructor( backend, parameters = {} ) {

		this.isRenderer = true;

		//

		const {
			logarithmicDepthBuffer = false,
			alpha = true
		} = parameters;

		// public

		this.domElement = backend.getDomElement();

		this.backend = backend;

		this.autoClear = true;
		this.autoClearColor = true;
		this.autoClearDepth = true;
		this.autoClearStencil = true;

		this.alpha = alpha;

		this.logarithmicDepthBuffer = logarithmicDepthBuffer;

		this.outputColorSpace = SRGBColorSpace;

		this.toneMapping = NoToneMapping;
		this.toneMappingExposure = 1.0;

		this.sortObjects = true;

		this.depth = true;
		this.stencil = false;

		this.clippingPlanes = [];

		this.info = new Info();

		// nodes

		this.toneMappingNode = null;

		// internals

		this._pixelRatio = 1;
		this._width = this.domElement.width;
		this._height = this.domElement.height;

		this._viewport = new Vector4( 0, 0, this._width, this._height );
		this._scissor = new Vector4( 0, 0, this._width, this._height );
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

		const alphaClear = this.alpha === true ? 0 : 1;

		this._clearColor = new Color4( 0, 0, 0, alphaClear );
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

		// backwards compatibility

		this.shadowMap = {
			enabled: false,
			type: null
		};

		this.xr = {
			enabled: false
		};

	}
async init() {

		if ( this._initialized ) {

			throw new Error( 'Renderer: Backend has already been initialized.' );

		}

		if ( this._initPromise !== null ) {

			return this._initPromise;

		}

		this._initPromise = new Promise( async ( resolve, reject ) => {

			const backend = this.backend;

			try {

				await backend.init( this );

			} catch ( error ) {

				reject( error );
				return;

			}

			this._nodes = new Nodes( this, backend );
			this._animation = new Animation( this._nodes, this.info );
			this._attributes = new Attributes( backend );
			this._background = new Background( this, this._nodes );
			this._geometries = new Geometries( this._attributes, this.info );
			this._textures = new Textures( this, backend, this.info );
			this._pipelines = new Pipelines( backend, this._nodes );
			this._bindings = new Bindings( backend, this._nodes, this._textures, this._attributes, this._pipelines, this.info );
			this._objects = new RenderObjects( this, this._nodes, this._geometries, this._pipelines, this._bindings, this.info );
			this._renderLists = new RenderLists();
			this._renderContexts = new RenderContexts();

			//

			this._initialized = true;

			resolve();

		} );

		return this._initPromise;

	}
get coordinateSystem() {

		return this.backend.coordinateSystem;

	}
async compileAsync( scene, camera, targetScene = null ) {

		if ( this._initialized === false ) await this.init();

		// preserve render tree

		const nodeFrame = this._nodes.nodeFrame;

		const previousRenderId = nodeFrame.renderId;
		const previousRenderContext = this._currentRenderContext;
		const previousRenderObjectFunction = this._currentRenderObjectFunction;
		const previousCompilationPromises = this._compilationPromises;

		//

		const sceneRef = ( scene.isScene === true ) ? scene : _scene;

		if ( targetScene === null ) targetScene = scene;

		const renderTarget = this._renderTarget;
		const renderContext = this._renderContexts.get( targetScene, camera, renderTarget );
		const activeMipmapLevel = this._activeMipmapLevel;

		const compilationPromises = [];

		this._currentRenderContext = renderContext;
		this._currentRenderObjectFunction = this.renderObject;

		this._handleObjectFunction = this._createObjectPipeline;

		this._compilationPromises = compilationPromises;

		nodeFrame.renderId ++;

		//

		nodeFrame.update();

		//

		renderContext.depth = this.depth;
		renderContext.stencil = this.stencil;

		if ( ! renderContext.clippingContext ) renderContext.clippingContext = new ClippingContext();
		renderContext.clippingContext.updateGlobal( this, camera );

		//

		sceneRef.onBeforeRender( this, scene, camera, renderTarget );

		//

		const renderList = this._renderLists.get( scene, camera );
		renderList.begin();

		this._projectObject( scene, camera, 0, renderList );

		// include lights from target scene
		if ( targetScene !== scene ) {

			targetScene.traverseVisible( function ( object ) {

				if ( object.isLight && object.layers.test( camera.layers ) ) {

					renderList.pushLight( object );

				}

			} );

		}

		renderList.finish();

		//

		if ( renderTarget !== null ) {

			this._textures.updateRenderTarget( renderTarget, activeMipmapLevel );

			const renderTargetData = this._textures.get( renderTarget );

			renderContext.textures = renderTargetData.textures;
			renderContext.depthTexture = renderTargetData.depthTexture;

		} else {

			renderContext.textures = null;
			renderContext.depthTexture = null;

		}

		//

		this._nodes.updateScene( sceneRef );

		//

		this._background.update( sceneRef, renderList, renderContext );

		// process render lists

		const opaqueObjects = renderList.opaque;
		const transparentObjects = renderList.transparent;
		const lightsNode = renderList.lightsNode;

		if ( opaqueObjects.length > 0 ) this._renderObjects( opaqueObjects, camera, sceneRef, lightsNode );
		if ( transparentObjects.length > 0 ) this._renderObjects( transparentObjects, camera, sceneRef, lightsNode );

		// restore render tree

		nodeFrame.renderId = previousRenderId;

		this._currentRenderContext = previousRenderContext;
		this._currentRenderObjectFunction = previousRenderObjectFunction;
		this._compilationPromises = previousCompilationPromises;

		this._handleObjectFunction = this._renderObjectDirect;

		// wait for all promises setup by backends awaiting compilation/linking/pipeline creation to complete

		await Promise.all( compilationPromises );

	}
async renderAsync( scene, camera ) {

		if ( this._initialized === false ) await this.init();

		const renderContext = this._renderScene( scene, camera );

		await this.backend.resolveTimestampAsync( renderContext, 'render' );

	}
render( scene, camera ) {

		if ( this._initialized === false ) {

			console.warn( 'THREE.Renderer: .render() called before the backend is initialized. Try using .renderAsync() instead.' );

			return this.renderAsync( scene, camera );

		}

		this._renderScene( scene, camera );

	}
_getFrameBufferTarget() {

		const { currentColorSpace } = this;

		const useToneMapping = this._renderTarget === null && ( this.toneMapping !== NoToneMapping || this.toneMappingNode !== null );
		const useColorSpace = currentColorSpace !== LinearSRGBColorSpace && currentColorSpace !== NoColorSpace;

		if ( useToneMapping === false && useColorSpace === false ) return null;

		const { width, height } = this.getDrawingBufferSize( _drawingBufferSize );
		const { depth, stencil } = this;

		let frameBufferTarget = this._frameBufferTarget;

		if ( frameBufferTarget === null ) {

			frameBufferTarget = new RenderTarget( width, height, {
				depthBuffer: depth,
				stencilBuffer: stencil,
				type: HalfFloatType, // FloatType
				format: RGBAFormat,
				colorSpace: LinearSRGBColorSpace,
				generateMipmaps: false,
				minFilter: LinearFilter,
				magFilter: LinearFilter,
				samples: this.backend.parameters.antialias ? 4 : 0
			} );

			frameBufferTarget.isPostProcessingRenderTarget = true;

			this._frameBufferTarget = frameBufferTarget;

		}

		frameBufferTarget.depthBuffer = depth;
		frameBufferTarget.stencilBuffer = stencil;
		frameBufferTarget.setSize( width, height );
		frameBufferTarget.viewport.copy( this._viewport );
		frameBufferTarget.scissor.copy( this._scissor );
		frameBufferTarget.viewport.multiplyScalar( this._pixelRatio );
		frameBufferTarget.scissor.multiplyScalar( this._pixelRatio );
		frameBufferTarget.scissorTest = this._scissorTest;

		return frameBufferTarget;

	}
_renderScene( scene, camera, useFrameBufferTarget = true ) {

		const frameBufferTarget = useFrameBufferTarget ? this._getFrameBufferTarget() : null;

		// preserve render tree

		const nodeFrame = this._nodes.nodeFrame;

		const previousRenderId = nodeFrame.renderId;
		const previousRenderContext = this._currentRenderContext;
		const previousRenderObjectFunction = this._currentRenderObjectFunction;

		//

		const sceneRef = ( scene.isScene === true ) ? scene : _scene;

		const outputRenderTarget = this._renderTarget;

		const activeCubeFace = this._activeCubeFace;
		const activeMipmapLevel = this._activeMipmapLevel;

		//

		let renderTarget;

		if ( frameBufferTarget !== null ) {

			renderTarget = frameBufferTarget;

			this.setRenderTarget( renderTarget );

		} else {

			renderTarget = outputRenderTarget;

		}

		//

		const renderContext = this._renderContexts.get( scene, camera, renderTarget );

		this._currentRenderContext = renderContext;
		this._currentRenderObjectFunction = this._renderObjectFunction || this.renderObject;

		//

		this.info.calls ++;
		this.info.render.calls ++;

		nodeFrame.renderId = this.info.calls;

		//

		const coordinateSystem = this.coordinateSystem;

		if ( camera.coordinateSystem !== coordinateSystem ) {

			camera.coordinateSystem = coordinateSystem;

			camera.updateProjectionMatrix();

		}

		//

		if ( scene.matrixWorldAutoUpdate === true ) scene.updateMatrixWorld();

		if ( camera.parent === null && camera.matrixWorldAutoUpdate === true ) camera.updateMatrixWorld();


		//

		let viewport = this._viewport;
		let scissor = this._scissor;
		let pixelRatio = this._pixelRatio;

		if ( renderTarget !== null ) {

			viewport = renderTarget.viewport;
			scissor = renderTarget.scissor;
			pixelRatio = 1;

		}

		this.getDrawingBufferSize( _drawingBufferSize );

		_screen.set( 0, 0, _drawingBufferSize.width, _drawingBufferSize.height );

		const minDepth = ( viewport.minDepth === undefined ) ? 0 : viewport.minDepth;
		const maxDepth = ( viewport.maxDepth === undefined ) ? 1 : viewport.maxDepth;

		renderContext.viewportValue.copy( viewport ).multiplyScalar( pixelRatio ).floor();
		renderContext.viewportValue.width >>= activeMipmapLevel;
		renderContext.viewportValue.height >>= activeMipmapLevel;
		renderContext.viewportValue.minDepth = minDepth;
		renderContext.viewportValue.maxDepth = maxDepth;
		renderContext.viewport = renderContext.viewportValue.equals( _screen ) === false;

		renderContext.scissorValue.copy( scissor ).multiplyScalar( pixelRatio ).floor();
		renderContext.scissor = this._scissorTest && renderContext.scissorValue.equals( _screen ) === false;
		renderContext.scissorValue.width >>= activeMipmapLevel;
		renderContext.scissorValue.height >>= activeMipmapLevel;

		if ( ! renderContext.clippingContext ) renderContext.clippingContext = new ClippingContext();
		renderContext.clippingContext.updateGlobal( this, camera );

		//

		sceneRef.onBeforeRender( this, scene, camera, renderTarget );

		//

		_projScreenMatrix.multiplyMatrices( camera.projectionMatrix, camera.matrixWorldInverse );
		_frustum.setFromProjectionMatrix( _projScreenMatrix, coordinateSystem );

		const renderList = this._renderLists.get( scene, camera );
		renderList.begin();

		this._projectObject( scene, camera, 0, renderList );

		renderList.finish();

		if ( this.sortObjects === true ) {

			renderList.sort( this._opaqueSort, this._transparentSort );

		}

		//

		if ( renderTarget !== null ) {

			this._textures.updateRenderTarget( renderTarget, activeMipmapLevel );

			const renderTargetData = this._textures.get( renderTarget );

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

		//

		this._nodes.updateScene( sceneRef );

		//

		this._background.update( sceneRef, renderList, renderContext );

		//

		this.backend.beginRender( renderContext );

		// process render lists

		const opaqueObjects = renderList.opaque;
		const transparentObjects = renderList.transparent;
		const lightsNode = renderList.lightsNode;

		if ( opaqueObjects.length > 0 ) this._renderObjects( opaqueObjects, camera, sceneRef, lightsNode );
		if ( transparentObjects.length > 0 ) this._renderObjects( transparentObjects, camera, sceneRef, lightsNode );

		// finish render pass

		this.backend.finishRender( renderContext );

		// restore render tree

		nodeFrame.renderId = previousRenderId;

		this._currentRenderContext = previousRenderContext;
		this._currentRenderObjectFunction = previousRenderObjectFunction;

		//

		if ( frameBufferTarget !== null ) {

			this.setRenderTarget( outputRenderTarget, activeCubeFace, activeMipmapLevel );

			_quad.material.fragmentNode = this._nodes.getOutputNode( renderTarget.texture );

			this._renderScene( _quad, _quad.camera, false );

		}

		//

		sceneRef.onAfterRender( this, scene, camera, renderTarget );

		//

		return renderContext;

	}