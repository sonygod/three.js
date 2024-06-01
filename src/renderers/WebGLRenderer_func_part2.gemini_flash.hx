import three.renderers.WebGLRenderer;
import three.renderers.WebGLRenderer.State;
import three.core.Background;
import three.core.Object3D;
import three.cameras.Camera;
import three.scenes.Scene;
import three.math.Color;
import three.math.Matrix4;
import three.geometries.Geometry;
import three.materials.Material;
import three.renderers.WebGLProgram;
import three.renderers.WebGLProperties;
import three.renderers.WebGLProgramCache;
import three.renderers.WebGLExtensions;
import three.renderers.WebGLBindingStates;
import three.renderers.WebGLUniformsGroups;
import three.renderers.WebGLGeometries;
import three.renderers.WebGLAttributes;
import three.renderers.WebGLIndexedBufferRenderer;
import three.renderers.WebGLBufferRenderer;
import three.renderers.WebGLShadowMap;
import three.renderers.WebGLInfo;
import three.renderers.WebGLRenderLists;
import three.renderers.WebGLRenderStates;
import three.renderers.WebGLCubeMaps;
import three.renderers.WebGLCubeUVMaps;
import three.renderers.WebGLObjects;
import three.renderers.WebGLAnimation;
import three.renderers.WebGLXR;

class WebGLRendererHaxe extends WebGLRenderer {

  var _emptyScene : Scene;
  var _isContextLost : Bool;
  var _gl : dynamic;
  var _useLegacyLights : Bool;
  var _isWebgl2 : Bool;
  var _extensions : WebGLExtensions;
  var _properties : WebGLProperties;
  var _programCache : WebGLProgramCache;
  var _renderStates : WebGLRenderStates;
  var _renderLists : WebGLRenderLists;
  var _geometries : WebGLGeometries;
  var _attributes : WebGLAttributes;
  var _bindingStates : WebGLBindingStates;
  var _uniformsGroups : WebGLUniformsGroups;
  var _cubemaps : WebGLCubeMaps;
  var _cubeuvmaps : WebGLCubeUVMaps;
  var _objects : WebGLObjects;
  var _animation : WebGLAnimation;
  var _xr : WebGLXR;
  var _info : WebGLInfo;
  var _shadowMap : WebGLShadowMap;
  var _currentRenderState : State;
  var _renderStateStack : Array<State>;
  var _bufferRenderer : WebGLBufferRenderer;
  var _indexedBufferRenderer : WebGLIndexedBufferRenderer;
  var _canvas : dynamic;
  var _pixelRatio : Float;

  public function new() {
    _emptyScene = new Scene();
    _isContextLost = false;
    _gl = null;
    _useLegacyLights = false;
    _isWebgl2 = false;
    _extensions = null;
    _properties = null;
    _programCache = null;
    _renderStates = null;
    _renderLists = null;
    _geometries = null;
    _attributes = null;
    _bindingStates = null;
    _uniformsGroups = null;
    _cubemaps = null;
    _cubeuvmaps = null;
    _objects = null;
    _animation = null;
    _xr = null;
    _info = null;
    _shadowMap = null;
    _currentRenderState = null;
    _renderStateStack = [];
    _bufferRenderer = null;
    _indexedBufferRenderer = null;
    _canvas = null;
    _pixelRatio = 1;
    super();
  }

  public function init( canvas : dynamic ) : Void {
    _canvas = canvas;
    _canvas.addEventListener("webglcontextlost", onContextLost, false);
    _canvas.addEventListener("webglcontextrestored", onContextRestore, false);
    _canvas.addEventListener("webglcontextcreationerror", onContextCreationError, false);
    initGLContext();
  }

