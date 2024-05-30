package three.js.examples.jsm.renderers.common;

import three.Vector4;

class RenderContext {
    static var id:Int = 0;

    public var id:Int;
    public var color:Bool;
    public var clearColor:Bool;
    public var clearColorValue:Vector4;
    public var depth:Bool;
    public var clearDepth:Bool;
    public var clearDepthValue:Float;
    public var stencil:Bool;
    public var clearStencil:Bool;
    public var clearStencilValue:Int;
    public var viewport:Bool;
    public var viewportValue:Vector4;
    public var scissor:Bool;
    public var scissorValue:Vector4;
    public var textures:Null<Array<Texture>>;
    public var depthTexture:Null<Texture>;
    public var activeCubeFace:Int;
    public var sampleCount:Int;
    public var width:Int;
    public var height:Int;
    public var isRenderContext:Bool;

    public function new() {
        id = id++;
        color = true;
        clearColor = true;
        clearColorValue = new Vector4(0, 0, 0, 1);
        depth = true;
        clearDepth = true;
        clearDepthValue = 1;
        stencil = false;
        clearStencil = true;
        clearStencilValue = 1;
        viewport = false;
        viewportValue = new Vector4();
        scissor = false;
        scissorValue = new Vector4();
        textures = null;
        depthTexture = null;
        activeCubeFace = 0;
        sampleCount = 1;
        width = 0;
        height = 0;
        isRenderContext = true;
    }
}