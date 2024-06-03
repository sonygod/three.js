import three.core.WebGLRenderer;
import three.core.WebGLCoordinateSystem;
import three.core.ColorManagement;
import three.core.DisplayP3ColorSpace;
import three.core.LinearDisplayP3ColorSpace;
import three.materials.Material;
import three.materials.MeshLambertMaterial;
import three.materials.MeshToonMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.ShadowMaterial;
import three.materials.ShaderMaterial;
import three.materials.RawShaderMaterial;
import three.materials.SpriteMaterial;
import three.objects.Object3D;
import three.renderers.WebGLUniforms;
import three.renderers.WebGLUniformsGroup;
import three.renderers.WebGLState;
import three.renderers.WebGLTextures;
import three.renderers.WebGLBindingStates;
import three.renderers.WebGLProperties;
import three.renderers.WebGLShadowMap;
import three.renderers.WebGLExtensions;
import three.renderers.WebGLUtils;
import three.scenes.Fog;
import three.cameras.Camera;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.textures.Texture;
import three.textures.DataTexture;
import three.textures.DataTexture3D;
import three.textures.DataArrayTexture;
import three.textures.CompressedArrayTexture;
import three.textures.CompressedTexture;
import three.textures.CubeTexture;
import three.renderers.WebGLMultisampleRenderTarget;
import three.renderers.WebGLRenderTarget;
import three.renderers.WebGLCubeRenderTarget;
import three.renderers.WebGLCapabilities;

class WebGLRendererHaxe extends WebGLRenderer {

	public var _currentActiveCubeFace:Int = 0;
	public var _currentActiveMipmapLevel:Int = 0;
	public var _currentRenderTarget:Dynamic = null;
	public var _currentViewport:Vector2 = new Vector2();
	public var _currentScissor:Vector2 = new Vector2();
	public var _currentScissorTest:Bool = false;
	public var _currentMaterialId:Int = -1;

	private var _outputColorSpace:Dynamic = null;
	private var _useLegacyLights:Bool = false;

	public function new() {
		super();
	}

	override public function render( scene:Dynamic, camera:Dynamic, renderTarget:Dynamic = null, forceClear:Bool = true ):Void {
		// TODO: Implement render function
	}

	public function getActiveCubeFace():Int {
		return _currentActiveCubeFace;
	}

	public function getActiveMipmapLevel():Int {
		return _currentActiveMipmapLevel;
	}

	public function getRenderTarget():Dynamic {
		return _currentRenderTarget;
	}

	public function setRenderTargetTextures( renderTarget:Dynamic, colorTexture:Dynamic, depthTexture:Dynamic ):Void {
		// TODO: Implement setRenderTargetTextures function
	}

	public function setRenderTargetFramebuffer( renderTarget:Dynamic, defaultFramebuffer:Dynamic ):Void {
		// TODO: Implement setRenderTargetFramebuffer function
	}

	public function setRenderTarget( renderTarget:Dynamic, activeCubeFace:Int = 0, activeMipmapLevel:Int = 0 ):Void {
		// TODO: Implement setRenderTarget function
	}

	public function readRenderTargetPixels( renderTarget:Dynamic, x:Int, y:Int, width:Int, height:Int, buffer:Dynamic, activeCubeFaceIndex:Int = 0 ):Void {
		// TODO: Implement readRenderTargetPixels function
	}

	public function readRenderTargetPixelsAsync( renderTarget:Dynamic, x:Int, y:Int, width:Int, height:Int, buffer:Dynamic, activeCubeFaceIndex:Int = 0 ):Dynamic {
		// TODO: Implement readRenderTargetPixelsAsync function
	}

	public function copyFramebufferToTexture( texture:Dynamic, position:Dynamic = null, level:Int = 0 ):Void {
		// TODO: Implement copyFramebufferToTexture function
	}

	public function copyTextureToTexture( srcTexture:Dynamic, dstTexture:Dynamic, srcRegion:Dynamic = null, dstPosition:Dynamic = null, level:Int = 0 ):Void {
		// TODO: Implement copyTextureToTexture function
	}

	public function copyTextureToTexture3D( srcTexture:Dynamic, dstTexture:Dynamic, srcRegion:Dynamic = null, dstPosition:Dynamic = null, level:Int = 0 ):Void {
		// TODO: Implement copyTextureToTexture3D function
	}

	public function initRenderTarget( target:Dynamic ):Void {
		// TODO: Implement initRenderTarget function
	}

	public function initTexture( texture:Dynamic ):Void {
		// TODO: Implement initTexture function
	}

	public function resetState():Void {
		// TODO: Implement resetState function
	}

	public function get coordinateSystem():WebGLCoordinateSystem {
		return WebGLCoordinateSystem;
	}

	public function get outputColorSpace():Dynamic {
		return _outputColorSpace;
	}

	public function set outputColorSpace( colorSpace:Dynamic ):Void {
		_outputColorSpace = colorSpace;
		// TODO: Implement set outputColorSpace
	}

	public function get useLegacyLights():Bool {
		// TODO: Implement get useLegacyLights
		return _useLegacyLights;
	}

	public function set useLegacyLights( value:Bool ):Void {
		// TODO: Implement set useLegacyLights
		_useLegacyLights = value;
	}

}