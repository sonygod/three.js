import three.constants.Constants;
import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Vector3;
import three.math.Vector4;
import three.renderers.WebGLRenderer;
import three.utils.Utils;
import three.math.ColorManagement;
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
import three.webxr.WebXRManager;
import three.webgl.WebGLMaterials;
import three.webgl.WebGLUniformsGroups;

class WebGLRenderer {
  public var isWebGLRenderer:Bool = true;

  public var domElement:html.CanvasElement;
  public var debug:Debug;
  public var autoClear:Bool = true;
  public var autoClearColor:Bool = true;
  public var autoClearDepth:Bool = true;
  public var autoClearStencil:Bool = true;
  public var sortObjects:Bool = true;
  public var clippingPlanes:Array<Dynamic> = [];
  public var localClippingEnabled:Bool = false;
  public var _outputColorSpace:Int = Constants.SRGBColorSpace;
  public var _useLegacyLights:Bool = false;
  public var toneMapping:Int = Constants.NoToneMapping;
  public var toneMappingExposure:Float = 1.0;

  public var capabilities:WebGLCapabilities;
  public var extensions:WebGLExtensions;
  public var properties:WebGLProperties;
  public var renderLists:WebGLRenderLists;
  public var shadowMap:WebGLShadowMap;
  public var state:WebGLState;
  public var info:WebGLInfo;
  public var xr:WebXRManager;

  private var _isContextLost:Bool = false;

  private var _currentActiveCubeFace:Int = 0;
  private var _currentActiveMipmapLevel:Int = 0;
  private var _currentRenderTarget:WebGLRenderTarget = null;
  private var _currentMaterialId:Int = - 1;

  private var _currentCamera:Dynamic = null;

  private var _currentViewport:Vector4 = new Vector4();
  private var _currentScissor:Vector4 = new Vector4();
  private var _currentScissorTest:Dynamic = null;

  private var _currentClearColor:Color = new Color(0x000000);
  private var _currentClearAlpha:Float = 0;

  private var _width:Int;
  private var _height:Int;

  private var _pixelRatio:Float = 1;
  private var _opaqueSort:Dynamic = null;
  private var _transparentSort:Dynamic = null;

  private var _viewport:Vector4 = new Vector4(0, 0, _width, _height);
  private var _scissor:Vector4 = new Vector4(0, 0, _width, _height);
  private var _scissorTest:Bool = false;

  private var _frustum:Frustum = new Frustum();
  private var _clippingEnabled:Bool = false;
  private var _localClippingEnabled:Bool = false;
  private var _projScreenMatrix:Matrix4 = new Matrix4();

  private var _vector3:Vector3 = new Vector3();

  private var _emptyScene:Dynamic = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

  private var _gl:Dynamic;
  private var extensions:WebGLExtensions;
  private var capabilities:WebGLCapabilities;
  private var state:WebGLState;
  private var info:WebGLInfo;
  private var properties:WebGLProperties;
  private var textures:WebGLTextures;
  private var cubemaps:WebGLCubeMaps;
  private var cubeuvmaps:WebGLCubeUVMaps;
  private var attributes:WebGLAttributes;
  private var geometries:WebGLGeometries;
  private var objects:WebGLObjects;
  private var morphtargets:WebGLMorphtargets;
  private var clipping:WebGLClipping;
  private var programCache:WebGLPrograms;
  private var materials:WebGLMaterials;
  private var renderLists:WebGLRenderLists;
  private var renderStates:WebGLRenderStates;
  private var background:WebGLBackground;
  private var shadowMap:WebGLShadowMap;
  private var uniformsGroups:WebGLUniformsGroups;

  private var bufferRenderer:WebGLBufferRenderer;
  private var indexedBufferRenderer:WebGLIndexedBufferRenderer;

  private var utils:WebGLUtils;
  private var bindingStates:WebGLBindingStates;

