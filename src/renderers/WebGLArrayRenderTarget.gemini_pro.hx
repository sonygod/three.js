import WebGLRenderTarget from "./WebGLRenderTarget";
import DataArrayTexture from "../textures/DataArrayTexture";

class WebGLArrayRenderTarget extends WebGLRenderTarget {

	public var isWebGLArrayRenderTarget:Bool = true;
	public var depth:Int;
	public var texture:DataArrayTexture;

	public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = {}) {
		super(width, height, options);

		this.depth = depth;
		this.texture = new DataArrayTexture(null, width, height, depth);
		this.texture.isRenderTargetTexture = true;
	}

}

export class WebGLArrayRenderTarget;