  public function initGLContext() : Void {
    if (_gl == null) {
      _gl = _canvas.getContext("webgl2", {
        antialias : true,
        alpha : true,
        stencil : true,
        premultipliedAlpha : true,
        preserveDrawingBuffer : false,
        powerPreference : "high-performance",
        failIfMajorPerformanceCaveat : true
      });
      if (_gl == null) {
        _gl = _canvas.getContext("webgl", {
          antialias : true,
          alpha : true,
          stencil : true,
          premultipliedAlpha : true,
          preserveDrawingBuffer : false,
          powerPreference : "high-performance",
          failIfMajorPerformanceCaveat : true
        });
      }
    }
    if (_gl != null) {
      _isWebgl2 = _gl.getExtension("WEBGL_draw_buffers") != null;
      _isWebgl2 = _isWebgl2 && _gl.getExtension("EXT_color_buffer_float") != null;
      if (_gl.getExtension("EXT_shader_texture_lod") != null) {
        _gl.getExtension("EXT_shader_texture_lod").TEXTURE_LOD_BIAS_EXT = _gl.TEXTURE_LOD_BIAS_EXT;
      }
      if (_isWebgl2) {
        _gl.getExtension("EXT_color_buffer_float").getExtension("WEBGL_depth_texture");
      }
      if (_gl.getExtension("WEBGL_depth_texture") != null) {
        _gl.getExtension("WEBGL_depth_texture").UNSIGNED_INT_24_8_WEBGL = _gl.UNSIGNED_INT_24_8_WEBGL;
      }
      _extensions = new WebGLExtensions( _gl );
      _properties = new WebGLProperties();
      _programCache = new WebGLProgramCache( _gl, _extensions );
      _renderStates = new WebGLRenderStates();
      _renderLists = new WebGLRenderLists();
      _geometries = new WebGLGeometries( _gl );
      _attributes = new WebGLAttributes( _gl );
      _bindingStates = new WebGLBindingStates( _gl );
      _uniformsGroups = new WebGLUniformsGroups();
      _cubemaps = new WebGLCubeMaps( _gl );
      _cubeuvmaps = new WebGLCubeUVMaps( _gl );
      _objects = new WebGLObjects();
      _animation = new WebGLAnimation();
      _xr = new WebGLXR( _this );
      _info = new WebGLInfo();
      _shadowMap = new WebGLShadowMap();
      _bufferRenderer = new WebGLBufferRenderer( _gl, _extensions, _info );
      _indexedBufferRenderer = new WebGLIndexedBufferRenderer( _gl, _extensions, _info );
      _currentRenderState = null;
      _renderStateStack = [];
    }
  }

  public function setPixelRatio( value : Float ) : Void {
    _pixelRatio = value;
  }

  public function getPixelRatio() : Float {
    return _pixelRatio;
  }

  public function setSize( width : Int, height : Int, updateStyle : Bool = true ) : Void {
    super.setSize(width, height, updateStyle);
  }

  public function setClearColor( color : Color, alpha : Float = 1 ) : Void {
    super.setClearColor(color, alpha);
  }

  public function setClearAlpha( alpha : Float ) : Void {
    super.setClearAlpha(alpha);
  }

  public function clear( color : Bool, depth : Bool, stencil : Bool ) : Void {
    var bits : Int = 0;
    if (color) {
      var clearColor : Color = background.getClearColor();
      var a : Float = background.getClearAlpha();
      var r : Float = clearColor.r;
      var g : Float = clearColor.g;
      var b : Float = clearColor.b;
      var uintClearColor : Array<Int> = [r, g, b, a];
      var intClearColor : Array<Int> = [r, g, b, a];
      if (isUnsignedType) {
        _gl.clearBufferuiv( _gl.COLOR, 0, uintClearColor );
      } else {
        _gl.clearBufferiv( _gl.COLOR, 0, intClearColor );
      }
    } else {
      bits |= _gl.COLOR_BUFFER_BIT;
    }
    if (depth) bits |= _gl.DEPTH_BUFFER_BIT;
    if (stencil) {
      bits |= _gl.STENCIL_BUFFER_BIT;
      this.state.buffers.stencil.setMask( 0xffffffff );
    }
    _gl.clear( bits );
  }

  public function clearColor() : Void {
    this.clear( true, false, false );
  }

  public function clearDepth() : Void {
    this.clear( false, true, false );
  }

  public function clearStencil() : Void {
    this.clear( false, false, true );
  }

  public function dispose() : Void {
    _canvas.removeEventListener("webglcontextlost", onContextLost, false);
    _canvas.removeEventListener("webglcontextrestored", onContextRestore, false);
    _canvas.removeEventListener("webglcontextcreationerror", onContextCreationError, false);
    _renderLists.dispose();
    _renderStates.dispose();
    _properties.dispose();
    _cubemaps.dispose();
    _cubeuvmaps.dispose();
    _objects.dispose();
    _bindingStates.dispose();
    _uniformsGroups.dispose();
    _programCache.dispose();
    _xr.dispose();
    _xr.removeEventListener("sessionstart", onXRSessionStart, false);
    _xr.removeEventListener("sessionend", onXRSessionEnd, false);
    _animation.stop();
  }