  public function new(parameters:Dynamic = {}) {
    var canvas = cast(parameters.canvas, html.CanvasElement);
    if (canvas == null) canvas = Utils.createCanvasElement();
    var context = cast(parameters.context, WebGLRenderingContext);
    var depth = cast(parameters.depth, Bool);
    if (depth == null) depth = true;
    var stencil = cast(parameters.stencil, Bool);
    if (stencil == null) stencil = false;
    var alpha = cast(parameters.alpha, Bool);
    if (alpha == null) alpha = false;
    var antialias = cast(parameters.antialias, Bool);
    if (antialias == null) antialias = false;
    var premultipliedAlpha = cast(parameters.premultipliedAlpha, Bool);
    if (premultipliedAlpha == null) premultipliedAlpha = true;
    var preserveDrawingBuffer = cast(parameters.preserveDrawingBuffer, Bool);
    if (preserveDrawingBuffer == null) preserveDrawingBuffer = false;
    var powerPreference = cast(parameters.powerPreference, String);
    if (powerPreference == null) powerPreference = "default";
    var failIfMajorPerformanceCaveat = cast(parameters.failIfMajorPerformanceCaveat, Bool);
    if (failIfMajorPerformanceCaveat == null) failIfMajorPerformanceCaveat = false;

    this.domElement = canvas;
    this.debug = {
      checkShaderErrors: true,
      onShaderError: null
    };

    var uintClearColor = new Uint32Array(4);
    var intClearColor = new Int32Array(4);

    var currentRenderList:Dynamic = null;
    var currentRenderState:Dynamic = null;

    var renderListStack = [];
    var renderStateStack = [];

    var _alpha:Bool;
    if (context != null) {
      if (typeof(WebGLRenderingContext) != "undefined" && context is WebGLRenderingContext) {
        throw new Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");
      }
      _alpha = context.getContextAttributes().alpha;
    } else {
      _alpha = alpha;
    }

    this.domElement = canvas;

    var _this = this;

    var _width = canvas.width;
    var _height = canvas.height;

    var _pixelRatio = 1;
    var _opaqueSort = null;
    var _transparentSort = null;

    var _viewport = new Vector4(0, 0, _width, _height);
    var _scissor = new Vector4(0, 0, _width, _height);
    var _scissorTest = false;

    var _frustum = new Frustum();

    var _clippingEnabled = false;
    var _localClippingEnabled = false;

    var _projScreenMatrix = new Matrix4();

    var _vector3 = new Vector3();

    var _emptyScene = { background: null, fog: null, environment: null, overrideMaterial: null, isScene: true };

    function getTargetPixelRatio():Float {
      return _currentRenderTarget == null ? _pixelRatio : 1;
    }

    function getContext(contextName:String, contextAttributes:Dynamic):Dynamic {
      return canvas.getContext(contextName, contextAttributes);
    }

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

      if ("setAttribute" in canvas) canvas.setAttribute("data-engine", "three.js r" + Constants.REVISION);

      canvas.addEventListener("webglcontextlost", onContextLost, false);
      canvas.addEventListener("webglcontextrestored", onContextRestore, false);
      canvas.addEventListener("webglcontextcreationerror", onContextCreationError, false);

      if (_gl == null) {
        var contextName = "webgl2";

        _gl = getContext(contextName, contextAttributes);

        if (_gl == null) {
          if (getContext(contextName)) {
            throw new Error("Error creating WebGL context with your selected attributes.");
          } else {
            throw new Error("Error creating WebGL context.");
          }
        }
      }

    } catch (error:Dynamic) {
      console.error("THREE.WebGLRenderer: " + error.message);
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
      cubemaps = new WebGLCubeMaps(_this);
      cubeuvmaps = new WebGLCubeUVMaps(_this);
      attributes = new WebGLAttributes(_gl);
      bindingStates = new WebGLBindingStates(_gl, attributes);
      geometries = new WebGLGeometries(_gl, attributes, info, bindingStates);
      objects = new WebGLObjects(_gl, geometries, attributes, info);
      morphtargets = new WebGLMorphtargets(_gl, capabilities, textures);
      clipping = new WebGLClipping(properties);
      programCache = new WebGLPrograms(_this, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping);
      materials = new WebGLMaterials(_this, properties);
      renderLists = new WebGLRenderLists();
      renderStates = new WebGLRenderStates(extensions);
      background = new WebGLBackground(_this, cubemaps, cubeuvmaps, state, objects, _alpha, premultipliedAlpha);
      shadowMap = new WebGLShadowMap(_this, objects, capabilities);
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

    initGLContext();

    var xr = new WebXRManager(_this, _gl);
    this.xr = xr;

    this.getContext = function():Dynamic {
      return _gl;
    };

    this.getContextAttributes = function():Dynamic {
      return _gl.getContextAttributes();
    };

    this.forceContextLoss = function() {
      var extension = extensions.get("WEBGL_lose_context");
      if (extension) extension.loseContext();
    };

    this.forceContextRestore = function() {
      var extension = extensions.get("WEBGL_lose_context");
      if (extension) extension.restoreContext();
    };

    this.getPixelRatio = function():Float {
      return _pixelRatio;
    };

    this.setPixelRatio = function(value:Float) {
      if (value == null) return;
      _pixelRatio = value;

      this.setSize(_width, _height, false);
    };

    this.getSize = function(target:Vector2):Vector2 {
      return target.set(_width, _height);
    };

    this.setSize = function(width:Int, height:Int, updateStyle:Bool = true) {
      if (xr.isPresenting) {
        console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting.");
        return;
      }

      _width = width;
      _height = height;

      canvas.width = Math.floor(width * _pixelRatio);
      canvas.height = Math.floor(height * _pixelRatio);

      if (updateStyle == true) {
        canvas.style.width = width + "px";
        canvas.style.height = height + "px";
      }

      this.setViewport(0, 0, width, height);
    };

    this.getDrawingBufferSize = function(target:Vector2):Vector2 {
      return target.set(_width * _pixelRatio, _height * _pixelRatio).floor();
    };

    this.setDrawingBufferSize = function(width:Int, height:Int, pixelRatio:Float) {
      _width = width;
      _height = height;

      _pixelRatio = pixelRatio;

      canvas.width = Math.floor(width * pixelRatio);
      canvas.height = Math.floor(height * pixelRatio);

      this.setViewport(0, 0, width, height);
    };

    this.getCurrentViewport = function(target:Vector4):Vector4 {
      return target.copy(_currentViewport);
    };

    this.getViewport = function(target:Vector4):Vector4 {
      return target.copy(_viewport);
    };

    this.setViewport = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {
      if (x is Vector4) {
        _viewport.set(x.x, x.y, x.z, x.w);
      } else {
        _viewport.set(x, y, width, height);
      }

      state.viewport(_currentViewport.copy(_viewport).multiplyScalar(_pixelRatio).round());
    };

    this.getScissor = function(target:Vector4):Vector4 {
      return target.copy(_scissor);
    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {
      if (x is Vector4) {
        _scissor.set(x.x, x.y, x.z, x.w);
      } else {
        _scissor.set(x, y, width, height);
      }

      state.scissor(_currentScissor.copy(_scissor).multiplyScalar(_pixelRatio).round());
    };

    this.getScissorTest = function():Bool {
      return _scissorTest;
    };

    this.setScissorTest = function(boolean:Bool) {
      state.setScissorTest(_scissorTest = boolean);
    };

    this.setOpaqueSort = function(method:Dynamic) {
      _opaqueSort = method;
    };

    this.setTransparentSort = function(method:Dynamic) {
      _transparentSort = method;
    };

    this.getClearColor = function(target:Color):Color {
      return target.copy(background.getClearColor());
    };

    this.setClearColor = function(color:Color, alpha:Float = 1) {
      background.setClearColor(color, alpha);
    };

    this.getClearAlpha = function():Float {
      return background.getClearAlpha();
    };

    this.setClearAlpha = function(alpha:Float) {
      background.setClearAlpha(alpha);
    };

    this.clear = function(color:Bool = true, depth:Bool = true, stencil:Bool = true) {
      var bits:Int = 0;

      if (color) {
        var isIntegerFormat = false;
        if (_currentRenderTarget != null) {
          var targetFormat = _currentRenderTarget.texture.format;
          isIntegerFormat = targetFormat == Constants.RGBAIntegerFormat ||
            targetFormat == Constants.RGIntegerFormat ||
            targetFormat == Constants.RedIntegerFormat;
        }

        if (isIntegerFormat) {
          var targetType = _currentRenderTarget.texture.type;
          var isUnsignedType = targetType == Constants.UnsignedByteType ||
            targetType == Constants.UnsignedIntType ||
            targetType == Constants.UnsignedShortType ||
            targetType == Constants.UnsignedInt248Type ||
            targetType == Constants.UnsignedShort4444Type ||
            targetType == Constants.UnsignedShort5551Type;

          if (isUnsignedType) {
            uintClearColor[0] = background.getClearColor().r * 255;
            uintClearColor[1] = background.getClearColor().g * 255;
            uintClearColor[2] = background.getClearColor().b * 255;
            uintClearColor[3] = background.getClearColor().a * 255;
            _gl.clearBufferuiv(Constants.COLOR, 0, uintClearColor);
          } else {
            intClearColor[0] = background.getClearColor().r * 255;
            intClearColor[1] = background.getClearColor().g * 255;
            intClearColor[2] = background.getClearColor().b * 255;
            intClearColor[3] = background.getClearColor().a * 255;
            _gl.clearBufferiv(Constants.COLOR, 0, intClearColor);
          }

        } else {
          _gl.clearColor(background.getClearColor().r, background.getClearColor().g, background.getClearColor().b, background.getClearColor().a);
          bits |= Constants.COLOR_BUFFER_BIT;
        }

      }

      if (depth) {
        _gl.clearDepth(1);
        bits |= Constants.DEPTH_BUFFER_BIT;
      }

      if (stencil) {
        _gl.clearStencil(0);
        bits |= Constants.STENCIL_BUFFER_BIT;
      }

      if (bits != 0) _gl.clear(bits);
    };

    this.dispose = function() {
      // dispose all WebGL objects

      capabilities.dispose();
      state.dispose();
      properties.dispose();
      textures.dispose();
      cubemaps.dispose();
      cubeuvmaps.dispose();
      attributes.dispose();
      geometries.dispose();
      objects.dispose();
      programCache.dispose();
      materials.dispose();
      renderStates.dispose();
      background.dispose();
      shadowMap.dispose();
      uniformsGroups.dispose();

      bufferRenderer.dispose();
      indexedBufferRenderer.dispose();

      // remove event listeners

      this.domElement.removeEventListener("webglcontextlost", onContextLost, false);
      this.domElement.removeEventListener("webglcontextrestored", onContextRestore, false);
      this.domElement.removeEventListener("webglcontextcreationerror", onContextCreationError, false);

      // reset

      _gl = null;

    };

    this.render = function(scene:Dynamic, camera:Dynamic, renderTarget:WebGLRenderTarget = null, forceClear:Bool = true) {
      //  console.time( 'WebGLRenderer.render' );

      // reset caching for the new frame

      _currentMaterialId = - 1;

      // reset state

      state.reset();

      // update scene graph

      if (scene.autoUpdate == true) scene.updateMatrixWorld(true);

      // update camera matrices and frustum

      if (camera.parent != null) camera.updateMatrixWorld(true);

      camera.matrixWorldInverse.getInverse(camera.matrixWorld);

      _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);

      _frustum.setFromMatrix(camera.projectionMatrix.multiplyMatrices(camera.matrixWorldInverse, camera.matrixWorld));

      // render target

      _currentRenderTarget = renderTarget;

      if (renderTarget != null) {

        _this.setRenderTarget(renderTarget);

      } else {

        _this.setRenderTarget(null);

      }

      // clipping

      if (scene.isScene == true) {

        _localClippingEnabled = scene.localClippingEnabled;

      } else {

        _localClippingEnabled = false;

      }

      _clippingEnabled = _localClippingEnabled || camera.clippingPlanes.length != 0;

      clipping.init(camera, scene.clippingPlanes, _localClippingEnabled);

      // lights

      _this._useLegacyLights = false;

      // update shadow map (deferred)

      shadowMap.render(scene, camera);

      // render scene

      _this._render(scene, camera, forceClear);

      //  console.timeEnd( 'WebGLRenderer.render' );

    };

    this._render = function(scene:Dynamic, camera:Dynamic, forceClear:Bool = true) {

      // pre-render

      if ( _isContextLost == true ) return;

      _this.info.render.calls = 0;
      _this.info.render.vertices = 0;
      _this.info.render.faces = 0;
      _this.info.render.points = 0;
      _this.info.render.triangles = 0;

      // update world matrix

      if (scene.isScene == true) {

        if (scene.background != null) {

          background.set(scene.background);

        } else if (scene.environment != null) {

          background.set(scene.environment);

        } else {

          background.set(null);

        }

        if (scene.fog != null) {

          state.setFog(scene.fog);

        } else {

          state.setFog(null);

        }

      } else {

        background.set(null);
        state.setFog(null);

      }

      _currentCamera = camera;
      _currentScissorTest = null;

      // update material properties

      materials.update();

      // update attributes

      attributes.init();

      // init render list

      renderLists.init();

      // opaque pass (front-to-back)

      if (scene.isScene == true) {

        renderLists.push.apply(renderLists, scene.children);

      } else {

        renderLists.push(scene);

      }

      // opaque pass

      if ( _sortObjects == true ) {

        if ( _opaqueSort != null ) {

          renderLists.sort( _opaqueSort );

        } else {

          renderLists.sort( WebGLRenderer.opaqueSort );

        }

      }

      _this.info.render.calls = 0;
      _this.info.render.vertices = 0;
      _this.info.render.faces = 0;
      _this.info.render.points = 0;
      _this.info.render.triangles = 0;

      _this._renderObjects(renderLists, scene, camera, _this.info.render, forceClear);

      renderLists.clear();

      //  console.time( 'WebGLRenderer.render.transparent' );

      // transparent pass (back-to-front)

      if ( _sortObjects == true ) {

        if ( _transparentSort != null ) {

          renderLists.sort( _transparentSort );

        } else {

          renderLists.sort( WebGLRenderer.transparentSort );

        }

      }

      _this.info.render.calls = 0;
      _this.info.render.vertices = 0;
      _this.info.render.faces = 0;
      _this.info.render.points = 0;
      _this.info.render.triangles = 0;

      _this._renderObjects(renderLists, scene, camera, _this.info.render, forceClear);

      renderLists.clear();

      //  console.timeEnd( 'WebGLRenderer.render.transparent' );

      // post-render

      if ( _currentRenderTarget != null ) {

        // Generate mipmaps if needed
        if ( _currentRenderTarget.texture.generateMipmaps == true ) {

          textures.generateMipmaps(_currentRenderTarget.texture);

        }

        // Ensure valid target is used
        _this.setRenderTarget( _currentRenderTarget );

      } else {

        _this.setRenderTarget( null );

      }

      // reset

      state.reset();

      // reset material properties

      materials.reset();

      // reset attributes

      attributes.reset();

      // reset objects

      objects.reset();

      // reset program cache

      programCache.reset();

      // reset shadow map

      shadowMap.reset();

      _currentCamera = null;

      //  console.timeEnd( 'WebGLRenderer.render' );

    };

    this._renderObjects = function(renderList:Array<Dynamic>, scene:Dynamic, camera:Dynamic, info:Dynamic, forceClear:Bool = true) {

      var _isScene = scene.isScene;

      var overrideMaterial = _isScene ? scene.overrideMaterial : null;
      var environment = _isScene ? scene.environment : null;

      var geometryGroup = null;

      var object:Dynamic;

      for (object in renderList) {

        var material:Dynamic = object.material;

        if (material == null) continue;

        //  console.time( 'WebGLRenderer.renderObjects.update' );

        if (object.visible == false) continue;

        if (object.layers.test(camera.layers) == false) continue;

        if (object.isGroup == true) {

          if (object.children.length == 0) continue;

        }

        if (object.isMesh == true || object.isLine == true || object.isPoints == true) {

          if (object.geometry.isGeometry == true) {

            if (geometryGroup == null) geometryGroup = {
              objects: [],
              material: material
            };

            geometryGroup.objects.push(object);

          } else {

            _this.renderBufferDirect( object, overrideMaterial, environment, info );

          }

        } else if (object.isSprite == true) {

          _this.renderBufferDirect( object, overrideMaterial, environment, info );

        } else if (object.isLineLoop == true || object.isLineSegments == true) {

          if (object.geometry.isGeometry == true) {

            if (geometryGroup == null) geometryGroup = {
              objects: [],
              material: material
            };

            geometryGroup.objects.push(object);

          } else {

            _this.renderBufferDirect( object, overrideMaterial, environment, info );

          }

        } else if (object.isLOD == true) {

          if (object.visible == true) {

            // render all levels of LODs, not just the closest one

            for (var child in object.children) {

              _this._renderObjects([child], scene, camera, info, forceClear);

            }

          }

        } else if (object.isInstancedMesh == true) {

          _this.renderBufferDirect( object, overrideMaterial, environment, info );

        } else if (object.isInstancedLine == true || object.isInstancedLineSegments == true) {

          _this.renderBufferDirect( object, overrideMaterial, environment, info );

        } else if (object.isInstancedPoints == true) {

          _this.renderBufferDirect( object, overrideMaterial, environment, info );

        }

        //  console.timeEnd( 'WebGLRenderer.renderObjects.update' );

      }

      // render geometry groups

      if (geometryGroup != null) {

        _this.renderBufferDirect( geometryGroup, overrideMaterial, environment, info );

      }

    };

    this.renderBufferDirect = function(object:Dynamic, overrideMaterial:Dynamic, environment:Dynamic, info:Dynamic) {

      var material = overrideMaterial != null ? overrideMaterial : object.material;

      if (material.visible == false) return;

      if (material.side == Constants.BackSide) {

        state.setFlipSided(true);

      }

      //  console.time( 'WebGLRenderer.renderBufferDirect.setup' );

      var program = programCache.getProgram( object, material );

      //  console.timeEnd( 'WebGLRenderer.renderBufferDirect.setup' );

      //  console.time( 'WebGLRenderer.renderBufferDirect.render' );

      if (object.isInstancedMesh == true || object.isInstancedLine == true || object.isInstancedLineSegments == true || object.isInstancedPoints == true) {

        if (object.isInstancedMesh == true) {

          if (object.geometry.isBufferGeometry == true) {

            indexedBufferRenderer.render( object, program, material, _projScreenMatrix, _frustum, object.geometry, info );

          }

        } else if (object.isInstancedLine == true || object.isInstancedLineSegments == true) {

          if (object.geometry.isBufferGeometry == true) {

            indexedBufferRenderer.render( object, program, material, _projScreenMatrix, _frustum, object.geometry, info );

          }

        } else if (object.isInstancedPoints == true) {

          if (object.geometry.isBufferGeometry == true) {

            bufferRenderer.render( object, program, material, _projScreenMatrix, _frustum, object.geometry, info );

          }

        }

      } else if ( object.geometry.isBufferGeometry == true) {

        if ( object.geometry.index != null ) {

          indexedBufferRenderer.render( object, program, material, _projScreenMatrix, _frustum, object.geometry, info );

        } else {

          bufferRenderer.render( object, program, material, _projScreenMatrix, _frustum, object.geometry, info );

        }

      } else {

        //  console.time( 'WebGLRenderer.renderBufferDirect.render.legacy' );

        _this.renderBuffer( object, program, material, _projScreenMatrix, _frustum, info );

        //  console.timeEnd( 'WebGLRenderer.renderBufferDirect.render.legacy' );

      }

      //  console.timeEnd( 'WebGLRenderer.renderBufferDirect.render' );

      if (material.side == Constants.BackSide) {

        state.setFlipSided(false);

      }

    };

    this.renderBuffer = function(object:Dynamic, program:Dynamic, material:Dynamic, projScreenMatrix:Matrix4, frustum:Frustum, info:Dynamic) {

      //  console.time( 'WebGLRenderer.renderBuffer.setup' );

      // setup program

      if ( program.id != _currentMaterialId ) {

        programCache.setProgram( program, _this._useLegacyLights, object.isLine == true, object.isPoints == true, object.isSprite == true, material.isShaderMaterial == true );

        // setup uniforms

        uniformsGroups.init( program, material, object );

        // setup attributes

        programCache.updateAttributes( program, object );

        // setup textures

        textures.update( program, material, object );

        // setup morph targets

        morphtargets.update( program, object );

        // set material id

        _currentMaterialId = program.id;

      } else {

        //  console.time( 'WebGLRenderer.renderBuffer.update' );

        // refresh uniforms

        uniformsGroups.update( program, material, object );

        // refresh textures

        textures.update( program, material, object );

        //  console.timeEnd( 'WebGLRenderer.renderBuffer.update' );

      }

      //  console.timeEnd( 'WebGLRenderer.renderBuffer.setup' );

      //  console.time( 'WebGLRenderer.renderBuffer.render' );

      if ( object.isMesh == true ) {

        if ( object.geometry.isGeometry == true ) {

          //  console.time( 'WebGLRenderer.renderBuffer.render.faces' );

          var n = object.geometry.faces.length;
          info.render.faces += n;
          info.render.vertices += object.geometry.vertices.length;

          _gl.drawElements( Constants.TRIANGLES, n * 3, Constants.UNSIGNED_SHORT, 0 );

          //  console.timeEnd( 'WebGLRenderer.renderBuffer.render.faces' );

        } else {

          info.render.triangles += object.geometry.index.count / 3;
          info.render.vertices += object.geometry.attributes.position.count;

          _gl.drawElements( Constants.TRIANGLES, object.geometry.index.count, Constants.UNSIGNED_SHORT, 0 );

        }

      } else if ( object.isLine == true ) {

        if ( object.geometry.isGeometry == true ) {

          _gl.drawArrays( Constants.LINES, 0, object.geometry.vertices.length );

          info.render.vertices += object.geometry.vertices.length;

        } else {

          info.render.vertices += object.geometry.attributes.position.count;

          _gl.drawArrays( Constants.LINES, 0, object.geometry.attributes.position.count );

        }

      } else if ( object.isPoints == true ) {

        if ( object.geometry.isGeometry == true ) {

          _gl.drawArrays( Constants.POINTS, 0, object.geometry.vertices.length );

          info.render.vertices += object.geometry.vertices.length;
          info.render.points += object.geometry.vertices.length;

        } else {

          info.render.vertices += object.geometry.attributes
        if ( object.geometry.isGeometry == true ) {

          _gl.drawArrays( Constants.POINTS, 0, object.geometry.vertices.length );

          info.render.vertices += object.geometry.vertices.length;
          info.render.points += object.geometry.vertices.length;

        } else {

          info.render.vertices += object.geometry.attributes.position.count;

          _gl.drawArrays( Constants.POINTS, 0, object.geometry.attributes.position.count );

        }

      } else if ( object.isSprite == true ) {

        //  console.time( 'WebGLRenderer.renderBuffer.render.sprite' );

        info.render.vertices += 4;

        _gl.drawArrays( Constants.TRIANGLES, 0, 6 );

        //  console.timeEnd( 'WebGLRenderer.renderBuffer.render.sprite' );

      }

      //  console.timeEnd( 'WebGLRenderer.renderBuffer.render' );

    };

    this.setRenderTarget = function(renderTarget:WebGLRenderTarget = null) {

      var currentRenderTarget = _currentRenderTarget;

      if ( renderTarget != null && renderTarget.isWebGLRenderTarget == true ) {

        //  console.time( 'WebGLRenderer.setRenderTarget.setup' );

        state.bindFramebuffer( renderTarget.framebuffer );

        if ( renderTarget.scissorTest == true ) {

          state.setScissorTest( true );
          state.scissor( renderTarget.scissor.multiplyScalar( getTargetPixelRatio() ).round() );

        } else {

          state.setScissorTest( false );

        }

        state.viewport( renderTarget.viewport.multiplyScalar( getTargetPixelRatio() ).round() );

        //  console.timeEnd( 'WebGLRenderer.setRenderTarget.setup' );

      } else {

        //  console.time( 'WebGLRenderer.setRenderTarget.default' );

        state.bindFramebuffer( null );

        state.setScissorTest( _scissorTest );
        state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

        //  console.timeEnd( 'WebGLRenderer.setRenderTarget.default' );

      }

      _currentRenderTarget = renderTarget;

      if ( currentRenderTarget != null ) {

        state.reset();

      }

    };

    this.readRenderTargetPixels = function(renderTarget:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int, buffer:Array<Float32> = null) {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          const gl = _gl;

          let data;

          if ( buffer === null ) {

            data = new Float32Array( width * height * 4 );

          } else {

            data = buffer;

          }

          if ( typeof gl.readPixels !== 'undefined' ) {

            gl.readPixels( x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, data );

          } else {

            console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is not supported. Please check your browser.' );

          }

          state.bindFramebuffer( null );

          return data;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() can only be used with render targets.' );

    };

    this.copyFramebufferToTexture = function(renderTarget:WebGLRenderTarget, source:WebGLRenderTarget) {

      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( renderTarget.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          if ( source.isWebGLRenderTarget == true ) {

            state.bindFramebuffer( source.framebuffer );
            textures.copyTextureToTexture( source.texture, renderTarget.texture );

          }

          state.bindFramebuffer( null );

          return;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    //

    this.updateShadowMap = function(scene:Dynamic, camera:Dynamic) {

      shadowMap.render( scene, camera );

    };

    this.getShadowMap = function(target:Array<Dynamic> = null) {

      return shadowMap.get( target );

    };

    //

    this.outputColorSpace = function(colorSpace:Int) {

      if ( colorSpace === SRGBColorSpace || colorSpace === LinearSRGBColorSpace ||
        colorSpace === DisplayP3ColorSpace || colorSpace === LinearDisplayP3ColorSpace ) {

        this._outputColorSpace = colorSpace;

      } else {

        console.warn( 'THREE.WebGLRenderer: .outputColorSpace() can only be set to SRGBColorSpace, LinearSRGBColorSpace, DisplayP3ColorSpace, or LinearDisplayP3ColorSpace.' );

      }

    };

    this.getOutputColorSpace = function() {

      return this._outputColorSpace;

    };

    //

    function onContextLost(event:Dynamic) {

      event.preventDefault();
      console.warn( 'THREE.WebGLRenderer: WebGL context lost.' );
      _isContextLost = true;

    }

    function onContextRestore(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context restored.' );
      _isContextLost = false;

      initGLContext();

      // recreate webxr session

      xr.setSession( null, true );

      // recreate all render targets
      // ( re-allocate framebuffers, textures, etc. )

      _this.setRenderTarget( _currentRenderTarget );

      // attempt to re-bind the objects (for re-created webgl context)

      for (var i in renderLists.objects) {

        const object = renderLists.objects[i];

        if ( object.isMesh == true ) {

          object.geometry.groupsNeedUpdate = true;

        }

        object.needsUpdate = true;

      }

      // re-render

      _this.render( _emptyScene, _currentCamera, _currentRenderTarget, true );

    }

    function onContextCreationError( event:Dynamic ) {

      console.error( 'THREE.WebGLRenderer: WebGL context creation error.' );
      _isContextLost = true;

    }

    //

    function getDepthBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.depthBuffer;

      }

      return _gl.depthBuffer;

    }

    function getStencilBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.stencilBuffer;

      }

      return _gl.stencilBuffer;

    }

