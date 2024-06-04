import three.Vector4;

class RenderContext {

	public var id:Int;
	public var color:Bool;
	public var clearColor:Bool;
	public var clearColorValue: { r:Float, g:Float, b:Float, a:Float };
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
	public var textures:Dynamic;
	public var depthTexture:Dynamic;
	public var activeCubeFace:Int;
	public var sampleCount:Int;
	public var width:Int;
	public var height:Int;
	public var isRenderContext:Bool;

	public function new() {
		this.id = id++;
		this.color = true;
		this.clearColor = true;
		this.clearColorValue = { r: 0, g: 0, b: 0, a: 1 };
		this.depth = true;
		this.clearDepth = true;
		this.clearDepthValue = 1;
		this.stencil = false;
		this.clearStencil = true;
		this.clearStencilValue = 1;
		this.viewport = false;
		this.viewportValue = new Vector4();
		this.scissor = false;
		this.scissorValue = new Vector4();
		this.textures = null;
		this.depthTexture = null;
		this.activeCubeFace = 0;
		this.sampleCount = 1;
		this.width = 0;
		this.height = 0;
		this.isRenderContext = true;
	}

	static var id:Int = 0;
}