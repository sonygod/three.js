import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Vector3;
import three.math.Vector4;
import three.webgl.WebGLAnimation;
import three.webgl.WebGLAttributes;
import three.webgl.WebGLBackground;
import three.webgl.WebGLBindingStates;
import three.webgl.WebGLBufferRenderer;
import three.webgl.WebGLCapabilities;
import three.webgl.WebGLClipping;
import three.webgl.WebGLCubeMaps;
import three.webgl.WebGLCubeUVMaps;
import three.webgl.WebGLExtensions;
import three.webgl.WebGLGeometries;
import three.webgl.WebGLIndexedBufferRenderer;
import three.webgl.WebGLInfo;
import three.webgl.WebGLMorphtargets;
import three.webgl.WebGLObjects;
import three.webgl.WebGLPrograms;
import three.webgl.WebGLProperties;
import three.webgl.WebGLRenderLists;
import three.webgl.WebGLRenderStates;
import three.webgl.WebGLRenderTarget;
import three.webgl.WebGLShadowMap;
import three.webgl.WebGLState;
import three.webgl.WebGLTextures;
import three.webgl.WebGLUniforms;
import three.webgl.WebGLUtils;
import three.webgl.WebXRManager;
import three.webgl.WebGLMaterials;
import three.webgl.WebGLUniformsGroups;
import three.utils.createCanvasElement;
import three.utils.probeAsync;
import three.math.ColorManagement;

class WebGLRenderer {

	public var isWebGLRenderer:Bool;

