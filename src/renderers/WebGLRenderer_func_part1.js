import {
	REVISION,
	BackSide,
	FrontSide,
	DoubleSide,
	HalfFloatType,
	UnsignedByteType,
	NoToneMapping,
	LinearMipmapLinearFilter,
	SRGBColorSpace,
	LinearSRGBColorSpace,
	RGBAIntegerFormat,
	RGIntegerFormat,
	RedIntegerFormat,
	UnsignedIntType,
	UnsignedShortType,
	UnsignedInt248Type,
	UnsignedShort4444Type,
	UnsignedShort5551Type,
	WebGLCoordinateSystem,
	DisplayP3ColorSpace,
	LinearDisplayP3ColorSpace
} from '../constants.js';
import { Color } from '../math/Color.js';
import { Frustum } from '../math/Frustum.js';
import { Matrix4 } from '../math/Matrix4.js';
import { Vector3 } from '../math/Vector3.js';
import { Vector4 } from '../math/Vector4.js';
import { WebGLAnimation } from './webgl/WebGLAnimation.js';
import { WebGLAttributes } from './webgl/WebGLAttributes.js';
import { WebGLBackground } from './webgl/WebGLBackground.js';
import { WebGLBindingStates } from './webgl/WebGLBindingStates.js';
import { WebGLBufferRenderer } from './webgl/WebGLBufferRenderer.js';
import { WebGLCapabilities } from './webgl/WebGLCapabilities.js';
import { WebGLClipping } from './webgl/WebGLClipping.js';
import { WebGLCubeMaps } from './webgl/WebGLCubeMaps.js';
import { WebGLCubeUVMaps } from './webgl/WebGLCubeUVMaps.js';
import { WebGLExtensions } from './webgl/WebGLExtensions.js';
import { WebGLGeometries } from './webgl/WebGLGeometries.js';
import { WebGLIndexedBufferRenderer } from './webgl/WebGLIndexedBufferRenderer.js';
import { WebGLInfo } from './webgl/WebGLInfo.js';
import { WebGLMorphtargets } from './webgl/WebGLMorphtargets.js';
import { WebGLObjects } from './webgl/WebGLObjects.js';
import { WebGLPrograms } from './webgl/WebGLPrograms.js';
import { WebGLProperties } from './webgl/WebGLProperties.js';
import { WebGLRenderLists } from './webgl/WebGLRenderLists.js';
import { WebGLRenderStates } from './webgl/WebGLRenderStates.js';
import { WebGLRenderTarget } from './WebGLRenderTarget.js';
import { WebGLShadowMap } from './webgl/WebGLShadowMap.js';
import { WebGLState } from './webgl/WebGLState.js';
import { WebGLTextures } from './webgl/WebGLTextures.js';
import { WebGLUniforms } from './webgl/WebGLUniforms.js';
import { WebGLUtils } from './webgl/WebGLUtils.js';
import { WebXRManager } from './webxr/WebXRManager.js';
import { WebGLMaterials } from './webgl/WebGLMaterials.js';
import { WebGLUniformsGroups } from './webgl/WebGLUniformsGroups.js';
import { createCanvasElement, probeAsync } from '../utils.js';
import { ColorManagement } from '../math/ColorManagement.js';