  function onContextLost( event : dynamic ) : Void {
    event.preventDefault();
    _isContextLost = true;
    console.log("THREE.WebGLRenderer: Context Lost.");
  }

  function onContextRestore( /* event */ ) : Void {
    _isContextLost = false;
    console.log("THREE.WebGLRenderer: Context Restored.");
    var infoAutoReset : Bool = _info.autoReset;
    var shadowMapEnabled : Bool = _shadowMap.enabled;
    var shadowMapAutoUpdate : Bool = _shadowMap.autoUpdate;
    var shadowMapNeedsUpdate : Bool = _shadowMap.needsUpdate;
    var shadowMapType : Int = _shadowMap.type;
    initGLContext();
    _info.autoReset = infoAutoReset;
    _shadowMap.enabled = shadowMapEnabled;
    _shadowMap.autoUpdate = shadowMapAutoUpdate;
    _shadowMap.needsUpdate = shadowMapNeedsUpdate;
    _shadowMap.type = shadowMapType;
  }

  function onContextCreationError( event : dynamic ) : Void {
    console.error("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ", event.statusMessage);
  }

  function onMaterialDispose( event : dynamic ) : Void {
    var material : Material = event.target;
    material.removeEventListener("dispose", onMaterialDispose);
    deallocateMaterial(material);
  }

  function deallocateMaterial( material : Material ) : Void {
    releaseMaterialProgramReferences(material);
    _properties.remove(material);
  }

  function releaseMaterialProgramReferences( material : Material ) : Void {
    var programs : Array<WebGLProgram> = _properties.get(material).programs;
    if (programs != null) {
      programs.forEach(function(program : WebGLProgram) {
        _programCache.releaseProgram(program);
      });
      if (material.isShaderMaterial) {
        _programCache.releaseShaderCache(material);
      }
    }
  }

  public function renderBufferDirect( camera : Camera, scene : Scene, geometry : Geometry, material : Material, object : Object3D, group : dynamic = null ) : Void {
    if (scene == null) scene = _emptyScene;
    var frontFaceCW : Bool = object.isMesh && object.matrixWorld.determinant() < 0;
    var program : WebGLProgram = setProgram(camera, scene, geometry, material, object);
    state.setMaterial(material, frontFaceCW);
    var index : dynamic = geometry.index;
    var rangeFactor : Int = 1;
    if (material.wireframe) {
      index = _geometries.getWireframeAttribute(geometry);
      if (index == null) return;
      rangeFactor = 2;
    }
    var drawRange : dynamic = geometry.drawRange;
    var position : dynamic = geometry.attributes.position;
    var drawStart : Int = drawRange.start * rangeFactor;
    var drawEnd : Int = (drawRange.start + drawRange.count) * rangeFactor;
    if (group != null) {
      drawStart = Math.max(drawStart, group.start * rangeFactor);
      drawEnd = Math.min(drawEnd, (group.start + group.count) * rangeFactor);
    }
    if (index != null) {
      drawStart = Math.max(drawStart, 0);
      drawEnd = Math.min(drawEnd, index.count);
    } else if (position != null) {
      drawStart = Math.max(drawStart, 0);
      drawEnd = Math.min(drawEnd, position.count);
    }
    var drawCount : Int = drawEnd - drawStart;
    if (drawCount < 0 || drawCount == Infinity) return;
    _bindingStates.setup(object, material, program, geometry, index);
    var attribute : dynamic;
    var renderer : dynamic = _bufferRenderer;
    if (index != null) {
      attribute = _attributes.get(index);
      renderer = _indexedBufferRenderer;
      renderer.setIndex(attribute);
    }
    if (object.isMesh) {
      if (material.wireframe) {
        state.setLineWidth(material.wireframeLinewidth * getTargetPixelRatio());
        renderer.setMode( _gl.LINES );
      } else {
        renderer.setMode( _gl.TRIANGLES );
      }
    } else if (object.isLine) {
      var lineWidth : Float = material.linewidth;
      if (lineWidth == null) lineWidth = 1;
      state.setLineWidth(lineWidth * getTargetPixelRatio());
      if (object.isLineSegments) {
        renderer.setMode( _gl.LINES );
      } else if (object.isLineLoop) {
        renderer.setMode( _gl.LINE_LOOP );
      } else {
        renderer.setMode( _gl.LINE_STRIP );
      }
    } else if (object.isPoints) {
      renderer.setMode( _gl.POINTS );
    } else if (object.isSprite) {
      renderer.setMode( _gl.TRIANGLES );
    }
    if (object.isBatchedMesh) {
      if (object._multiDrawInstances != null) {
        renderer.renderMultiDrawInstances(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount, object._multiDrawInstances);
      } else {
        renderer.renderMultiDraw(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount);
      }
    } else if (object.isInstancedMesh) {
      renderer.renderInstances(drawStart, drawCount, object.count);
    } else if (geometry.isInstancedBufferGeometry) {
      var maxInstanceCount : Int = geometry._maxInstanceCount != null ? geometry._maxInstanceCount : Infinity;
      var instanceCount : Int = Math.min(geometry.instanceCount, maxInstanceCount);
      renderer.renderInstances(drawStart, drawCount, instanceCount);
    } else {
      renderer.render(drawStart, drawCount);
    }
  }

