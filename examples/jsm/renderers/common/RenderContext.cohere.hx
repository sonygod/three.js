class RenderContext {
	public var id:Int;
	public var color:Bool;
	public var clearColor:Bool;
	public var clearColorValue:Vector4_Impl;
	public var depth:Bool;
	public var clearDepth:Bool;
	public var clearDepthValue:Float;
	public var stencil:Bool;
	public var clearStencil:Bool;
	public var clearStencilValue:Int;
	public var viewport:Bool;
	public var viewportValue:Vector4_Impl;
	public var scissor:Bool;
	public var scissorValue:Vector4_Impl;
	public var textures:Array<Texture>;
	public var depthTexture:Texture;
	public var activeCubeFace:Int;
	public var sampleCount:Int;
	public var width:Int;
	public var height:Int;
	public var isRenderContext:Bool;

	public function new() {
		id = 0;
		color = true;
		clearColor = true;
		clearColorValue = new Vector4_Impl(0, 0, 0, 1);
		depth = true;
		clearDepth = true;
		clearDepthValue = 1;
		stencil = false;
		clearStencil = true;
		clearStencilValue = 1;
		viewport = false;
		viewportValue = new Vector4_Impl();
		scissor = false;
		scissorValue = new Vector4_Impl();
		textures = null;
		depthTexture = null;
		activeCubeFace = 0;
		sampleCount = 1;
		width = 0;
		height = 0;
		isRenderContext = true;
	}
}

class Vector4_Impl {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float, y:Float, z:Float, w:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}