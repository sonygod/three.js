import openfl.display3D.textures.Data3DTexture;
import openfl.display3D.WebGLRenderTarget;

class WebGL3DRenderTarget extends WebGLRenderTarget {
	public var depth:Int;
	public var texture:Data3DTexture;

	public function new (width:Int = 1, height:Int = 1, depth:Int = 1, ?options:Dynamic) {
		super(width, height, options);
		this.isWebGL3DRenderTarget = true;
		this.depth = depth;
		this.texture = new Data3DTexture(null, width, height, depth);
		this.texture.isRenderTargetTexture = true;
	}
}