    //

    this.getDepthTexture = function(renderTarget:WebGLRenderTarget):Dynamic {

      var depthTexture = null;

      if ( renderTarget.isWebGLRenderTarget == true ) {

        depthTexture = renderTarget.depthTexture;

      } else {

        if ( _this.extensions.get( 'WEBGL_depth_texture' ) ) {

          depthTexture = properties.get( renderTarget, 'depthTexture' );

          if ( depthTexture == null ) {

            depthTexture = new WebGLRenderTarget( _width, _height, {

              depthBuffer: true,
              stencilBuffer: false,
              format: Constants.DepthFormat,
              type: Constants.UnsignedShortType

            } );

            properties.set( renderTarget, 'depthTexture', depthTexture );

          }

        }

      }

      return depthTexture;

    };

    this.isWebGL1 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 1' ) >= 0;

    };

    this.isWebGL2 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 2' ) >= 0;

    };

    //

    this.getLinearToneMapping = function() {

      return this.toneMapping === Constants.LinearToneMapping;

    };

    this.setLinearToneMapping = function() {

      this.toneMapping = Constants.LinearToneMapping;

    };

    this.getReinhardToneMapping = function() {

      return this.toneMapping === Constants.ReinhardToneMapping;

    };

    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2ToneMapping;

    };

    this.setUncharted2ToneMapping = function() {

      this.toneMapping = Constants.Uncharted2ToneMapping;

    };

    this.getCineonToneMapping = function() {

      return this.toneMapping === Constants.CineonToneMapping;

    };

    this.setCineonToneMapping = function() {

      this.toneMapping = Constants.CineonToneMapping;

    };

    this.getACESFilmicToneMapping = function() {

      return this.toneMapping === Constants.ACESFilmicToneMapping;

    };

    this.setACESFilmicToneMapping = function() {

      this.toneMapping = Constants.ACESFilmicToneMapping;

    };

    this.getCustomToneMapping = function() {

      return this.toneMapping === Constants.CustomToneMapping;

    };

    this.setCustomToneMapping = function() {

      this.toneMapping = Constants.CustomToneMapping;

    };

    this.getNoToneMapping = function() {

      return this.toneMapping === Constants.NoToneMapping;

    };

    this.setNoToneMapping = function() {

      this.toneMapping = Constants.NoToneMapping;

    };

    //

    this.getPhysicalLights = function() {

      return this._useLegacyLights === false;

    };

    this.setPhysicalLights = function() {

      this._useLegacyLights = false;

    };

    this.getLegacyLights = function() {

      return this._useLegacyLights === true;

    };

    this.setLegacyLights = function() {

      this._useLegacyLights = true;

    };

    //

    this.getActiveCubeFace = function() {

      return _currentActiveCubeFace;

    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but are deprecated)

    this.gammaFactor = function(factor:Float = 2.0) {

      console.warn( 'THREE.WebGLRenderer: .gammaFactor() is now obsolete. Use .outputColorSpace( THREE.SRGBColorSpace ) for sRGB or THREE.LinearSRGBColorSpace for linear color space.' );

      this.outputColorSpace( factor === 2.0 ? Constants.SRGBColorSpace : Constants.LinearSRGBColorSpace );

    };

    //

    this.getGammaFactor = function() {

      return this.getOutputColorSpace() === Constants.SRGBColorSpace ? 2.0 : 1.0;

    };

    //

    this.getMaxAnisotropy = function() {

      return capabilities.getMaxAnisotropy();

    };

    //

    this.getPrecision = function() {

      return capabilities.precision;

    };

    //

    this.getRenderList = function() {

      return renderLists;

    };

    //

    this.addPostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostProcess() is no longer supported.' );

    };

    this.removePostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostProcess() is no longer supported.' );

    };

    this.getClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearColor() is deprecated. Use .getClearColor() instead.' );
      return background.getClearColor();

    };

    this.setClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor.apply( background, arguments );

    };

    this.getClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearAlpha() is deprecated. Use .getClearAlpha() instead.' );
      return background.getClearAlpha();

    };

    this.setClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha.apply( background, arguments );

    };

    //

    this.getMaxTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextures() is deprecated. Use .capabilities.maxTextures instead.' );
      return capabilities.maxTextures;

    };

    this.getMaxVertexUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexUniforms() is deprecated. Use .capabilities.maxVertexUniforms instead.' );
      return capabilities.maxVertexUniforms;

    };

    this.getMaxFragmentUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxFragmentUniforms() is deprecated. Use .capabilities.maxFragmentUniforms instead.' );
      return capabilities.maxFragmentUniforms;

    };

    this.getMaxVaryings = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVaryings() is deprecated. Use .capabilities.maxVaryings instead.' );
      return capabilities.maxVaryings;

    };

    this.getMaxVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexTextures() is deprecated. Use .capabilities.maxVertexTextures instead.' );
      return capabilities.maxVertexTextures;

    };

    this.getMaxTextureSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextureSize() is deprecated. Use .capabilities.maxTextureSize instead.' );
      return capabilities.maxTextureSize;

    };

    this.getMaxCubemapSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxCubemapSize() is deprecated. Use .capabilities.maxCubemapSize instead.' );
      return capabilities.maxCubemapSize;

    };

    this.getMaxAnisotropy = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxAnisotropy() is deprecated. Use .capabilities.getMaxAnisotropy() instead.' );
      return capabilities.getMaxAnisotropy();

    };

    this.getPrecision = function() {

      console.warn( 'THREE.WebGLRenderer: .getPrecision() is deprecated. Use .capabilities.precision instead.' );
      return capabilities.precision;

    };

    this.getSupportsStandardDerivatives = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsStandardDerivatives() is deprecated. Use .capabilities.standardDerivatives instead.' );
      return capabilities.standardDerivatives;

    };

    this.getSupportsInstancedArrays = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsInstancedArrays() is deprecated. Use .capabilities.instancedArrays instead.' );
      return capabilities.instancedArrays;

    };

    this.getSupportsVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsVertexTextures() is deprecated. Use .capabilities.vertexTextures instead.' );
      return capabilities.vertexTextures;

    };

    this.getSupportsFloatTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatTextures() is deprecated. Use .capabilities.floatTextures instead.' );
      return capabilities.floatTextures;

    };

    this.getSupportsFloatFramebuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatFramebuffers() is deprecated. Use .capabilities.floatFramebuffers instead.' );
      return capabilities.floatFramebuffers;

    };

    this.getSupportsSRGB = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsSRGB() is deprecated. Use .capabilities.sRGB instead.' );
      return capabilities.sRGB;

    };

    this.getSupportsWebGL2 = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsWebGL2() is deprecated. Use .capabilities.isWebGL2 instead.' );
      return capabilities.isWebGL2;

    };

    this.getSupportsDrawBuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsDrawBuffers() is deprecated. Use .capabilities.drawBuffers instead.' );
      return capabilities.drawBuffers;

    };

    this.getSupportsLinearFiltering = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsLinearFiltering() is deprecated. Use .capabilities.linearFiltering instead.' );
      return capabilities.linearFiltering;

    };

    this.getSupportsTextureFloatLinear = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsTextureFloatLinear() is deprecated. Use .capabilities.textureFloatLinear instead.' );
      return capabilities.textureFloatLinear;

    };

    //

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use .setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.compile = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .compile() is deprecated. Use .render() instead.' );
      this.render( scene, camera );

    };

    // Backward compatibility:

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use xr.setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.initTexture = function(texture:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .initTexture() is deprecated. Use .initTexture() instead.' );
      textures.initTexture( texture );

    };

    //

    this.addPreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPreRenderCallback() is deprecated. Use .addPreRenderCallback() instead.' );
      renderStates.addPreRenderCallback( callback );

    };

    this.removePreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePreRenderCallback() is deprecated. Use .removePreRenderCallback() instead.' );
      renderStates.removePreRenderCallback( callback );

    };

    this.addPostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostRenderCallback() is deprecated. Use .addPostRenderCallback() instead.' );
      renderStates.addPostRenderCallback( callback );

    };

    this.removePostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostRenderCallback() is deprecated. Use .removePostRenderCallback() instead.' );
      renderStates.removePostRenderCallback( callback );

    };

    //

    this.setClearColorHex = function(hex:Int, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColorHex() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( hex, alpha );

    };

    this.setClearColor = function(color:Color, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( color, alpha );

    };

    this.setClearAlpha = function(alpha:Float) {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha( alpha );

    };

    this.setDrawingBufferSize = function(width:Int, height:Int, pixelRatio:Float) {

      console.warn( 'THREE.WebGLRenderer: .setDrawingBufferSize() is deprecated. Use .setDrawingBufferSize() instead.' );
      _width = width;
      _height = height;

      _pixelRatio = pixelRatio;

      canvas.width = Math.floor( width * pixelRatio );
      canvas.height = Math.floor( height * pixelRatio );

      this.setViewport( 0, 0, width, height );

    };

    this.setScissorTest = function(boolean:Bool) {

      console.warn( 'THREE.WebGLRenderer: .setScissorTest() is deprecated. Use .setScissorTest() instead.' );
      state.setScissorTest( _scissorTest = boolean );

    };

    this.getScissor = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getScissor() is deprecated. Use .getScissor() instead.' );
      return target.copy( _scissor );

    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setScissor() is deprecated. Use .setScissor() instead.' );
      if ( x.isVector4 ) {

        _scissor.set( x.x, x.y, x.z, x.w );

      } else {

        _scissor.set( x, y, width, height );

      }

      state.scissor( _currentScissor.copy( _scissor ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getViewport = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getViewport() is deprecated. Use .getViewport() instead.' );
      return target.copy( _viewport );

    };

    this.setViewport = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setViewport() is deprecated. Use .setViewport() instead.' );
      if ( x.isVector4 ) {

        _viewport.set( x.x, x.y, x.z, x.w );

      } else {

        _viewport.set( x, y, width, height );

      }

      state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getRenderTarget = function() {

      console.warn( 'THREE.WebGLRenderer: .getRenderTarget() is deprecated. Use .getRenderTarget() instead.' );
      return _currentRenderTarget;

    };

    this.setRenderTarget = function(renderTarget:WebGLRenderTarget = null) {

      console.warn( 'THREE.WebGLRenderer: .setRenderTarget() is deprecated. Use .setRenderTarget() instead.' );
      _currentRenderTarget = renderTarget;

      if ( renderTarget != null && renderTarget.isWebGLRenderTarget == true ) {

        state.bindFramebuffer( renderTarget.framebuffer );

        if ( renderTarget.scissorTest == true ) {

          state.setScissorTest( true );
          state.scissor( renderTarget.scissor.multiplyScalar( getTargetPixelRatio() ).round() );

        } else {

          state.setScissorTest( false );

        }

        state.viewport( renderTarget.viewport.multiplyScalar( getTargetPixelRatio() ).round() );

      } else {

        state.bindFramebuffer( null );

        state.setScissorTest( _scissorTest );
        state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

      }

    };

    this.readRenderTargetPixels = function(renderTarget:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int, buffer:Array<Float32> = null) {

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is deprecated. Use .readRenderTargetPixels() instead.' );
      if ( renderTarget.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          const gl = _gl;

          let data;

          if ( buffer === null ) {

            data = new Float32Array( width * height * 4 );

          } else {

            data = buffer;

          }

          if ( typeof gl.readPixels !== 'undefined' ) {

            gl.readPixels( x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, data );

          } else {

            console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is not supported. Please check your browser.' );

          }

          state.bindFramebuffer( null );

          return data;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() can only be used with render targets.' );

    };

    //

    this.copyFramebufferToTexture = function(renderTarget:WebGLRenderTarget, source:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() is deprecated. Use .copyFramebufferToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( renderTarget.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          if ( source.isWebGLRenderTarget == true ) {

            state.bindFramebuffer( source.framebuffer );
            textures.copyTextureToTexture( source.texture, renderTarget.texture );

          }

          state.bindFramebuffer( null );

          return;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    //

    this.updateShadowMap = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .updateShadowMap() is deprecated. Use .shadowMap.render() instead.' );
      shadowMap.render( scene, camera );

    };

    this.getShadowMap = function(target:Array<Dynamic> = null) {

      console.warn( 'THREE.WebGLRenderer: .getShadowMap() is deprecated. Use .shadowMap.get() instead.' );
      return shadowMap.get( target );

    };

    //

    this.outputColorSpace = function(colorSpace:Int) {

      console.warn( 'THREE.WebGLRenderer: .outputColorSpace() is deprecated. Use .outputColorSpace() instead.' );
      if ( colorSpace === SRGBColorSpace || colorSpace === LinearSRGBColorSpace ||
        colorSpace === DisplayP3ColorSpace || colorSpace === LinearDisplayP3ColorSpace ) {

        this._outputColorSpace = colorSpace;

      } else {

        console.warn( 'THREE.WebGLRenderer: .outputColorSpace() can only be set to SRGBColorSpace, LinearSRGBColorSpace, DisplayP3ColorSpace, or LinearDisplayP3ColorSpace.' );

      }

    };

    this.getOutputColorSpace = function() {

      console.warn( 'THREE.WebGLRenderer: .getOutputColorSpace() is deprecated. Use .getOutputColorSpace() instead.' );
      return this._outputColorSpace;

    };

    //

    function onContextLost(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context lost.' );
      _isContextLost = true;

    }

    function onContextRestore(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context restored.' );
      _isContextLost = false;

      initGLContext();

      // recreate webxr session

      xr.setSession( null, true );

      // recreate all render targets
      // ( re-allocate framebuffers, textures, etc. )

      _this.setRenderTarget( _currentRenderTarget );

      // attempt to re-bind the objects (for re-created webgl context)

      for (var i in renderLists.objects) {

        const object = renderLists.objects[i];

        if ( object.isMesh == true ) {

          object.geometry.groupsNeedUpdate = true;

        }

        object.needsUpdate = true;

      }

      // re-render

      _this.render( _emptyScene, _currentCamera, _currentRenderTarget, true );

    }

    function onContextCreationError( event:Dynamic ) {

      console.error( 'THREE.WebGLRenderer: WebGL context creation error.' );
      _isContextLost = true;

    }

    //

    function getDepthBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.depthBuffer;

      }

      return _gl.depthBuffer;

    }

    function getStencilBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.stencilBuffer;

      }

      return _gl.stencilBuffer;

    }

    //

    this.getDepthTexture = function(renderTarget:WebGLRenderTarget):Dynamic {

      var depthTexture = null;

      if ( renderTarget.isWebGLRenderTarget == true ) {

        depthTexture = renderTarget.depthTexture;

      } else {

        if ( _this.extensions.get( 'WEBGL_depth_texture' ) ) {

          depthTexture = properties.get( renderTarget, 'depthTexture' );

          if ( depthTexture == null ) {

            depthTexture = new WebGLRenderTarget( _width, _height, {

              depthBuffer: true,
              stencilBuffer: false,
              format: Constants.DepthFormat,
              type: Constants.UnsignedShortType

            } );

            properties.set( renderTarget, 'depthTexture', depthTexture );

          }

        }

      }

      return depthTexture;

    };

    this.isWebGL1 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 1' ) >= 0;

    };

    this.isWebGL2 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 2' ) >= 0;

    };

    //

    this.getLinearToneMapping = function() {

      return this.toneMapping === Constants.LinearToneMapping;

    };

    this.setLinearToneMapping = function() {

      this.toneMapping = Constants.LinearToneMapping;

    };

    this.getReinhardToneMapping = function() {

      return this.toneMapping === Constants.ReinhardToneMapping;

    };

    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2ToneMapping;

    };

    this.setUncharted2ToneMapping = function() {

      this.toneMapping = Constants.Uncharted2ToneMapping;

    };

    this.getCineonToneMapping = function() {

      return this.toneMapping === Constants.CineonToneMapping;

    };

    this.setCineonToneMapping = function() {

      this.toneMapping = Constants.CineonToneMapping;

    };

    this.getACESFilmicToneMapping = function() {

      return this.toneMapping === Constants.ACESFilmicToneMapping;

    };

    this.setACESFilmicToneMapping = function() {

      this.toneMapping = Constants.ACESFilmicToneMapping;

    };

    this.getCustomToneMapping = function() {

      return this.toneMapping === Constants.CustomToneMapping;

    };

    this.setCustomToneMapping = function() {

      this.toneMapping = Constants.CustomToneMapping;

    };

    this.getNoToneMapping = function() {

      return this.toneMapping === Constants.NoToneMapping;

    };

    this.setNoToneMapping = function() {

      this.toneMapping = Constants.NoToneMapping;

    };

    //

    this.getPhysicalLights = function() {

      return this._useLegacyLights === false;

    };

    this.setPhysicalLights = function() {

      this._useLegacyLights = false;

    };

    this.getLegacyLights = function() {

      return this._useLegacyLights === true;

    };

    this.setLegacyLights = function() {

      this._useLegacyLights = true;

    };

    //

    this.getActiveCubeFace = function() {

      return _currentActiveCubeFace;

    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but
    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but are deprecated)

    this.gammaFactor = function(factor:Float = 2.0) {

      console.warn( 'THREE.WebGLRenderer: .gammaFactor() is now obsolete. Use .outputColorSpace( THREE.SRGBColorSpace ) for sRGB or THREE.LinearSRGBColorSpace for linear color space.' );

      this.outputColorSpace( factor === 2.0 ? Constants.SRGBColorSpace : Constants.LinearSRGBColorSpace );

    };

    //

    this.getGammaFactor = function() {

      return this.getOutputColorSpace() === Constants.SRGBColorSpace ? 2.0 : 1.0;

    };

    //

    this.getMaxAnisotropy = function() {

      return capabilities.getMaxAnisotropy();

    };

    //

    this.getPrecision = function() {

      return capabilities.precision;

    };

    //

    this.getRenderList = function() {

      return renderLists;

    };

    //

    this.addPostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostProcess() is no longer supported.' );

    };

    this.removePostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostProcess() is no longer supported.' );

    };

    this.getClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearColor() is deprecated. Use .getClearColor() instead.' );
      return background.getClearColor();

    };

    this.setClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor.apply( background, arguments );

    };

    this.getClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearAlpha() is deprecated. Use .getClearAlpha() instead.' );
      return background.getClearAlpha();

    };

    this.setClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha.apply( background, arguments );

    };

    //

    this.getMaxTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextures() is deprecated. Use .capabilities.maxTextures instead.' );
      return capabilities.maxTextures;

    };

    this.getMaxVertexUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexUniforms() is deprecated. Use .capabilities.maxVertexUniforms instead.' );
      return capabilities.maxVertexUniforms;

    };

    this.getMaxFragmentUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxFragmentUniforms() is deprecated. Use .capabilities.maxFragmentUniforms instead.' );
      return capabilities.maxFragmentUniforms;

    };

    this.getMaxVaryings = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVaryings() is deprecated. Use .capabilities.maxVaryings instead.' );
      return capabilities.maxVaryings;

    };

    this.getMaxVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexTextures() is deprecated. Use .capabilities.maxVertexTextures instead.' );
      return capabilities.maxVertexTextures;

    };

    this.getMaxTextureSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextureSize() is deprecated. Use .capabilities.maxTextureSize instead.' );
      return capabilities.maxTextureSize;

    };

    this.getMaxCubemapSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxCubemapSize() is deprecated. Use .capabilities.maxCubemapSize instead.' );
      return capabilities.maxCubemapSize;

    };

    this.getMaxAnisotropy = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxAnisotropy() is deprecated. Use .capabilities.getMaxAnisotropy() instead.' );
      return capabilities.getMaxAnisotropy();

    };

    this.getPrecision = function() {

      console.warn( 'THREE.WebGLRenderer: .getPrecision() is deprecated. Use .capabilities.precision instead.' );
      return capabilities.precision;

    };

    this.getSupportsStandardDerivatives = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsStandardDerivatives() is deprecated. Use .capabilities.standardDerivatives instead.' );
      return capabilities.standardDerivatives;

    };

    this.getSupportsInstancedArrays = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsInstancedArrays() is deprecated. Use .capabilities.instancedArrays instead.' );
      return capabilities.instancedArrays;

    };

    this.getSupportsVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsVertexTextures() is deprecated. Use .capabilities.vertexTextures instead.' );
      return capabilities.vertexTextures;

    };

    this.getSupportsFloatTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatTextures() is deprecated. Use .capabilities.floatTextures instead.' );
      return capabilities.floatTextures;

    };

    this.getSupportsFloatFramebuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatFramebuffers() is deprecated. Use .capabilities.floatFramebuffers instead.' );
      return capabilities.floatFramebuffers;

    };

    this.getSupportsSRGB = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsSRGB() is deprecated. Use .capabilities.sRGB instead.' );
      return capabilities.sRGB;

    };

    this.getSupportsWebGL2 = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsWebGL2() is deprecated. Use .capabilities.isWebGL2 instead.' );
      return capabilities.isWebGL2;

    };

    this.getSupportsDrawBuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsDrawBuffers() is deprecated. Use .capabilities.drawBuffers instead.' );
      return capabilities.drawBuffers;

    };

    this.getSupportsLinearFiltering = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsLinearFiltering() is deprecated. Use .capabilities.linearFiltering instead.' );
      return capabilities.linearFiltering;

    };

    this.getSupportsTextureFloatLinear = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsTextureFloatLinear() is deprecated. Use .capabilities.textureFloatLinear instead.' );
      return capabilities.textureFloatLinear;

    };

    //

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use .setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.compile = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .compile() is deprecated. Use .render() instead.' );
      this.render( scene, camera );

    };

    // Backward compatibility:

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use xr.setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.initTexture = function(texture:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .initTexture() is deprecated. Use .initTexture() instead.' );
      textures.initTexture( texture );

    };

    //

    this.addPreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPreRenderCallback() is deprecated. Use .addPreRenderCallback() instead.' );
      renderStates.addPreRenderCallback( callback );

    };

    this.removePreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePreRenderCallback() is deprecated. Use .removePreRenderCallback() instead.' );
      renderStates.removePreRenderCallback( callback );

    };

    this.addPostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostRenderCallback() is deprecated. Use .addPostRenderCallback() instead.' );
      renderStates.addPostRenderCallback( callback );

    };

    this.removePostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostRenderCallback() is deprecated. Use .removePostRenderCallback() instead.' );
      renderStates.removePostRenderCallback( callback );

    };

    //

    this.setClearColorHex = function(hex:Int, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColorHex() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( hex, alpha );

    };

    this.setClearColor = function(color:Color, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( color, alpha );

    };

    this.setClearAlpha = function(alpha:Float) {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha( alpha );

    };

    this.setDrawingBufferSize = function(width:Int, height:Int, pixelRatio:Float) {

      console.warn( 'THREE.WebGLRenderer: .setDrawingBufferSize() is deprecated. Use .setDrawingBufferSize() instead.' );
      _width = width;
      _height = height;

      _pixelRatio = pixelRatio;

      canvas.width = Math.floor( width * pixelRatio );
      canvas.height = Math.floor( height * pixelRatio );

      this.setViewport( 0, 0, width, height );

    };

    this.setScissorTest = function(boolean:Bool) {

      console.warn( 'THREE.WebGLRenderer: .setScissorTest() is deprecated. Use .setScissorTest() instead.' );
      state.setScissorTest( _scissorTest = boolean );

    };

    this.getScissor = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getScissor() is deprecated. Use .getScissor() instead.' );
      return target.copy( _scissor );

    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setScissor() is deprecated. Use .setScissor() instead.' );
      if ( x.isVector4 ) {

        _scissor.set( x.x, x.y, x.z, x.w );

      } else {

        _scissor.set( x, y, width, height );

      }

      state.scissor( _currentScissor.copy( _scissor ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getViewport = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getViewport() is deprecated. Use .getViewport() instead.' );
      return target.copy( _viewport );

    };

    this.setViewport = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setViewport() is deprecated. Use .setViewport() instead.' );
      if ( x.isVector4 ) {

        _viewport.set( x.x, x.y, x.z, x.w );

      } else {

        _viewport.set( x, y, width, height );

      }

      state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getRenderTarget = function() {

      console.warn( 'THREE.WebGLRenderer: .getRenderTarget() is deprecated. Use .getRenderTarget() instead.' );
      return _currentRenderTarget;

    };

    this.setRenderTarget = function(renderTarget:WebGLRenderTarget = null) {

      console.warn( 'THREE.WebGLRenderer: .setRenderTarget() is deprecated. Use .setRenderTarget() instead.' );
      _currentRenderTarget = renderTarget;

      if ( renderTarget != null && renderTarget.isWebGLRenderTarget == true ) {

        state.bindFramebuffer( renderTarget.framebuffer );

        if ( renderTarget.scissorTest == true ) {

          state.setScissorTest( true );
          state.scissor( renderTarget.scissor.multiplyScalar( getTargetPixelRatio() ).round() );

        } else {

          state.setScissorTest( false );

        }

        state.viewport( renderTarget.viewport.multiplyScalar( getTargetPixelRatio() ).round() );

      } else {

        state.bindFramebuffer( null );

        state.setScissorTest( _scissorTest );
        state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

      }

    };

    this.readRenderTargetPixels = function(renderTarget:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int, buffer:Array<Float32> = null) {

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is deprecated. Use .readRenderTargetPixels() instead.' );
      if ( renderTarget.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          const gl = _gl;

          let data;

          if ( buffer === null ) {

            data = new Float32Array( width * height * 4 );

          } else {

            data = buffer;

          }

          if ( typeof gl.readPixels !== 'undefined' ) {

            gl.readPixels( x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, data );

          } else {

            console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is not supported. Please check your browser.' );

          }

          state.bindFramebuffer( null );

          return data;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() can only be used with render targets.' );

    };

    //

    this.copyFramebufferToTexture = function(renderTarget:WebGLRenderTarget, source:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() is deprecated. Use .copyFramebufferToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( renderTarget.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          if ( source.isWebGLRenderTarget == true ) {

            state.bindFramebuffer( source.framebuffer );
            textures.copyTextureToTexture( source.texture, renderTarget.texture );

          }

          state.bindFramebuffer( null );

          return;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    //

    this.updateShadowMap = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .updateShadowMap() is deprecated. Use .shadowMap.render() instead.' );
      shadowMap.render( scene, camera );

    };

    this.getShadowMap = function(target:Array<Dynamic> = null) {

      console.warn( 'THREE.WebGLRenderer: .getShadowMap() is deprecated. Use .shadowMap.get() instead.' );
      return shadowMap.get( target );

    };

    //

    this.outputColorSpace = function(colorSpace:Int) {

      console.warn( 'THREE.WebGLRenderer: .outputColorSpace() is deprecated. Use .outputColorSpace() instead.' );
      if ( colorSpace === SRGBColorSpace || colorSpace === LinearSRGBColorSpace ||
        colorSpace === DisplayP3ColorSpace || colorSpace === LinearDisplayP3ColorSpace ) {

        this._outputColorSpace = colorSpace;

      } else {

        console.warn( 'THREE.WebGLRenderer: .outputColorSpace() can only be set to SRGBColorSpace, LinearSRGBColorSpace, DisplayP3ColorSpace, or LinearDisplayP3ColorSpace.' );

      }

    };

    this.getOutputColorSpace = function() {

      console.warn( 'THREE.WebGLRenderer: .getOutputColorSpace() is deprecated. Use .getOutputColorSpace() instead.' );
      return this._outputColorSpace;

    };

    //

    function onContextLost(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context lost.' );
      _isContextLost = true;

    }

    function onContextRestore(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context restored.' );
      _isContextLost = false;

      initGLContext();

      // recreate webxr session

      xr.setSession( null, true );

      // recreate all render targets
      // ( re-allocate framebuffers, textures, etc. )

      _this.setRenderTarget( _currentRenderTarget );

      // attempt to re-bind the objects (for re-created webgl context)

      for (var i in renderLists.objects) {

        const object = renderLists.objects[i];

        if ( object.isMesh == true ) {

          object.geometry.groupsNeedUpdate = true;

        }

        object.needsUpdate = true;

      }

      // re-render

      _this.render( _emptyScene, _currentCamera, _currentRenderTarget, true );

    }

    function onContextCreationError( event:Dynamic ) {

      console.error( 'THREE.WebGLRenderer: WebGL context creation error.' );
      _isContextLost = true;

    }

    //

    function getDepthBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.depthBuffer;

      }

      return _gl.depthBuffer;

    }

    function getStencilBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.stencilBuffer;

      }

      return _gl.stencilBuffer;

    }

    //

    this.getDepthTexture = function(renderTarget:WebGLRenderTarget):Dynamic {

      var depthTexture = null;

      if ( renderTarget.isWebGLRenderTarget == true ) {

        depthTexture = renderTarget.depthTexture;

      } else {

        if ( _this.extensions.get( 'WEBGL_depth_texture' ) ) {

          depthTexture = properties.get( renderTarget, 'depthTexture' );

          if ( depthTexture == null ) {

            depthTexture = new WebGLRenderTarget( _width, _height, {

              depthBuffer: true,
              stencilBuffer: false,
              format: Constants.DepthFormat,
              type: Constants.UnsignedShortType

            } );

            properties.set( renderTarget, 'depthTexture', depthTexture );

          }

        }

      }

      return depthTexture;

    };

    this.isWebGL1 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 1' ) >= 0;

    };

    this.isWebGL2 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 2' ) >= 0;

    };

    //

    this.getLinearToneMapping = function() {

      return this.toneMapping === Constants.LinearToneMapping;

    };

    this.setLinearToneMapping = function() {

      this.toneMapping = Constants.LinearToneMapping;

    };

    this.getReinhardToneMapping = function() {

      return this.toneMapping === Constants.ReinhardToneMapping;

    };

    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2ToneMapping;

    };

    this.setUncharted2ToneMapping = function() {

      this.toneMapping = Constants.Uncharted2ToneMapping;

    };

    this.getCineonToneMapping = function() {

      return this.toneMapping === Constants.CineonToneMapping;

    };

    this.setCineonToneMapping = function() {

      this.toneMapping = Constants.CineonToneMapping;

    };

    this.getACESFilmicToneMapping = function() {

      return this.toneMapping === Constants.ACESFilmicToneMapping;

    };

    this.setACESFilmicToneMapping = function() {

      this.toneMapping = Constants.ACESFilmicToneMapping;

    };

    this.getCustomToneMapping = function() {

      return this.toneMapping === Constants.CustomToneMapping;

    };

    this.setCustomToneMapping = function() {

      this.toneMapping = Constants.CustomToneMapping;

    };

    this.getNoToneMapping = function() {

      return this.toneMapping === Constants.NoToneMapping;

    };

    this.setNoToneMapping = function() {

      this.toneMapping = Constants.NoToneMapping;

    };

    //

    this.getPhysicalLights = function() {

      return this._useLegacyLights === false;

    };

    this.setPhysicalLights = function() {

      this._useLegacyLights = false;

    };

    this.getLegacyLights = function() {

      return this._useLegacyLights === true;

    };

    this.setLegacyLights = function() {

      this._useLegacyLights = true;

    };

    //

    this.getActiveCubeFace = function() {

      return _currentActiveCubeFace;

    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but are deprecated)

    this.gammaFactor = function(factor:Float = 2.0) {

      console.warn( 'THREE.WebGLRenderer: .gammaFactor() is now obsolete. Use .outputColorSpace( THREE.SRGBColorSpace ) for sRGB or THREE.LinearSRGBColorSpace for linear color space.' );

      this.outputColorSpace( factor === 2.0 ? Constants.SRGBColorSpace : Constants.LinearSRGBColorSpace );

    };

    //

    this.getGammaFactor = function() {

      return this.getOutputColorSpace() === Constants.SRGBColorSpace ? 2.0 : 1.0;

    };

    //

    this.getMaxAnisotropy = function() {

      return capabilities.getMaxAnisotropy();

    };

    //

    this.getPrecision = function() {

      return capabilities.precision;

    };

    //

    this.getRenderList = function() {

      return renderLists;

    };

    //

    this.addPostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostProcess() is no longer supported.' );

    };

    this.removePostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostProcess() is no longer supported.' );

    };

    this.getClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearColor() is deprecated. Use .getClearColor() instead.' );
      return background.getClearColor();

    };

    this.setClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor.apply( background, arguments );

    };

    this.getClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearAlpha() is deprecated. Use .getClearAlpha() instead.' );
      return background.getClearAlpha();

    };

    this.setClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha.apply( background, arguments );

    };

    //

    this.getMaxTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextures() is deprecated. Use .capabilities.maxTextures instead.' );
      return capabilities.maxTextures;

    };

    this.getMaxVertexUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexUniforms() is deprecated. Use .capabilities.maxVertexUniforms instead.' );
      return capabilities.maxVertexUniforms;

    };

    this.getMaxFragmentUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxFragmentUniforms() is deprecated. Use .capabilities.maxFragmentUniforms instead.' );
      return capabilities.maxFragmentUniforms;

    };

    this.getMaxVaryings = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVaryings() is deprecated. Use .capabilities.maxVaryings instead.' );
      return capabilities.maxVaryings;

    };

    this.getMaxVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexTextures() is deprecated. Use .capabilities.maxVertexTextures instead.' );
      return capabilities.maxVertexTextures;

    };

    this.getMaxTextureSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextureSize() is deprecated. Use .capabilities.maxTextureSize instead.' );
      return capabilities.maxTextureSize;

    };

    this.getMaxCubemapSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxCubemapSize() is deprecated. Use .capabilities.maxCubemapSize instead.' );
      return capabilities.maxCubemapSize;

    };

    this.getMaxAnisotropy = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxAnisotropy() is deprecated. Use .capabilities.getMaxAnisotropy() instead.' );
      return capabilities.getMaxAnisotropy();

    };

    this.getPrecision = function() {

      console.warn( 'THREE.WebGLRenderer: .getPrecision() is deprecated. Use .capabilities.precision instead.' );
      return capabilities.precision;

    };

    this.getSupportsStandardDerivatives = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsStandardDerivatives() is deprecated. Use .capabilities.standardDerivatives instead.' );
      return capabilities.standardDerivatives;

    };

    this.getSupportsInstancedArrays = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsInstancedArrays() is deprecated. Use .capabilities.instancedArrays instead.' );
      return capabilities.instancedArrays;

    };

    this.getSupportsVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsVertexTextures() is deprecated. Use .capabilities.vertexTextures instead.' );
      return capabilities.vertexTextures;

    };

    this.getSupportsFloatTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatTextures() is deprecated. Use .capabilities.floatTextures instead.' );
      return capabilities.floatTextures;

    };

    this.getSupportsFloatFramebuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatFramebuffers() is deprecated. Use .capabilities.floatFramebuffers instead.' );
      return capabilities.floatFramebuffers;

    };

    this.getSupportsSRGB = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsSRGB() is deprecated. Use .capabilities.sRGB instead.' );
      return capabilities.sRGB;

    };

    this.getSupportsWebGL2 = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsWebGL2() is deprecated. Use .capabilities.isWebGL2 instead.' );
      return capabilities.isWebGL2;

    };

    this.getSupportsDrawBuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsDrawBuffers() is deprecated. Use .capabilities.drawBuffers instead.' );
      return capabilities.drawBuffers;

    };

    this.getSupportsLinearFiltering = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsLinearFiltering() is deprecated. Use .capabilities.linearFiltering instead.' );
      return capabilities.linearFiltering;

    };

    this.getSupportsTextureFloatLinear = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsTextureFloatLinear() is deprecated. Use .capabilities.textureFloatLinear instead.' );
      return capabilities.textureFloatLinear;

    };

    //

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use .setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.compile = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .compile() is deprecated. Use .render() instead.' );
      this.render( scene, camera );

    };

    // Backward compatibility:

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use xr.setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.initTexture = function(texture:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .initTexture() is deprecated. Use .initTexture() instead.' );
      textures.initTexture( texture );

    };

    //

    this.addPreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPreRenderCallback() is deprecated. Use .addPreRenderCallback() instead.' );
      renderStates.addPreRenderCallback( callback );

    };

    this.removePreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePreRenderCallback() is deprecated. Use .removePreRenderCallback() instead.' );
      renderStates.removePreRenderCallback( callback );

    };

    this.addPostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostRenderCallback() is deprecated. Use .addPostRenderCallback() instead.' );
      renderStates.addPostRenderCallback( callback );

    };

    this.removePostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostRenderCallback() is deprecated. Use .removePostRenderCallback() instead.' );
      renderStates.removePostRenderCallback( callback );

    };

    //

    this.setClearColorHex = function(hex:Int, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColorHex() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( hex, alpha );

    };

    this.setClearColor = function(color:Color, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( color, alpha );

    };

    this.setClearAlpha = function(alpha:Float) {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha( alpha );

    };

    this.setDrawingBufferSize = function(width:Int, height:Int, pixelRatio:Float) {

      console.warn( 'THREE.WebGLRenderer: .setDrawingBufferSize() is deprecated. Use .setDrawingBufferSize() instead.' );
      _width = width;
      _height = height;

      _pixelRatio = pixelRatio;

      canvas.width = Math.floor( width * pixelRatio );
      canvas.height = Math.floor( height * pixelRatio );

      this.setViewport( 0, 0, width, height );

    };

    this.setScissorTest = function(boolean:Bool) {

      console.warn( 'THREE.WebGLRenderer: .setScissorTest() is deprecated. Use .setScissorTest() instead.' );
      state.setScissorTest( _scissorTest = boolean );

    };

    this.getScissor = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getScissor() is deprecated. Use .getScissor() instead.' );
      return target.copy( _scissor );

    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setScissor() is deprecated. Use .setScissor() instead.' );
      if ( x.isVector4 ) {

        _scissor.set( x.x, x.y, x.z, x.w );

      } else
    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setScissor() is deprecated. Use .setScissor() instead.' );
      if ( x.isVector4 ) {

        _scissor.set( x.x, x.y, x.z, x.w );

      } else {

        _scissor.set( x, y, width, height );

      }

      state.scissor( _currentScissor.copy( _scissor ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getViewport = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getViewport() is deprecated. Use .getViewport() instead.' );
      return target.copy( _viewport );

    };

    this.setViewport = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setViewport() is deprecated. Use .setViewport() instead.' );
      if ( x.isVector4 ) {

        _viewport.set( x.x, x.y, x.z, x.w );

      } else {

        _viewport.set( x, y, width, height );

      }

      state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getRenderTarget = function() {

      console.warn( 'THREE.WebGLRenderer: .getRenderTarget() is deprecated. Use .getRenderTarget() instead.' );
      return _currentRenderTarget;

    };

    this.setRenderTarget = function(renderTarget:WebGLRenderTarget = null) {

      console.warn( 'THREE.WebGLRenderer: .setRenderTarget() is deprecated. Use .setRenderTarget() instead.' );
      _currentRenderTarget = renderTarget;

      if ( renderTarget != null && renderTarget.isWebGLRenderTarget == true ) {

        state.bindFramebuffer( renderTarget.framebuffer );

        if ( renderTarget.scissorTest == true ) {

          state.setScissorTest( true );
          state.scissor( renderTarget.scissor.multiplyScalar( getTargetPixelRatio() ).round() );

        } else {

          state.setScissorTest( false );

        }

        state.viewport( renderTarget.viewport.multiplyScalar( getTargetPixelRatio() ).round() );

      } else {

        state.bindFramebuffer( null );

        state.setScissorTest( _scissorTest );
        state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

      }

    };

    this.readRenderTargetPixels = function(renderTarget:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int, buffer:Array<Float32> = null) {

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is deprecated. Use .readRenderTargetPixels() instead.' );
      if ( renderTarget.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          const gl = _gl;

          let data;

          if ( buffer === null ) {

            data = new Float32Array( width * height * 4 );

          } else {

            data = buffer;

          }

          if ( typeof gl.readPixels !== 'undefined' ) {

            gl.readPixels( x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, data );

          } else {

            console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is not supported. Please check your browser.' );

          }

          state.bindFramebuffer( null );

          return data;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() can only be used with render targets.' );

    };

    //

    this.copyFramebufferToTexture = function(renderTarget:WebGLRenderTarget, source:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() is deprecated. Use .copyFramebufferToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( renderTarget.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          if ( source.isWebGLRenderTarget == true ) {

            state.bindFramebuffer( source.framebuffer );
            textures.copyTextureToTexture( source.texture, renderTarget.texture );

          }

          state.bindFramebuffer( null );

          return;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    //

    this.updateShadowMap = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .updateShadowMap() is deprecated. Use .shadowMap.render() instead.' );
      shadowMap.render( scene, camera );

    };

    this.getShadowMap = function(target:Array<Dynamic> = null) {

      console.warn( 'THREE.WebGLRenderer: .getShadowMap() is deprecated. Use .shadowMap.get() instead.' );
      return shadowMap.get( target );

    };

    //

    this.outputColorSpace = function(colorSpace:Int) {

      console.warn( 'THREE.WebGLRenderer: .outputColorSpace() is deprecated. Use .outputColorSpace() instead.' );
      if ( colorSpace === SRGBColorSpace || colorSpace === LinearSRGBColorSpace ||
        colorSpace === DisplayP3ColorSpace || colorSpace === LinearDisplayP3ColorSpace ) {

        this._outputColorSpace = colorSpace;

      } else {

        console.warn( 'THREE.WebGLRenderer: .outputColorSpace() can only be set to SRGBColorSpace, LinearSRGBColorSpace, DisplayP3ColorSpace, or LinearDisplayP3ColorSpace.' );

      }

    };

    this.getOutputColorSpace = function() {

      console.warn( 'THREE.WebGLRenderer: .getOutputColorSpace() is deprecated. Use .getOutputColorSpace() instead.' );
      return this._outputColorSpace;

    };

    //

    function onContextLost(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context lost.' );
      _isContextLost = true;

    }

    function onContextRestore(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context restored.' );
      _isContextLost = false;

      initGLContext();

      // recreate webxr session

      xr.setSession( null, true );

      // recreate all render targets
      // ( re-allocate framebuffers, textures, etc. )

      _this.setRenderTarget( _currentRenderTarget );

      // attempt to re-bind the objects (for re-created webgl context)

      for (var i in renderLists.objects) {

        const object = renderLists.objects[i];

        if ( object.isMesh == true ) {

          object.geometry.groupsNeedUpdate = true;

        }

        object.needsUpdate = true;

      }

      // re-render

      _this.render( _emptyScene, _currentCamera, _currentRenderTarget, true );

    }

    function onContextCreationError( event:Dynamic ) {

      console.error( 'THREE.WebGLRenderer: WebGL context creation error.' );
      _isContextLost = true;

    }

    //

    function getDepthBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.depthBuffer;

      }

      return _gl.depthBuffer;

    }

    function getStencilBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.stencilBuffer;

      }

      return _gl.stencilBuffer;

    }

    //

    this.getDepthTexture = function(renderTarget:WebGLRenderTarget):Dynamic {

      var depthTexture = null;

      if ( renderTarget.isWebGLRenderTarget == true ) {

        depthTexture = renderTarget.depthTexture;

      } else {

        if ( _this.extensions.get( 'WEBGL_depth_texture' ) ) {

          depthTexture = properties.get( renderTarget, 'depthTexture' );

          if ( depthTexture == null ) {

            depthTexture = new WebGLRenderTarget( _width, _height, {

              depthBuffer: true,
              stencilBuffer: false,
              format: Constants.DepthFormat,
              type: Constants.UnsignedShortType

            } );

            properties.set( renderTarget, 'depthTexture', depthTexture );

          }

        }

      }

      return depthTexture;

    };

    this.isWebGL1 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 1' ) >= 0;

    };

    this.isWebGL2 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 2' ) >= 0;

    };

    //

    this.getLinearToneMapping = function() {

      return this.toneMapping === Constants.LinearToneMapping;

    };

    this.setLinearToneMapping = function() {

      this.toneMapping = Constants.LinearToneMapping;

    };

    this.getReinhardToneMapping = function() {

      return this.toneMapping === Constants.ReinhardToneMapping;

    };

    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2ToneMapping;

    };

    this.setUncharted2ToneMapping = function() {

      this.toneMapping = Constants.Uncharted2ToneMapping;

    };

    this.getCineonToneMapping = function() {

      return this.toneMapping === Constants.CineonToneMapping;

    };

    this.setCineonToneMapping = function() {

      this.toneMapping = Constants.CineonToneMapping;

    };

    this.getACESFilmicToneMapping = function() {

      return this.toneMapping === Constants.ACESFilmicToneMapping;

    };

    this.setACESFilmicToneMapping = function() {

      this.toneMapping = Constants.ACESFilmicToneMapping;

    };

    this.getCustomToneMapping = function() {

      return this.toneMapping === Constants.CustomToneMapping;

    };

    this.setCustomToneMapping = function() {

      this.toneMapping = Constants.CustomToneMapping;

    };

    this.getNoToneMapping = function() {

      return this.toneMapping === Constants.NoToneMapping;

    };

    this.setNoToneMapping = function() {

      this.toneMapping = Constants.NoToneMapping;

    };

    //

    this.getPhysicalLights = function() {

      return this._useLegacyLights === false;

    };

    this.setPhysicalLights = function() {

      this._useLegacyLights = false;

    };

    this.getLegacyLights = function() {

      return this._useLegacyLights === true;

    };

    this.setLegacyLights = function() {

      this._useLegacyLights = true;

    };

    //

    this.getActiveCubeFace = function() {

      return _currentActiveCubeFace;

    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but are deprecated)

    this.gammaFactor = function(factor:Float = 2.0) {

      console.warn( 'THREE.WebGLRenderer: .gammaFactor() is now obsolete. Use .outputColorSpace( THREE.SRGBColorSpace ) for sRGB or THREE.LinearSRGBColorSpace for linear color space.' );

      this.outputColorSpace( factor === 2.0 ? Constants.SRGBColorSpace : Constants.LinearSRGBColorSpace );

    };

    //

    this.getGammaFactor = function() {

      return this.getOutputColorSpace() === Constants.SRGBColorSpace ? 2.0 : 1.0;

    };

    //

    this.getMaxAnisotropy = function() {

      return capabilities.getMaxAnisotropy();

    };

    //

    this.getPrecision = function() {

      return capabilities.precision;

    };

    //

    this.getRenderList = function() {

      return renderLists;

    };

    //

    this.addPostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostProcess() is no longer supported.' );

    };

    this.removePostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostProcess() is no longer supported.' );

    };

    this.getClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearColor() is deprecated. Use .getClearColor() instead.' );
      return background.getClearColor();

    };

    this.setClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor.apply( background, arguments );

    };

    this.getClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearAlpha() is deprecated. Use .getClearAlpha() instead.' );
      return background.getClearAlpha();

    };

    this.setClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha.apply( background, arguments );

    };

    //

    this.getMaxTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextures() is deprecated. Use .capabilities.maxTextures instead.' );
      return capabilities.maxTextures;

    };

    this.getMaxVertexUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexUniforms() is deprecated. Use .capabilities.maxVertexUniforms instead.' );
      return capabilities.maxVertexUniforms;

    };

    this.getMaxFragmentUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxFragmentUniforms() is deprecated. Use .capabilities.maxFragmentUniforms instead.' );
      return capabilities.maxFragmentUniforms;

    };

    this.getMaxVaryings = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVaryings() is deprecated. Use .capabilities.maxVaryings instead.' );
      return capabilities.maxVaryings;

    };

    this.getMaxVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexTextures() is deprecated. Use .capabilities.maxVertexTextures instead.' );
      return capabilities.maxVertexTextures;

    };

    this.getMaxTextureSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextureSize() is deprecated. Use .capabilities.maxTextureSize instead.' );
      return capabilities.maxTextureSize;

    };

    this.getMaxCubemapSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxCubemapSize() is deprecated. Use .capabilities.maxCubemapSize instead.' );
      return capabilities.maxCubemapSize;

    };

    this.getMaxAnisotropy = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxAnisotropy() is deprecated. Use .capabilities.getMaxAnisotropy() instead.' );
      return capabilities.getMaxAnisotropy();

    };

    this.getPrecision = function() {

      console.warn( 'THREE.WebGLRenderer: .getPrecision() is deprecated. Use .capabilities.precision instead.' );
      return capabilities.precision;

    };

    this.getSupportsStandardDerivatives = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsStandardDerivatives() is deprecated. Use .capabilities.standardDerivatives instead.' );
      return capabilities.standardDerivatives;

    };

    this.getSupportsInstancedArrays = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsInstancedArrays() is deprecated. Use .capabilities.instancedArrays instead.' );
      return capabilities.instancedArrays;

    };

    this.getSupportsVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsVertexTextures() is deprecated. Use .capabilities.vertexTextures instead.' );
      return capabilities.vertexTextures;

    };

    this.getSupportsFloatTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatTextures() is deprecated. Use .capabilities.floatTextures instead.' );
      return capabilities.floatTextures;

    };

    this.getSupportsFloatFramebuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatFramebuffers() is deprecated. Use .capabilities.floatFramebuffers instead.' );
      return capabilities.floatFramebuffers;

    };

    this.getSupportsSRGB = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsSRGB() is deprecated. Use .capabilities.sRGB instead.' );
      return capabilities.sRGB;

    };

    this.getSupportsWebGL2 = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsWebGL2() is deprecated. Use .capabilities.isWebGL2 instead.' );
      return capabilities.isWebGL2;

    };

    this.getSupportsDrawBuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsDrawBuffers() is deprecated. Use .capabilities.drawBuffers instead.' );
      return capabilities.drawBuffers;

    };

    this.getSupportsLinearFiltering = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsLinearFiltering() is deprecated. Use .capabilities.linearFiltering instead.' );
      return capabilities.linearFiltering;

    };

    this.getSupportsTextureFloatLinear = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsTextureFloatLinear() is deprecated. Use .capabilities.textureFloatLinear instead.' );
      return capabilities.textureFloatLinear;

    };

    //

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use .setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.compile = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .compile() is deprecated. Use .render() instead.' );
      this.render( scene, camera );

    };

    // Backward compatibility:

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use xr.setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.initTexture = function(texture:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .initTexture() is deprecated. Use .initTexture() instead.' );
      textures.initTexture( texture );

    };

    //

    this.addPreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPreRenderCallback() is deprecated. Use .addPreRenderCallback() instead.' );
      renderStates.addPreRenderCallback( callback );

    };

    this.removePreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePreRenderCallback() is deprecated. Use .removePreRenderCallback() instead.' );
      renderStates.removePreRenderCallback( callback );

    };

    this.addPostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostRenderCallback() is deprecated. Use .addPostRenderCallback() instead.' );
      renderStates.addPostRenderCallback( callback );

    };

    this.removePostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostRenderCallback() is deprecated. Use .removePostRenderCallback() instead.' );
      renderStates.removePostRenderCallback( callback );

    };

    //

    this.setClearColorHex = function(hex:Int, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColorHex() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( hex, alpha );

    };

    this.setClearColor = function(color:Color, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( color, alpha );

    };

    this.setClearAlpha = function(alpha:Float) {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha( alpha );

    };

    this.setDrawingBufferSize = function(width:Int, height:Int, pixelRatio:Float) {

      console.warn( 'THREE.WebGLRenderer: .setDrawingBufferSize() is deprecated. Use .setDrawingBufferSize() instead.' );
      _width = width;
      _height = height;

      _pixelRatio = pixelRatio;

      canvas.width = Math.floor( width * pixelRatio );
      canvas.height = Math.floor( height * pixelRatio );

      this.setViewport( 0, 0, width, height );

    };

    this.setScissorTest = function(boolean:Bool) {

      console.warn( 'THREE.WebGLRenderer: .setScissorTest() is deprecated. Use .setScissorTest() instead.' );
      state.setScissorTest( _scissorTest = boolean );

    };

    this.getScissor = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getScissor() is deprecated. Use .getScissor() instead.' );
      return target.copy( _scissor );

    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setScissor() is deprecated. Use .setScissor() instead.' );
      if ( x.isVector4 ) {

        _scissor.set( x.x, x.y, x.z, x.w );

      } else {

        _scissor.set( x, y, width, height );

      }

      state.scissor( _currentScissor.copy( _scissor ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getViewport = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getViewport() is deprecated. Use .getViewport() instead.' );
      return target.copy( _viewport );

    };

    this.setViewport = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setViewport() is deprecated. Use .setViewport() instead.' );
      if ( x.isVector4 ) {

        _viewport.set( x.x, x.y, x.z, x.w );

      } else {

        _viewport.set( x, y, width, height );

      }

      state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getRenderTarget = function() {

      console.warn( 'THREE.WebGLRenderer: .getRenderTarget() is deprecated. Use .getRenderTarget() instead.' );
      return _currentRenderTarget;

    };

    this.setRenderTarget = function(renderTarget:WebGLRenderTarget = null) {

      console.warn( 'THREE.WebGLRenderer: .setRenderTarget() is deprecated. Use .setRenderTarget() instead.' );
      _currentRenderTarget = renderTarget;

      if ( renderTarget != null && renderTarget.isWebGLRenderTarget == true ) {

        state.bindFramebuffer( renderTarget.framebuffer );

        if ( renderTarget.scissorTest == true ) {

          state.setScissorTest( true );
          state.scissor( renderTarget.scissor.multiplyScalar( getTargetPixelRatio() ).round() );

        } else {

          state.setScissorTest( false );

        }

        state.viewport( renderTarget.viewport.multiplyScalar( getTargetPixelRatio() ).round() );

      } else {

        state.bindFramebuffer( null );

        state.setScissorTest( _scissorTest );
        state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

      }

    };

    this.readRenderTargetPixels = function(renderTarget:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int, buffer:Array<Float32> = null) {

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is deprecated. Use .readRenderTargetPixels() instead.' );
      if ( renderTarget.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          const gl = _gl;

          let data;

          if ( buffer === null ) {

            data = new Float32Array( width * height * 4 );

          } else {

            data = buffer;

          }

          if ( typeof gl.readPixels !== 'undefined' ) {

            gl.readPixels( x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, data );

          } else {

            console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is not supported. Please check your browser.' );

          }

          state.bindFramebuffer( null );

          return data;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() can only be used with render targets.' );

    };

    //

    this.copyFramebufferToTexture = function(renderTarget:WebGLRenderTarget, source:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() is deprecated. Use .copyFramebufferToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( renderTarget.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          if ( source.isWebGLRenderTarget == true ) {

            state.bindFramebuffer( source.framebuffer );
            textures.copyTextureToTexture( source.texture, renderTarget.texture );

          }

          state.bindFramebuffer( null );

          return;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    //

    this.updateShadowMap = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .updateShadowMap() is deprecated. Use .shadowMap.render() instead.' );
      shadowMap.render( scene, camera );

    };

    this.getShadowMap = function(target:Array<Dynamic> = null) {

      console.warn( 'THREE.WebGLRenderer: .getShadowMap() is deprecated. Use .shadowMap.get() instead.' );
      return shadowMap.get( target );

    };

    //

    this.outputColorSpace = function(colorSpace:Int) {

      console.warn( 'THREE.WebGLRenderer: .outputColorSpace() is deprecated. Use .outputColorSpace() instead.' );
      if ( colorSpace === SRGBColorSpace || colorSpace === LinearSRGBColorSpace ||
        colorSpace === DisplayP3ColorSpace || colorSpace === LinearDisplayP3ColorSpace ) {

        this._outputColorSpace = colorSpace;

      } else {

        console.warn( 'THREE.WebGLRenderer: .outputColorSpace() can only be set to SRGBColorSpace, LinearSRGBColorSpace, DisplayP3ColorSpace, or LinearDisplayP3ColorSpace.' );

      }

    };

    this.getOutputColorSpace = function() {

      console.warn( 'THREE.WebGLRenderer: .getOutputColorSpace() is deprecated. Use .getOutputColorSpace() instead.' );
      return this._outputColorSpace;

    };

    //

    function onContextLost(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context lost.' );
      _isContextLost = true;

    }

    function onContextRestore(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context restored.' );
      _isContextLost = false;

      initGLContext();

      // recreate webxr session

      xr.setSession( null, true );

      // recreate all render targets
      // ( re-allocate framebuffers, textures, etc. )

      _this.setRenderTarget( _currentRenderTarget );

      // attempt to re-bind the objects (for re-created webgl context)

      for (var i in renderLists.objects) {

        const object = renderLists.objects[i];

        if ( object.isMesh == true ) {

          object.geometry.groupsNeedUpdate = true;

        }

        object.needsUpdate = true;

      }

      // re-render

      _this.render( _emptyScene, _currentCamera, _currentRenderTarget, true );

    }

    function onContextCreationError( event:Dynamic ) {

      console.error( 'THREE.WebGLRenderer: WebGL context creation error.' );
      _isContextLost = true;

    }

    //

    function getDepthBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.depthBuffer;

      }

      return _gl.depthBuffer;

    }

    function getStencilBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.stencilBuffer;

      }

      return _gl.stencilBuffer;

    }

    //

    this.getDepthTexture = function(renderTarget:WebGLRenderTarget):Dynamic {

      var depthTexture = null;

      if ( renderTarget.isWebGLRenderTarget == true ) {

        depthTexture = renderTarget.depthTexture;

      } else {

        if ( _this.extensions.get( 'WEBGL_depth_texture' ) ) {

          depthTexture = properties.get( renderTarget, 'depthTexture' );

          if ( depthTexture == null ) {

            depthTexture = new WebGLRenderTarget( _width, _height, {

              depthBuffer: true,
              stencilBuffer: false,
              format: Constants.DepthFormat,
              type: Constants.UnsignedShortType

            } );

            properties.set( renderTarget, 'depthTexture', depthTexture );

          }

        }

      }

      return depthTexture;

    };

    this.isWebGL1 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 1' ) >= 0;

    };

    this.isWebGL2 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 2' ) >= 0;

    };

    //

    this.getLinearToneMapping = function() {

      return this.toneMapping === Constants.LinearToneMapping;

    };

    this.setLinearToneMapping = function() {

      this.toneMapping = Constants.LinearToneMapping;

    };

    this.getReinhardToneMapping = function() {

      return this.toneMapping === Constants.ReinhardToneMapping;

    };

    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2Tone
    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2ToneMapping;

    };

    this.setUncharted2ToneMapping = function() {

      this.toneMapping = Constants.Uncharted2ToneMapping;

    };

    this.getCineonToneMapping = function() {

      return this.toneMapping === Constants.CineonToneMapping;

    };

    this.setCineonToneMapping = function() {

      this.toneMapping = Constants.CineonToneMapping;

    };

    this.getACESFilmicToneMapping = function() {

      return this.toneMapping === Constants.ACESFilmicToneMapping;

    };

    this.setACESFilmicToneMapping = function() {

      this.toneMapping = Constants.ACESFilmicToneMapping;

    };

    this.getCustomToneMapping = function() {

      return this.toneMapping === Constants.CustomToneMapping;

    };

    this.setCustomToneMapping = function() {

      this.toneMapping = Constants.CustomToneMapping;

    };

    this.getNoToneMapping = function() {

      return this.toneMapping === Constants.NoToneMapping;

    };

    this.setNoToneMapping = function() {

      this.toneMapping = Constants.NoToneMapping;

    };

    //

    this.getPhysicalLights = function() {

      return this._useLegacyLights === false;

    };

    this.setPhysicalLights = function() {

      this._useLegacyLights = false;

    };

    this.getLegacyLights = function() {

      return this._useLegacyLights === true;

    };

    this.setLegacyLights = function() {

      this._useLegacyLights = true;

    };

    //

    this.getActiveCubeFace = function() {

      return _currentActiveCubeFace;

    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but are deprecated)

    this.gammaFactor = function(factor:Float = 2.0) {

      console.warn( 'THREE.WebGLRenderer: .gammaFactor() is now obsolete. Use .outputColorSpace( THREE.SRGBColorSpace ) for sRGB or THREE.LinearSRGBColorSpace for linear color space.' );

      this.outputColorSpace( factor === 2.0 ? Constants.SRGBColorSpace : Constants.LinearSRGBColorSpace );

    };

    //

    this.getGammaFactor = function() {

      return this.getOutputColorSpace() === Constants.SRGBColorSpace ? 2.0 : 1.0;

    };

    //

    this.getMaxAnisotropy = function() {

      return capabilities.getMaxAnisotropy();

    };

    //

    this.getPrecision = function() {

      return capabilities.precision;

    };

    //

    this.getRenderList = function() {

      return renderLists;

    };

    //

    this.addPostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostProcess() is no longer supported.' );

    };

    this.removePostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostProcess() is no longer supported.' );

    };

    this.getClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearColor() is deprecated. Use .getClearColor() instead.' );
      return background.getClearColor();

    };

    this.setClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor.apply( background, arguments );

    };

    this.getClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearAlpha() is deprecated. Use .getClearAlpha() instead.' );
      return background.getClearAlpha();

    };

    this.setClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha.apply( background, arguments );

    };

    //

    this.getMaxTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextures() is deprecated. Use .capabilities.maxTextures instead.' );
      return capabilities.maxTextures;

    };

    this.getMaxVertexUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexUniforms() is deprecated. Use .capabilities.maxVertexUniforms instead.' );
      return capabilities.maxVertexUniforms;

    };

    this.getMaxFragmentUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxFragmentUniforms() is deprecated. Use .capabilities.maxFragmentUniforms instead.' );
      return capabilities.maxFragmentUniforms;

    };

    this.getMaxVaryings = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVaryings() is deprecated. Use .capabilities.maxVaryings instead.' );
      return capabilities.maxVaryings;

    };

    this.getMaxVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexTextures() is deprecated. Use .capabilities.maxVertexTextures instead.' );
      return capabilities.maxVertexTextures;

    };

    this.getMaxTextureSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextureSize() is deprecated. Use .capabilities.maxTextureSize instead.' );
      return capabilities.maxTextureSize;

    };

    this.getMaxCubemapSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxCubemapSize() is deprecated. Use .capabilities.maxCubemapSize instead.' );
      return capabilities.maxCubemapSize;

    };

    this.getMaxAnisotropy = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxAnisotropy() is deprecated. Use .capabilities.getMaxAnisotropy() instead.' );
      return capabilities.getMaxAnisotropy();

    };

    this.getPrecision = function() {

      console.warn( 'THREE.WebGLRenderer: .getPrecision() is deprecated. Use .capabilities.precision instead.' );
      return capabilities.precision;

    };

    this.getSupportsStandardDerivatives = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsStandardDerivatives() is deprecated. Use .capabilities.standardDerivatives instead.' );
      return capabilities.standardDerivatives;

    };

    this.getSupportsInstancedArrays = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsInstancedArrays() is deprecated. Use .capabilities.instancedArrays instead.' );
      return capabilities.instancedArrays;

    };

    this.getSupportsVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsVertexTextures() is deprecated. Use .capabilities.vertexTextures instead.' );
      return capabilities.vertexTextures;

    };

    this.getSupportsFloatTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatTextures() is deprecated. Use .capabilities.floatTextures instead.' );
      return capabilities.floatTextures;

    };

    this.getSupportsFloatFramebuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatFramebuffers() is deprecated. Use .capabilities.floatFramebuffers instead.' );
      return capabilities.floatFramebuffers;

    };

    this.getSupportsSRGB = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsSRGB() is deprecated. Use .capabilities.sRGB instead.' );
      return capabilities.sRGB;

    };

    this.getSupportsWebGL2 = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsWebGL2() is deprecated. Use .capabilities.isWebGL2 instead.' );
      return capabilities.isWebGL2;

    };

    this.getSupportsDrawBuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsDrawBuffers() is deprecated. Use .capabilities.drawBuffers instead.' );
      return capabilities.drawBuffers;

    };

    this.getSupportsLinearFiltering = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsLinearFiltering() is deprecated. Use .capabilities.linearFiltering instead.' );
      return capabilities.linearFiltering;

    };

    this.getSupportsTextureFloatLinear = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsTextureFloatLinear() is deprecated. Use .capabilities.textureFloatLinear instead.' );
      return capabilities.textureFloatLinear;

    };

    //

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use .setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.compile = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .compile() is deprecated. Use .render() instead.' );
      this.render( scene, camera );

    };

    // Backward compatibility:

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use xr.setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.initTexture = function(texture:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .initTexture() is deprecated. Use .initTexture() instead.' );
      textures.initTexture( texture );

    };

    //

    this.addPreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPreRenderCallback() is deprecated. Use .addPreRenderCallback() instead.' );
      renderStates.addPreRenderCallback( callback );

    };

    this.removePreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePreRenderCallback() is deprecated. Use .removePreRenderCallback() instead.' );
      renderStates.removePreRenderCallback( callback );

    };

    this.addPostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostRenderCallback() is deprecated. Use .addPostRenderCallback() instead.' );
      renderStates.addPostRenderCallback( callback );

    };

    this.removePostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostRenderCallback() is deprecated. Use .removePostRenderCallback() instead.' );
      renderStates.removePostRenderCallback( callback );

    };

    //

    this.setClearColorHex = function(hex:Int, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColorHex() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( hex, alpha );

    };

    this.setClearColor = function(color:Color, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( color, alpha );

    };

    this.setClearAlpha = function(alpha:Float) {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha( alpha );

    };

    this.setDrawingBufferSize = function(width:Int, height:Int, pixelRatio:Float) {

      console.warn( 'THREE.WebGLRenderer: .setDrawingBufferSize() is deprecated. Use .setDrawingBufferSize() instead.' );
      _width = width;
      _height = height;

      _pixelRatio = pixelRatio;

      canvas.width = Math.floor( width * pixelRatio );
      canvas.height = Math.floor( height * pixelRatio );

      this.setViewport( 0, 0, width, height );

    };

    this.setScissorTest = function(boolean:Bool) {

      console.warn( 'THREE.WebGLRenderer: .setScissorTest() is deprecated. Use .setScissorTest() instead.' );
      state.setScissorTest( _scissorTest = boolean );

    };

    this.getScissor = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getScissor() is deprecated. Use .getScissor() instead.' );
      return target.copy( _scissor );

    };

    this.setScissor = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setScissor() is deprecated. Use .setScissor() instead.' );
      if ( x.isVector4 ) {

        _scissor.set( x.x, x.y, x.z, x.w );

      } else {

        _scissor.set( x, y, width, height );

      }

      state.scissor( _currentScissor.copy( _scissor ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getViewport = function(target:Vector4):Vector4 {

      console.warn( 'THREE.WebGLRenderer: .getViewport() is deprecated. Use .getViewport() instead.' );
      return target.copy( _viewport );

    };

    this.setViewport = function(x:Dynamic, y:Dynamic, width:Dynamic, height:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setViewport() is deprecated. Use .setViewport() instead.' );
      if ( x.isVector4 ) {

        _viewport.set( x.x, x.y, x.z, x.w );

      } else {

        _viewport.set( x, y, width, height );

      }

      state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

    };

    this.getRenderTarget = function() {

      console.warn( 'THREE.WebGLRenderer: .getRenderTarget() is deprecated. Use .getRenderTarget() instead.' );
      return _currentRenderTarget;

    };

    this.setRenderTarget = function(renderTarget:WebGLRenderTarget = null) {

      console.warn( 'THREE.WebGLRenderer: .setRenderTarget() is deprecated. Use .setRenderTarget() instead.' );
      _currentRenderTarget = renderTarget;

      if ( renderTarget != null && renderTarget.isWebGLRenderTarget == true ) {

        state.bindFramebuffer( renderTarget.framebuffer );

        if ( renderTarget.scissorTest == true ) {

          state.setScissorTest( true );
          state.scissor( renderTarget.scissor.multiplyScalar( getTargetPixelRatio() ).round() );

        } else {

          state.setScissorTest( false );

        }

        state.viewport( renderTarget.viewport.multiplyScalar( getTargetPixelRatio() ).round() );

      } else {

        state.bindFramebuffer( null );

        state.setScissorTest( _scissorTest );
        state.viewport( _currentViewport.copy( _viewport ).multiplyScalar( _pixelRatio ).round() );

      }

    };

    this.readRenderTargetPixels = function(renderTarget:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int, buffer:Array<Float32> = null) {

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is deprecated. Use .readRenderTargetPixels() instead.' );
      if ( renderTarget.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          const gl = _gl;

          let data;

          if ( buffer === null ) {

            data = new Float32Array( width * height * 4 );

          } else {

            data = buffer;

          }

          if ( typeof gl.readPixels !== 'undefined' ) {

            gl.readPixels( x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, data );

          } else {

            console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() is not supported. Please check your browser.' );

          }

          state.bindFramebuffer( null );

          return data;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .readRenderTargetPixels() can only be used with render targets.' );

    };

    //

    this.copyFramebufferToTexture = function(renderTarget:WebGLRenderTarget, source:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() is deprecated. Use .copyFramebufferToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( renderTarget.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        var framebuffer = renderTarget.framebuffer;

        if ( framebuffer != null ) {

          state.bindFramebuffer( framebuffer );

          if ( source.isWebGLRenderTarget == true ) {

            state.bindFramebuffer( source.framebuffer );
            textures.copyTextureToTexture( source.texture, renderTarget.texture );

          }

          state.bindFramebuffer( null );

          return;

        }

      }

      console.warn( 'THREE.WebGLRenderer: .copyFramebufferToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    this.copyTextureToTexture = function(source:WebGLRenderTarget, target:WebGLRenderTarget) {

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() is deprecated. Use .copyTextureToTexture() instead.' );
      const gl = _gl;
      const state = this.state;
      const textures = this.textures;

      if ( target.isWebGLRenderTarget == true && source.isWebGLRenderTarget == true ) {

        textures.copyTextureToTexture( source.texture, target.texture );

        return;

      }

      console.warn( 'THREE.WebGLRenderer: .copyTextureToTexture() can only be used with render targets.' );

    };

    //

    this.updateShadowMap = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .updateShadowMap() is deprecated. Use .shadowMap.render() instead.' );
      shadowMap.render( scene, camera );

    };

    this.getShadowMap = function(target:Array<Dynamic> = null) {

      console.warn( 'THREE.WebGLRenderer: .getShadowMap() is deprecated. Use .shadowMap.get() instead.' );
      return shadowMap.get( target );

    };

    //

    this.outputColorSpace = function(colorSpace:Int) {

      console.warn( 'THREE.WebGLRenderer: .outputColorSpace() is deprecated. Use .outputColorSpace() instead.' );
      if ( colorSpace === SRGBColorSpace || colorSpace === LinearSRGBColorSpace ||
        colorSpace === DisplayP3ColorSpace || colorSpace === LinearDisplayP3ColorSpace ) {

        this._outputColorSpace = colorSpace;

      } else {

        console.warn( 'THREE.WebGLRenderer: .outputColorSpace() can only be set to SRGBColorSpace, LinearSRGBColorSpace, DisplayP3ColorSpace, or LinearDisplayP3ColorSpace.' );

      }

    };

    this.getOutputColorSpace = function() {

      console.warn( 'THREE.WebGLRenderer: .getOutputColorSpace() is deprecated. Use .getOutputColorSpace() instead.' );
      return this._outputColorSpace;

    };

    //

    function onContextLost(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context lost.' );
      _isContextLost = true;

    }

    function onContextRestore(event:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: WebGL context restored.' );
      _isContextLost = false;

      initGLContext();

      // recreate webxr session

      xr.setSession( null, true );

      // recreate all render targets
      // ( re-allocate framebuffers, textures, etc. )

      _this.setRenderTarget( _currentRenderTarget );

      // attempt to re-bind the objects (for re-created webgl context)

      for (var i in renderLists.objects) {

        const object = renderLists.objects[i];

        if ( object.isMesh == true ) {

          object.geometry.groupsNeedUpdate = true;

        }

        object.needsUpdate = true;

      }

      // re-render

      _this.render( _emptyScene, _currentCamera, _currentRenderTarget, true );

    }

    function onContextCreationError( event:Dynamic ) {

      console.error( 'THREE.WebGLRenderer: WebGL context creation error.' );
      _isContextLost = true;

    }

    //

    function getDepthBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.depthBuffer;

      }

      return _gl.depthBuffer;

    }

    function getStencilBuffer(renderTarget:WebGLRenderTarget):Dynamic {

      if ( renderTarget.isWebGLRenderTarget == true ) {

        return renderTarget.stencilBuffer;

      }

      return _gl.stencilBuffer;

    }

    //

    this.getDepthTexture = function(renderTarget:WebGLRenderTarget):Dynamic {

      var depthTexture = null;

      if ( renderTarget.isWebGLRenderTarget == true ) {

        depthTexture = renderTarget.depthTexture;

      } else {

        if ( _this.extensions.get( 'WEBGL_depth_texture' ) ) {

          depthTexture = properties.get( renderTarget, 'depthTexture' );

          if ( depthTexture == null ) {

            depthTexture = new WebGLRenderTarget( _width, _height, {

              depthBuffer: true,
              stencilBuffer: false,
              format: Constants.DepthFormat,
              type: Constants.UnsignedShortType

            } );

            properties.set( renderTarget, 'depthTexture', depthTexture );

          }

        }

      }

      return depthTexture;

    };

    this.isWebGL1 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 1' ) >= 0;

    };

    this.isWebGL2 = function() {

      return _gl.getParameter( _gl.VERSION ).indexOf( 'WebGL 2' ) >= 0;

    };

    //

    this.getLinearToneMapping = function() {

      return this.toneMapping === Constants.LinearToneMapping;

    };

    this.setLinearToneMapping = function() {

      this.toneMapping = Constants.LinearToneMapping;

    };

    this.getReinhardToneMapping = function() {

      return this.toneMapping === Constants.ReinhardToneMapping;

    };

    this.setReinhardToneMapping = function() {

      this.toneMapping = Constants.ReinhardToneMapping;

    };

    this.getUncharted2ToneMapping = function() {

      return this.toneMapping === Constants.Uncharted2ToneMapping;

    };

    this.setUncharted2ToneMapping = function() {

      this.toneMapping = Constants.Uncharted2ToneMapping;

    };

    this.getCineonToneMapping = function() {

      return this.toneMapping === Constants.CineonToneMapping;

    };

    this.setCineonToneMapping = function() {

      this.toneMapping = Constants.CineonToneMapping;

    };

    this.getACESFilmicToneMapping = function() {

      return this.toneMapping === Constants.ACESFilmicToneMapping;

    };

    this.setACESFilmicToneMapping = function() {

      this.toneMapping = Constants.ACESFilmicToneMapping;

    };

    this.getCustomToneMapping = function() {

      return this.toneMapping === Constants.CustomToneMapping;

    };

    this.setCustomToneMapping = function() {

      this.toneMapping = Constants.CustomToneMapping;

    };

    this.getNoToneMapping = function() {

      return this.toneMapping === Constants.NoToneMapping;

    };

    this.setNoToneMapping = function() {

      this.toneMapping = Constants.NoToneMapping;

    };

    //

    this.getPhysicalLights = function() {

      return this._useLegacyLights === false;

    };

    this.setPhysicalLights = function() {

      this._useLegacyLights = false;

    };

    this.getLegacyLights = function() {

      return this._useLegacyLights === true;

    };

    this.setLegacyLights = function() {

      this._useLegacyLights = true;

    };

    //

    this.getActiveCubeFace = function() {

      return _currentActiveCubeFace;

    };

    this.getActiveMipmapLevel = function() {

      return _currentActiveMipmapLevel;

    };

    // For backwards-compatibility, these functions still exist (but are deprecated)

    this.gammaFactor = function(factor:Float = 2.0) {

      console.warn( 'THREE.WebGLRenderer: .gammaFactor() is now obsolete. Use .outputColorSpace( THREE.SRGBColorSpace ) for sRGB or THREE.LinearSRGBColorSpace for linear color space.' );

      this.outputColorSpace( factor === 2.0 ? Constants.SRGBColorSpace : Constants.LinearSRGBColorSpace );

    };

    //

    this.getGammaFactor = function() {

      return this.getOutputColorSpace() === Constants.SRGBColorSpace ? 2.0 : 1.0;

    };

    //

    this.getMaxAnisotropy = function() {

      return capabilities.getMaxAnisotropy();

    };

    //

    this.getPrecision = function() {

      return capabilities.precision;

    };

    //

    this.getRenderList = function() {

      return renderLists;

    };

    //

    this.addPostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostProcess() is no longer supported.' );

    };

    this.removePostProcess = function(postProcess:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostProcess() is no longer supported.' );

    };

    this.getClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearColor() is deprecated. Use .getClearColor() instead.' );
      return background.getClearColor();

    };

    this.setClearColor = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearColor() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor.apply( background, arguments );

    };

    this.getClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .getClearAlpha() is deprecated. Use .getClearAlpha() instead.' );
      return background.getClearAlpha();

    };

    this.setClearAlpha = function() {

      console.warn( 'THREE.WebGLRenderer: .setClearAlpha() is deprecated. Use .setClearAlpha() instead.' );
      background.setClearAlpha.apply( background, arguments );

    };

    //

    this.getMaxTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextures() is deprecated. Use .capabilities.maxTextures instead.' );
      return capabilities.maxTextures;

    };

    this.getMaxVertexUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexUniforms() is deprecated. Use .capabilities.maxVertexUniforms instead.' );
      return capabilities.maxVertexUniforms;

    };

    this.getMaxFragmentUniforms = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxFragmentUniforms() is deprecated. Use .capabilities.maxFragmentUniforms instead.' );
      return capabilities.maxFragmentUniforms;

    };

    this.getMaxVaryings = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVaryings() is deprecated. Use .capabilities.maxVaryings instead.' );
      return capabilities.maxVaryings;

    };

    this.getMaxVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxVertexTextures() is deprecated. Use .capabilities.maxVertexTextures instead.' );
      return capabilities.maxVertexTextures;

    };

    this.getMaxTextureSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxTextureSize() is deprecated. Use .capabilities.maxTextureSize instead.' );
      return capabilities.maxTextureSize;

    };

    this.getMaxCubemapSize = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxCubemapSize() is deprecated. Use .capabilities.maxCubemapSize instead.' );
      return capabilities.maxCubemapSize;

    };

    this.getMaxAnisotropy = function() {

      console.warn( 'THREE.WebGLRenderer: .getMaxAnisotropy() is deprecated. Use .capabilities.getMaxAnisotropy() instead.' );
      return capabilities.getMaxAnisotropy();

    };

    this.getPrecision = function() {

      console.warn( 'THREE.WebGLRenderer: .getPrecision() is deprecated. Use .capabilities.precision instead.' );
      return capabilities.precision;

    };

    this.getSupportsStandardDerivatives = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsStandardDerivatives() is deprecated. Use .capabilities.standardDerivatives instead.' );
      return capabilities.standardDerivatives;

    };

    this.getSupportsInstancedArrays = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsInstancedArrays() is deprecated. Use .capabilities.instancedArrays instead.' );
      return capabilities.instancedArrays;

    };

    this.getSupportsVertexTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsVertexTextures() is deprecated. Use .capabilities.vertexTextures instead.' );
      return capabilities.vertexTextures;

    };

    this.getSupportsFloatTextures = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatTextures() is deprecated. Use .capabilities.floatTextures instead.' );
      return capabilities.floatTextures;

    };

    this.getSupportsFloatFramebuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsFloatFramebuffers() is deprecated. Use .capabilities.floatFramebuffers instead.' );
      return capabilities.floatFramebuffers;

    };

    this.getSupportsSRGB = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsSRGB() is deprecated. Use .capabilities.sRGB instead.' );
      return capabilities.sRGB;

    };

    this.getSupportsWebGL2 = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsWebGL2() is deprecated. Use .capabilities.isWebGL2 instead.' );
      return capabilities.isWebGL2;

    };

    this.getSupportsDrawBuffers = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsDrawBuffers() is deprecated. Use .capabilities.drawBuffers instead.' );
      return capabilities.drawBuffers;

    };

    this.getSupportsLinearFiltering = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsLinearFiltering() is deprecated. Use .capabilities.linearFiltering instead.' );
      return capabilities.linearFiltering;

    };

    this.getSupportsTextureFloatLinear = function() {

      console.warn( 'THREE.WebGLRenderer: .getSupportsTextureFloatLinear() is deprecated. Use .capabilities.textureFloatLinear instead.' );
      return capabilities.textureFloatLinear;

    };

    //

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use .setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.compile = function(scene:Dynamic, camera:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .compile() is deprecated. Use .render() instead.' );
      this.render( scene, camera );

    };

    // Backward compatibility:

    this.setAnimationLoop = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .setAnimationLoop() is deprecated. Use xr.setAnimationLoop() instead.' );
      xr.setAnimationLoop( callback );

    };

    //

    this.initTexture = function(texture:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .initTexture() is deprecated. Use .initTexture() instead.' );
      textures.initTexture( texture );

    };

    //

    this.addPreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPreRenderCallback() is deprecated. Use .addPreRenderCallback() instead.' );
      renderStates.addPreRenderCallback( callback );

    };

    this.removePreRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePreRenderCallback() is deprecated. Use .removePreRenderCallback() instead.' );
      renderStates.removePreRenderCallback( callback );

    };

    this.addPostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .addPostRenderCallback() is deprecated. Use .addPostRenderCallback() instead.' );
      renderStates.addPostRenderCallback( callback );

    };

    this.removePostRenderCallback = function(callback:Dynamic) {

      console.warn( 'THREE.WebGLRenderer: .removePostRenderCallback() is deprecated. Use .removePostRenderCallback() instead.' );
      renderStates.removePostRenderCallback( callback );

    };

    //

    this.setClearColorHex = function(hex:Int, alpha:Float = 1) {

      console.warn( 'THREE.WebGLRenderer: .setClearColorHex() is deprecated. Use .setClearColor() instead.' );
      background.setClearColor( hex, alpha );

    };

    this.setClearColor = function(color: