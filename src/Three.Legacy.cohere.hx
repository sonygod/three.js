import openfl.display.OpenGLView;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.events.EventDispatcher;

class WebGLMultipleRenderTargets extends WebGLRenderTarget {
    public var isWebGLMultipleRenderTargets:Bool;
    public function new (width:Int, height:Int, count:Int, options:Dynamic) {
        super(width, height, { ...options, count: count });
        this.isWebGLMultipleRenderTargets = true;
        trace("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the 'count' parameter to enable MRT.");
    }

    public function get_texture():Array<WebGLTexture> {
        return textures;
    }
}