import three.Vector4;

class RenderContext {

	var id:Int;
	var color:Bool;
	var clearColor:Bool;
	var clearColorValue:{ r:Float, g:Float, b:Float, a:Float };
	var depth:Bool;
	var clearDepth:Bool;
	var clearDepthValue:Float;
	var stencil:Bool;
	var clearStencil:Bool;
	var clearStencilValue:Float;
	var viewport:Bool;
	var viewportValue:Vector4;
	var scissor:Bool;
	var scissorValue:Vector4;
	var textures:Dynamic;
	var depthTexture:Dynamic;
	var activeCubeFace:Int;
	var sampleCount:Int;
	var width:Int;
	var height:Int;
	var isRenderContext:Bool;

	static var _id:Int = 0;

	public function new() {
		id = _id ++;
		color = true;
		clearColor = true;
		clearColorValue = { r: 0, g: 0, b: 0, a: 1 };
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