	public function new(parameters:Object = null) {
		var _alpha;
		var uintClearColor = new Uint32Array(4);
		var intClearColor = new Int32Array(4);
		var currentRenderList = null;
		var currentRenderState = null;
		var renderListStack = [];
		var renderStateStack = [];
		this.domElement = createCanvasElement();
		var _this = this;
		var _isContextLost = false;
		var _currentActiveCubeFace = 0;
		var _currentActiveMipmapLevel = 0;
		var _currentRenderTarget = null;
		var _currentMaterialId = -1;
		var _currentCamera = null;
		var _currentViewport = new Vector4();
		var _currentScissor = new Vector4();
		var _currentClearColor = new Color(0x000000);
		var _currentClearAlpha = 0;
		var _width = canvas.width;
		var _height = canvas.height;
		var _pixelRatio = 1;
		var _opaqueSort = null;
		var _transparentSort = null;
		var _viewport = new Vector4(0, 0, _width, _height);
		var _scissor = new Vector4(0, 0, _width, _height);
		var _frustum = new Frustum();
		var _clippingEnabled = false;
		var _localClippingEnabled = false;
		var _projScreenMatrix = new Matrix4();
		var _vector3 = new Vector3();
		var _emptyScene = {background:null, fog:null, environment:null, overrideMaterial:null, isScene:true};
		var getTargetPixelRatio = function () {
			return _currentRenderTarget === null ? _pixelRatio : 1;
		};
		var getContext = function (contextName:String, contextAttributes:Object) {
			return canvas.getContext(contextName, contextAttributes);
		};
		try {
			var contextAttributes = {
				alpha:true,
				depth:true,
				stencil:false,
				antialias:false,
				premultipliedAlpha:true,
				preserveDrawingBuffer:false,
				powerPreference:'default',
				failIfMajorPerformanceCaveat:false,
			};
			canvas.setAttribute('data-engine', `three.js r${REVISION}`);
			canvas.addEventListener('webglcontextlost', onContextLost, false);
			canvas.addEventListener('webglcontextrestored', onContextRestore, false);
			canvas.addEventListener('webglcontextcreationerror', onContextCreationError, false);
			var context = getContext('webgl2', contextAttributes);
			if (context === null) {
				if (getContext(contextName)) {
					throw new Error('Error creating WebGL context with your selected attributes.');
				} else {
					throw new Error('Error creating WebGL context.');
				}
			}
		} catch (error:Error) {
			console.error('THREE.WebGLRenderer: ' + error.message);
			throw error;
		}
		var extensions, capabilities, state, info;
		var properties, textures, cubemaps, cubeuvmaps, attributes, geometries, objects;
		var programCache, materials, renderLists, renderStates, clipping, shadowMap;
		var background, morphtargets, bufferRenderer, indexedBufferRenderer;
		var utils, bindingStates, uniformsGroups;
		initGLContext();
		var xr = new WebXRManager(this, _gl);
		this.xr = xr;
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
			_this.capabilities = capabilities;
			_this.extensions = extensions;
			_this.properties = properties;
			_this.renderLists = renderLists;
			_this.shadowMap = shadowMap;
			_this.state = state;
			_this.info = info;
		}
		// xr
		const xr = new WebXRManager(this, _gl);
		this.xr = xr;
		// API
		public function getContext():WebGLRenderingContext {
			return _gl;
		}
		public function getContextAttributes():Object {
			return _gl.getContextAttributes();
		}
		public function forceContextLoss() {
			const extension = extensions.get('WEBGL_lose_context');
			if (extension) extension.loseContext();
		}
		public function forceContextRestore() {
			const extension = extensions.get('WEBGL_lose_context');
			if (extension) extension.restoreContext();
		}
		public function getPixelRatio():Float {
			return _pixelRatio;
		}
		public function setPixelRatio(value:Float) {
			if (value === undefined) return;
			_pixelRatio = value;
			this.setSize(_width, _height, false);
		}
		public function getSize(target:Vector4):Vector4 {
			return target.set(_width, _height);
		}
		public function setSize(width:Int, height:Int, updateStyle:Bool = true) {
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
		public function getDrawingBufferSize(target:Vector4):Vector4 {
			return target.set(_width * _pixelRatio, _height * _pixelRatio).floor();
		}
		public function setDrawingBufferSize(width:Int, height:Int, pixelRatio:Float) {
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
		public function setViewport(x:Int, y:Int, width:Int, height:Int) {
			if (x.isVector4) {
				_currentViewport.set(x.x, x.y, x.z, x.w);
			} else {
				_currentViewport.set(x, y, width, height);
			}
			state.viewport(_currentViewport.copy(_currentViewport).multiplyScalar(_pixelRatio).round());
		}
		public function getScissor(target:Vector4):Vector4 {
			return target.copy(_scissor);
		}
		public function setScissor(x:Int, y:Int, width:Int, height:Int) {
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
		public function setScissorTest(boolean:Bool) {
			state.setScissorTest(_scissorTest = boolean);
		}
		public function setOpaqueSort(method:Function) {
			_opaqueSort = method;
		}
		public function setTransparentSort(method:Function) {
			_transparentSort = method;
		}
		// Clearing
		public function clear(color:Bool = true, depth:Bool = true, stencil:Bool = true) {
			var bits = 0;
			if (color) {
				// check if we're trying to clear an integer target
				var isIntegerFormat = false;
				if (_currentRenderTarget !== null) {
					var targetFormat = _currentRenderTarget.texture.format;
					isIntegerFormat = targetFormat === RGBAIntegerFormat ||
						targetFormat === RGIntegerFormat ||
						targetFormat === RedIntegerFormat;
				}
				// use the appropriate clear functions to clear the target if it's a signed
				// or unsigned integer target
				if (isIntegerFormat) {
					var targetType = _currentRenderTarget.texture.type;
					var isUnsignedType = targetType === UnsignedByteType ||
						targetType === UnsignedIntType ||
						targetType === UnsignedShortType ||
						targetType === UnsignedInt248Type ||
						targetType === UnsignedShort4444Type ||
						targetType === UnsignedShort5551Type;
					var clearColor = background.getClearColor();
					var a = background.getClearAlpha();
					var r = clearColor.r;
					var g = clearColor.g;
					var b = clearColor.b;
					if (isUnsignedType) {
						uintClearColor[0] = r;
						uintClearColor[1] = g;
						uintClearColor[2] = b;
						uintClearColor[3] = a;
						_gl.clearBufferuiv(_gl.COLOR, 0, uintClearColor);
					} else {
						intClearColor[0] = r;
						intClearColor[1] = g;
						intClearColor[2] = b;
						intClearColor[3] = a;
						_gl.clearBufferiv(_gl.COLOR, 0, intClearColor);
					}
				} else {
					bits |= _gl.COLOR_BUFFER_BIT;
				}
			}
			if (depth) bits |= _gl.DEPTH_BUFFER_BIT;
			if (stencil) {
				bits |= _gl.STENCIL_BUFFER_BIT;
				this.state.buffers.stencil.setMask(0xffffffff);
			}
			_gl.clear(bits);
		}
		public function clearColor() {
			this.clear(true, false, false);
		}
		public function clearDepth() {
			this.clear(false, true, false);
		}
		public function clearStencil() {
			this.clear(false, false, true);
		}
		//
		public function dispose() {
			canvas.removeEventListener('webglcontextlost', onContextLost, false);
			canvas.removeEventListener('webglcontextrestored', onContextRestore, false);
			canvas.removeEventListener('webglcontextcreationerror', onContextCreationError, false);
			renderLists.dispose();
			renderStates.dispose();
			properties.dispose();
			cubemaps.dispose();
			cubeuvmaps.dispose();
			objects.dispose();
			bindingStates.dispose();
			uniformsGroups.dispose();
			programCache.dispose();
			xr.dispose();
			xr.removeEventListener('sessionstart', onXRSessionStart);
			xr.removeEventListener('sessionend', onXRSessionEnd);
			animation.stop();
		}
		// Events
		function onContextLost(event) {
			event.preventDefault();
			console.log('THREE.WebGLRenderer: Context Lost.');
			_isContextLost = true;
		}
		function onContextRestore(/* event */) {
			console.log('THREE.WebGLRenderer: Context Restored.');
			_isContextLost = false;
		}
		function onContextCreationError(event) {
			console.error('THREE.WebGLRenderer: A WebGL context could not be created. Reason: ', event.statusMessage);
		}
		function onMaterialDispose(event) {
			const material = event.target;
			material.removeEventListener('dispose', onMaterialDispose);
			deallocateMaterial(material);
		}
		function deallocateMaterial(material) {
			releaseMaterialProgramReferences(material);
			properties.remove(material);
		}
		function