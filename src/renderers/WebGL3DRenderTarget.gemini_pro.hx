import WebGLRenderTarget from "./WebGLRenderTarget";
import Data3DTexture from "../textures/Data3DTexture";

class WebGL3DRenderTarget extends WebGLRenderTarget {

	public var isWebGL3DRenderTarget:Bool = true;
	public var depth:Int;
	public var texture:Data3DTexture;

	public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = {}) {
		super(width, height, options);
		this.depth = depth;
		this.texture = new Data3DTexture(null, width, height, depth);
		this.texture.isRenderTargetTexture = true;
	}
}

export class WebGL3DRenderTarget;