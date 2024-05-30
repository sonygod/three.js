import three.Vector4;

class RenderContext {
    public static var id:Int = 0;

    public var id:Int;
    public var color:Bool = true;
    public var clearColor:Bool = true;
    public var clearColorValue:three.Color = new three.Color(0, 0, 0, 1);
    public var depth:Bool = true;
    public var clearDepth:Bool = true;
    public var clearDepthValue:Float = 1;
    public var stencil:Bool = false;
    public var clearStencil:Bool = true;
    public var clearStencilValue:Int = 1;
    public var viewport:Bool = false;
    public var viewportValue:Vector4 = new Vector4();
    public var scissor:Bool = false;
    public var scissorValue:Vector4 = new Vector4();
    public var textures:Null<Dynamic> = null;
    public var depthTexture:Null<Dynamic> = null;
    public var activeCubeFace:Int = 0;
    public var sampleCount:Int = 1;
    public var width:Int = 0;
    public var height:Int = 0;
    public var isRenderContext:Bool = true;

    public function new() {
        this.id = RenderContext.id++;
    }
}