  function prepareMaterial( material : Material, scene : Scene, object : Object3D ) : Void {
    if (material.transparent && material.side == DoubleSide && ! material.forceSinglePass) {
      material.side = BackSide;
      material.needsUpdate = true;
      getProgram(material, scene, object);
      material.side = FrontSide;
      material.needsUpdate = true;
      getProgram(material, scene, object);
      material.side = DoubleSide;
    } else {
      getProgram(material, scene, object);
    }
  }

  public function compile( scene : Scene, camera : Camera, targetScene : Scene = null ) : Set<Material> {
    if (targetScene == null) targetScene = scene;
    _currentRenderState = _renderStates.get(targetScene);
    _currentRenderState.init(camera);
    _renderStateStack.push(_currentRenderState);
    targetScene.traverseVisible(function(object : Object3D) {
      if (object.isLight && object.layers.test(camera.layers)) {
        _currentRenderState.pushLight(object);
        if (object.castShadow) {
          _currentRenderState.pushShadow(object);
        }
      }
    });
    if (scene != targetScene) {
      scene.traverseVisible(function(object : Object3D) {
        if (object.isLight && object.layers.test(camera.layers)) {
          _currentRenderState.pushLight(object);
          if (object.castShadow) {
            _currentRenderState.pushShadow(object);
          }
        }
      });
    }
    _currentRenderState.setupLights(_useLegacyLights);
    var materials : Set<Material> = new Set();
    scene.traverse(function(object : Object3D) {
      var material : dynamic = object.material;
      if (material != null) {
        if (Std.is(material, Array)) {
          for (i in 0...material.length) {
            var material2 : Material = material[i];
            prepareMaterial(material2, targetScene, object);
            materials.add(material2);
          }
        } else {
          prepareMaterial(material, targetScene, object);
          materials.add(material);
        }
      }
    });
    _renderStateStack.pop();
    _currentRenderState = null;
    return materials;
  }

  public function compileAsync( scene : Scene, camera : Camera, targetScene : Scene = null ) : haxe.macro.Promise<Scene> {
    var materials : Set<Material> = this.compile(scene, camera, targetScene);
    return new haxe.macro.Promise(function(resolve : haxe.macro.PromiseCallback<Scene>, reject : haxe.macro.PromiseCallback<Dynamic>) {
      function checkMaterialsReady() : Void {
        materials.forEach(function(material : Material) {
          var materialProperties : dynamic = _properties.get(material);
          var program : WebGLProgram = materialProperties.currentProgram;
          if (program.isReady()) {
            materials.remove(material);
          }
        });
        if (materials.size == 0) {
          resolve(scene);
        } else {
          setTimeout(checkMaterialsReady, 10);
        }
      }
      if (_extensions.get("KHR_parallel_shader_compile") != null) {
        checkMaterialsReady();
      } else {
        setTimeout(checkMaterialsReady, 10);
      }
    });
  }

}