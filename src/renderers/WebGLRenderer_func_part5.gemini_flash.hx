import three.core.EventDispatcher;
import three.core.Object3D;
import three.cameras.Camera;
import three.renderers.WebGLRenderTarget;
import three.textures.Texture;
import three.textures.DataTexture3D;
import three.textures.DataArrayTexture;
import three.textures.CompressedTexture;
import three.textures.CompressedArrayTexture;
import three.math.Vector2;
import js.html.webgl.WebGLRenderingContext;
import three.renderers.webgl.WebGLState;
import three.renderers.webgl.WebGLProperties;
import three.renderers.webgl.WebGLCapabilities;
import three.renderers.webgl.WebGLTextures;
import three.renderers.webgl.WebGLAttributes;
import three.renderers.webgl.WebGLBindingStates;
import three.renderers.webgl.WebGLBackground;
import three.renderers.webgl.WebGLMorphtargets;
import three.renderers.webgl.WebGLBufferRenderer;
import three.renderers.webgl.WebGLIndexedBufferRenderer;
import three.renderers.webgl.WebGLLights;
import three.renderers.webgl.WebGLObjects;
import three.renderers.webgl.WebGLPrograms;
import three.renderers.webgl.WebGLGeometries;
import three.renderers.webgl.WebGLInfo;
import three.renderers.webgl.WebGLUtils;
import three.renderers.webgl.WebGLShadowMap;
import three.renderers.webgl.WebGLRenderLists;
import three.renderers.webgl.WebGLClipping;
import three.scenes.Scene;
import three.materials.Material;
import three.core.BufferGeometry;
import three.materials.ShaderMaterial;
import three.materials.RawShaderMaterial;
import three.renderers.webgl.WebGLUniforms;

// FIXME: Find a way to import using * as alias
import WebGLCoordinateSystem from three.renderers.WebGLCoordinateSystem";
import DisplayP3ColorSpace from "three.constants.DisplayP3ColorSpace";
import LinearDisplayP3ColorSpace from "three.constants.LinearDisplayP3ColorSpace";
import ColorManagement from "three.constants.ColorManagement";

@:jsRequire("three", "WebGLRenderer")
extern class WebGLRenderer extends EventDispatcher {
  public function new(parameters:Dynamic = null):Void;
  public function domElement():Dynamic;
  public function render(scene:Scene, camera:Camera):Void;
  public function setAnimationLoop(callback:Void->Void):Void;
  public function setSize(width:Int, height:Int, updateStyle:Bool = false):Void;
  public function getDrawingBufferSize(target:Vector2):Vector2;
  public function setClearColor(color:Int, alpha:Float = 1):Void;
  public function getClearColor(target:Dynamic):Dynamic;
  public function getClearAlpha():Float;
  public function clear(color:Bool = true, depth:Bool = true, stencil:Bool = true):Void;
  public function clearColor():Void;
  public function clearDepth():Void;
  public function clearStencil():Void;
  public function dispose():Void;
  public function reset():Void;
  public function supportsFloatTextures():Bool;
  public function supportsHalfFloatTextures():Bool;
  public function supportsStandardDerivatives():Bool;
  public function supportsCompressedTextureS3TC():Bool;
  public function supportsCompressedTexturePVRTC():Bool;
  public function supportsCompressedTextureETC1():Bool;
  public function supportsCompressedTextureETC2():Bool;
  public function supportsCompressedTextureASTC():Bool;
  public function supportsCompressedTextureBPTC():Bool;
  public function supportsBasis():Bool;
  public function supportsRGBA8():Bool;
  public function supportsLinearMipmaps():Bool;

  public static function get coordinateSystem():WebGLCoordinateSystem;
  public var outputColorSpace(get, set):Int;
  inline function get_outputColorSpace():Int {
    return this._outputColorSpace;
  }
  inline function set_outputColorSpace(colorSpace:Int):Int {
    this._outputColorSpace = colorSpace;

    var gl:WebGLRenderingContext = this.getContext();
    gl.drawingBufferColorSpace = colorSpace == DisplayP3ColorSpace ? 'display-p3' : 'srgb';
    gl.unpackColorSpace = ColorManagement.workingColorSpace == LinearDisplayP3ColorSpace ? 'display-p3' : 'srgb';
    return colorSpace;
  }

  // @:deprecated("r155")
  public var useLegacyLights(get, set):Bool;
  inline function get_useLegacyLights():Bool {
    trace('THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733.');
    return this._useLegacyLights;
  }
  inline function set_useLegacyLights(value:Bool):Bool {
    trace('THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733.');
    this._useLegacyLights = value;
    return value;
  }

  function getContext():WebGLRenderingContext;

  // Private properties
  var _currentActiveCubeFace:Int;
  var _currentActiveMipmapLevel:Int;
  var _currentRenderTarget:WebGLRenderTarget;
  var _currentMaterialId:Int;
  var _useLegacyLights:Bool;
  var _outputColorSpace:Int;
}