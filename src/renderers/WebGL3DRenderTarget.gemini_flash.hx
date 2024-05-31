import three.textures.Data3DTexture;
import three.renderers.webgl.WebGLRenderTarget;

class WebGL3DRenderTarget extends WebGLRenderTarget {

	public var isWebGL3DRenderTarget(default, null) : Bool = true;
	public var depth(default, null) : Int;

	public function new( width : Int = 1, height : Int = 1, depth : Int = 1, options : Dynamic = {} ) {

		super( width, height, options );

		this.depth = depth;

		this.texture = new Data3DTexture( null, width, height, depth );

		cast(this.texture, Dynamic).isRenderTargetTexture = true;

	}

}