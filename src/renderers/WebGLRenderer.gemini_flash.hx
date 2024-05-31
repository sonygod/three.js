import three.constants.Constants;
import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Vector3;
import three.math.Vector4;
import three.renderers.webgl.WebGLAnimation;
import three.renderers.webgl.WebGLAttributes;
import three.renderers.webgl.WebGLBackground;
import three.renderers.webgl.WebGLBindingStates;
import three.renderers.webgl.WebGLBufferRenderer;
import three.renderers.webgl.WebGLCapabilities;
import three.renderers.webgl.WebGLClipping;
import three.renderers.webgl.WebGLCubeMaps;
import three.renderers.webgl.WebGLCubeUVMaps;
import three.renderers.webgl.WebGLExtensions;
import three.renderers.webgl.WebGLGeometries;
import three.renderers.webgl.WebGLIndexedBufferRenderer;
import three.renderers.webgl.WebGLInfo;
import three.renderers.webgl.WebGLMorphtargets;
import three.renderers.webgl.WebGLObjects;
import three.renderers.webgl.WebGLPrograms;
import three.renderers.webgl.WebGLProperties;
import three.renderers.webgl.WebGLRenderLists;
import three.renderers.webgl.WebGLRenderStates;
import three.renderers.WebGLRenderTarget;
import three.renderers.webgl.WebGLShadowMap;
import three.renderers.webgl.WebGLState;
import three.renderers.webgl.WebGLTextures;
import three.renderers.webgl.WebGLUniforms;
import three.renderers.webgl.WebGLUtils;
import three.renderers.webxr.WebXRManager;
import three.renderers.webgl.WebGLMaterials;
import three.renderers.webgl.WebGLUniformsGroups;
import three.utils.Utils;
import three.math.ColorManagement;
import js.html.CanvasElement;

//import { ColorRepresentation } from '../utils';