constructor( parameters = {} ) {

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

		this.isWebGLRenderer = true;

		let _alpha;

		if ( context !== null ) {

			if ( typeof WebGLRenderingContext !== 'undefined' && context instanceof WebGLRenderingContext ) {

				throw new Error( 'THREE.WebGLRenderer: WebGL 1 is not supported since r163.' );

			}

			_alpha = context.getContextAttributes().alpha;

		} else {

			_alpha = alpha;

		}

		const uintClearColor = new Uint32Array( 4 );
		const intClearColor = new Int32Array( 4 );

		let currentRenderList = null;
		let currentRenderState = null;

		// render() can be called from within a callback triggered by another render.
		// We track this so that the nested render call gets its list and state isolated from the parent render call.

		const renderListStack = [];
		const renderStateStack = [];

		// public properties

		this.domElement = canvas;

		// Debug configuration container
		this.debug = {

			/**
			 * Enables error checking and reporting when shader programs are being compiled
			 * @type {boolean}
			 */
			checkShaderErrors: true,
			/**
			 * Callback for custom error reporting.
			 * @type {?Function}
			 */
			onShaderError: null
		};

		// clearing

		this.autoClear = true;
		this.autoClearColor = true;
		this.autoClearDepth = true;
		this.autoClearStencil = true;

		// scene graph

		this.sortObjects = true;

		// user-defined clipping

		this.clippingPlanes = [];
		this.localClippingEnabled = false;

		// physically based shading

		this._outputColorSpace = SRGBColorSpace;

		// physical lights

		this._useLegacyLights = false;

		// tone mapping

		this.toneMapping = NoToneMapping;
		this.toneMappingExposure = 1.0;

		// internal properties

		const _this = this;

		let _isContextLost = false;

		// internal state cache

		let _currentActiveCubeFace = 0;
		let _currentActiveMipmapLevel = 0;
		let _currentRenderTarget = null;
		let _currentMaterialId = - 1;

		let _currentCamera = null;

		const _currentViewport = new Vector4();
		const _currentScissor = new Vector4();
		let _currentScissorTest = null;

		const _currentClearColor = new Color( 0x000000 );
		let _currentClearAlpha = 0;

		//

		let _width = canvas.width;
		let _height = canvas.height;

		let _pixelRatio = 1;
		let _opaqueSort = null;
		let _transparentSort = null;

		const _viewport = new Vector4( 0, 0, _width, _height );
		const _scissor = new Vector4( 0, 0, _width, _height );
		let _scissorTest = false;

		// frustum

		const _frustum = new Frustum();

		// clipping

		let _clippingEnabled = false;
		let _localClippingEnabled = false;

		// camera matrices cache

		const _projScreenMatrix = new Matrix4();

		const _vector3 = new Vector3();

		const _emptyScene = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

		function getTargetPixelRatio() {

			return _currentRenderTarget === null ? _pixelRatio : 1;

		}

		// initialize

		let _gl = context;

		function getContext( contextName, contextAttributes ) {

			return canvas.getContext( contextName, contextAttributes );

		}

		try {

			const contextAttributes = {
				alpha: true,
				depth,
				stencil,
				antialias,
				premultipliedAlpha,
				preserveDrawingBuffer,
				powerPreference,
				failIfMajorPerformanceCaveat,
			};

			// OffscreenCanvas does not have setAttribute, see #22811
			if ( 'setAttribute' in canvas ) canvas.setAttribute( 'data-engine', `three.js r${REVISION}` );

			// event listeners must be registered before WebGL context is created, see #12753
			canvas.addEventListener( 'webglcontextlost', onContextLost, false );
			canvas.addEventListener( 'webglcontextrestored', onContextRestore, false );
			canvas.addEventListener( 'webglcontextcreationerror', onContextCreationError, false );

			if ( _gl === null ) {

				const contextName = 'webgl2';

				_gl = getContext( contextName, contextAttributes );

				if ( _gl === null ) {

					if ( getContext( contextName ) ) {

						throw new Error( 'Error creating WebGL context with your selected attributes.' );

					} else {

						throw new Error( 'Error creating WebGL context.' );

					}

				}

			}

		} catch ( error ) {

			console.error( 'THREE.WebGLRenderer: ' + error.message );
			throw error;

		}

		let extensions, capabilities, state, info;
		let properties, textures, cubemaps, cubeuvmaps, attributes, geometries, objects;
		let programCache, materials, renderLists, renderStates, clipping, shadowMap;

		let background, morphtargets, bufferRenderer, indexedBufferRenderer;

		let utils, bindingStates, uniformsGroups;

		function initGLContext() {

			extensions = new WebGLExtensions( _gl );
			extensions.init();

			utils = new WebGLUtils( _gl, extensions );

			capabilities = new WebGLCapabilities( _gl, extensions, parameters, utils );

			state = new WebGLState( _gl );

			info = new WebGLInfo( _gl );
			properties = new WebGLProperties();
			textures = new WebGLTextures( _gl, extensions, state, properties, capabilities, utils, info );
			cubemaps = new WebGLCubeMaps( _this );
			cubeuvmaps = new WebGLCubeUVMaps( _this );
			attributes = new WebGLAttributes( _gl );
			bindingStates = new WebGLBindingStates( _gl, attributes );
			geometries = new WebGLGeometries( _gl, attributes, info, bindingStates );
			objects = new WebGLObjects( _gl, geometries, attributes, info );
			morphtargets = new WebGLMorphtargets( _gl, capabilities, textures );
			clipping = new WebGLClipping( properties );
			programCache = new WebGLPrograms( _this, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping );
			materials = new WebGLMaterials( _this, properties );
			renderLists = new WebGLRenderLists();
			renderStates = new WebGLRenderStates( extensions );
			background = new WebGLBackground( _this, cubemaps, cubeuvmaps, state, objects, _alpha, premultipliedAlpha );
			shadowMap = new WebGLShadowMap( _this, objects, capabilities );
			uniformsGroups = new WebGLUniformsGroups( _gl, info, capabilities, state );

			bufferRenderer = new WebGLBufferRenderer( _gl, extensions, info );
			indexedBufferRenderer = new WebGLIndexedBufferRenderer( _gl, extensions, info );

			info.programs = programCache.programs;

			_this.capabilities = capabilities;
			_this.extensions = extensions;
			_this.properties = properties;
			_this.renderLists = renderLists;
			_this.shadowMap = shadowMap;
			_this.state = state;
			_this.info = info;

		}

		initGLContext();

		// xr

		const xr = new WebXRManager( _this, _gl );

		this.xr = xr;

		// API

		this.getContext = function () {

			return _gl;

		};

		this.getContextAttributes = function () {

			return _gl.getContextAttributes();

		};

		this.forceContextLoss = function () {

			const extension = extensions.get( 'WEBGL_lose_context' );
			if ( extension ) extension.loseContext();

		};

		this.forceContextRestore = function () {

			const extension = extensions.get( 'WEBGL_lose_context' );
			if ( extension ) extension.restoreContext();

		};

		this.getPixelRatio = function () {

			return _pixelRatio;

		};

		this.setPixelRatio = function ( value ) {

			if ( value === undefined ) return;

			_pixelRatio = value;

			this.setSize( _width, _height, false );

		};

		this.getSize = function ( target ) {

			return target.set( _width, _height );

		};

		this.setSize = function ( width, height, updateStyle = true ) {

			if ( xr.isPresenting ) {

				console.warn( 'THREE.WebGLRenderer: Can\'t change size while VR device is presenting.' );
				return;

			}

			_width = width;
			_height = height;

			canvas.width = Math.floor( width * _pixelRatio );
			canvas.height = Math.floor( height * _pixelRatio );

			if ( updateStyle === true ) {

				canvas.style.width = width + 'px';
				canvas.style.height = height + 'px';

			}

			this.setViewport( 0, 0, width, height );

		};

		this.getDrawingBufferSize = function ( target ) {

			return target.set( _width * _pixelRatio, _height * _pixelRatio ).floor();

		};

		this.setDrawingBufferSize = function ( width, height, pixelRatio ) {

			_width = width;
			_height = height;

			_pixelRatio = pixelRatio;

			canvas.width = Math.floor( width * pixelRatio );
			canvas.height = Math.floor( height * pixelRatio );

			this.setViewport( 0, 0, width, height );

		};

		this.getCurrentViewport = function ( target ) {

			return target.copy( _currentViewport );

		};

		this.getViewport = function ( target ) {

			return target.copy( _viewport );

		};

		this.setViewport = function ( x, y, width, height ) {

			if ( x.isVector4 ) {

				_viewport.set( x.x, x.y, x.z, x.w );

			} else {

				_viewport.set( x, y, width, height );

			}

			state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

		};

		this.getScissor = function ( target ) {

			return target.copy( _scissor );

		};

		this.setScissor = function ( x, y, width, height ) {

			if ( x.isVector4 ) {

				_scissor.set( x.x, x.y, x.z, x.w );

			} else {

				_scissor.set( x, y, width, height );

			}

			state.scissor( _currentScissor.copy( _scissor ).multiplyScalar( _pixelRatio ).round() );

		};

		this.getScissorTest = function () {

			return _scissorTest;

		};

		this.setScissorTest = function ( boolean ) {

			state.setScissorTest( _scissorTest = boolean );

		};

		this.setOpaqueSort = function ( method ) {

			_opaqueSort = method;

		};

		this.setTransparentSort = function ( method ) {

			_transparentSort = method;

		};

		// Clearing

		this.getClearColor = function ( target ) {

			return target.copy( background.getClearColor() );

		};

		this.setClearColor = function () {

			background.setClearColor.apply( background, arguments );

		};

		this.getClearAlpha = function () {

			return background.getClearAlpha();

		};

		this.setClearAlpha = function () {

			background.setClearAlpha.apply( background, arguments );

		};

		this.clear = function ( color = true, depth = true, stencil = true ) {

			let bits = 0;

			if ( color ) {

				// check if we're trying to clear an integer target
				let isIntegerFormat = false;
				if ( _currentRenderTarget !== null ) {

					const targetFormat = _currentRenderTarget.texture.format;
					isIntegerFormat = targetFormat === RGBAIntegerFormat ||
						targetFormat === RGIntegerFormat ||
						targetFormat === RedIntegerFormat;

				}

				// use the appropriate clear functions to clear the target if it's a signed
				// or unsigned integer target
				if ( isIntegerFormat ) {

					const targetType = _currentRenderTarget.texture.type;
					const isUnsignedType = targetType === UnsignedByteType ||
						targetType === UnsignedIntType ||
						targetType === UnsignedShortType ||
						targetType === UnsignedInt248Type ||
						targetType === UnsignedShort4444Type ||
						targetType === UnsignedShort5551Type;
