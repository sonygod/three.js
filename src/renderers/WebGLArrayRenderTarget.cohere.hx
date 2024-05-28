import WebGLRenderTarget from "./WebGLRenderTarget";
import DataArrayTexture from "../textures/DataArrayTexture";

class WebGLArrayRenderTarget extends WebGLRenderTarget {
    public depth:Int;
    public texture:DataArrayTexture;
    public isWebGLArrayRenderTarget:Bool;

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = null) {
        super(width, height, options);
        this.isWebGLArrayRenderTarget = true;
        this.depth = depth;
        this.texture = new DataArrayTexture(null, width, height, depth);
        this.texture.isRenderTargetTexture = true;
    }
}