@:native("THREE.WebGLRenderer")
@:keepSubclasses
extern class WebGLRenderer {

	public function new( parameters : Dynamic ) : Void;

	public var isWebGLRenderer(default,never) : Bool;

	public var domElement : CanvasElement;
	public var debug : {
		/**
		 * Enables error checking and reporting when shader programs are being compiled
		 * @type {boolean}
		 */
		public var checkShaderErrors : Bool;
		/**
		 * Callback for custom error reporting.
		 * @type {?Function}
		 */
		public var onShaderError : Dynamic;
	};
	public var autoClear : Bool;
	public var autoClearColor : Bool;
	public var autoClearDepth : Bool;
	public var autoClearStencil : Bool;
	public var sortObjects : Bool;
	public var clippingPlanes : Array<Dynamic>;
	public var localClippingEnabled : Bool;

	// physically based shading
	public var _outputColorSpace : Int;

	// tone mapping
	public var toneMapping : Int;
	public var toneMappingExposure : Float;

	public var capabilities : WebGLCapabilities;
	public var extensions : WebGLExtensions;
	public var properties : WebGLProperties;
	public var renderLists : WebGLRenderLists;
	public var shadowMap : WebGLShadowMap;
	public var state : WebGLState;
	public var info : WebGLInfo;

	public var xr : WebXRManager;

	public function getContext() : Dynamic;
	public function getContextAttributes() : Dynamic;
	public function forceContextLoss() : Void;
	public function forceContextRestore() : Void;
	public function getPixelRatio() : Float;
	public function setPixelRatio( value : Float ) : Void;
	public function getSize( target : Vector2 ) : Vector2;
	public function setSize( width : Float, height : Float, ?updateStyle : Bool ) : Void;
	public function getDrawingBufferSize( target : Vector2 ) : Vector2;
	public function setDrawingBufferSize( width : Float, height : Float, pixelRatio : Float ) : Void;
	public function getCurrentViewport( target : Vector4 ) : Vector4;
	public function getViewport( target : Vector4 ) : Vector4;
	public function setViewport( x : Dynamic, ?y : Float, ?width : Float, ?height : Float ) : Void;
	public function getScissor( target : Vector4 ) : Vector4;
	public function setScissor( x : Dynamic, ?y : Float, ?width : Float, ?height : Float ) : Void;
	public function getScissorTest() : Bool;
	public function setScissorTest( boolean : Bool ) : Void;
	public function setOpaqueSort( method : Dynamic ) : Void;
	public function setTransparentSort( method : Dynamic ) : Void;
	public function getClearColor( target : Color ) : Color;
	//public function setClearColor( color : ColorRepresentation, alpha : Float ) : Void;
	public function setClearColor( color : Dynamic, ?alpha : Float ) : Void;
	public function getClearAlpha() : Float;
	public function setClearAlpha( alpha : Float ) : Void;
	public function clear( ?color : Bool, ?depth : Bool, ?stencil : Bool ) : Void;
	public function clearColor() : Void;
	public function clearDepth() : Void;
	public function clearStencil() : Void;
	public function dispose() : Void;
	public function renderBufferDirect( camera : Dynamic, scene : Dynamic, geometry : Dynamic, material : Dynamic, object : Dynamic, group : Dynamic ) : Void;
	public function compile( scene : Dynamic, camera : Dynamic, ?targetScene : Dynamic ) : Dynamic;
	public function compileAsync( scene : Dynamic, camera : Dynamic, ?targetScene : Dynamic ) : js.lib.Promise<Dynamic>;
	public function setAnimationLoop( callback : Dynamic ) : Void;
	public function render( scene : Dynamic, camera : Dynamic ) : Void;
	public function getActiveCubeFace() : Int;
	public function getActiveMipmapLevel() : Int;
	public function getRenderTarget() : WebGLRenderTarget;
	public function setRenderTargetTextures( renderTarget : WebGLRenderTarget, colorTexture : Dynamic, depthTexture : Dynamic ) : Void;
	public function setRenderTargetFramebuffer( renderTarget : WebGLRenderTarget, defaultFramebuffer : Dynamic ) : Void;
	public function setRenderTarget( renderTarget : WebGLRenderTarget, ?activeCubeFace : Int, ?activeMipmapLevel : Int ) : Void;
	public function readRenderTargetPixels( renderTarget : WebGLRenderTarget, x : Float, y : Float, width : Float, height : Float, buffer : js.lib.ArrayBufferView, ?activeCubeFaceIndex : Int ) : Void;
	public function readRenderTargetPixelsAsync( renderTarget : WebGLRenderTarget, x : Float, y : Float, width : Float, height : Float, buffer : js.lib.ArrayBufferView, ?activeCubeFaceIndex : Int ) : js.lib.Promise<Dynamic>;
	public function copyFramebufferToTexture( texture : Dynamic, ?position : Vector2, ?level : Int ) : Void;
	public function copyTextureToTexture( srcTexture : Dynamic, dstTexture : Dynamic, ?srcRegion : Dynamic, ?dstPosition : Vector2, ?level : Int ) : Void;
	public function copyTextureToTexture3D( srcTexture : Dynamic, dstTexture : Dynamic, ?srcRegion : Dynamic, ?dstPosition : Dynamic, ?level : Int ) : Void;
	public function initRenderTarget( target : WebGLRenderTarget ) : Void;
	public function initTexture( texture : Dynamic ) : Void;
	public function resetState() : Void;

	public var coordinateSystem(get, never) : Int;
	inline function get_coordinateSystem() : Int {
		return Constants.WebGLCoordinateSystem;
	}

	public var outputColorSpace(get, set) : Int;
	inline function get_outputColorSpace() : Int {
		return this._outputColorSpace;
	}
	inline function set_outputColorSpace(colorSpace) : Int {
		this._outputColorSpace = colorSpace;

		var gl = this.getContext();
		gl.drawingBufferColorSpace = (colorSpace == Constants.DisplayP3ColorSpace) ? "display-p3" : "srgb";
		gl.unpackColorSpace = (ColorManagement.workingColorSpace == Constants.LinearDisplayP3ColorSpace) ? "display-p3" : "srgb";

		return colorSpace;
	}

	public var useLegacyLights(get, set) : Bool;
	inline function get_useLegacyLights() : Bool {
		trace('THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733.');
		return this._useLegacyLights;
	}
	inline function set_useLegacyLights(value:Bool) : Bool {
		trace( 'THREE.WebGLRenderer: The property .useLegacyLights has been deprecated. Migrate your lighting according to the following guide: https://discourse.threejs.org/t/updates-to-lighting-in-three-js-r155/53733.' );
		return this._useLegacyLights = value;
	}
}